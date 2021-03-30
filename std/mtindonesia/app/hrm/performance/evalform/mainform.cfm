<cfparam name="reqno" default="">
<cfparam name="formno" default="">
<cfparam name="empid" default="">
<cfparam name="varcoid" default="#REQUEST.SCOOKIE.COID#">
<cfparam name="varcocode" default="#request.scookie.cocode#">
<cfparam name="refdate" default="">
<cfparam name="periodcode" default="">
<cfparam name="planformno" default="">
<cfparam name="reqorder" default="-">
<cfparam name="evaldatevalid" default="url.evaldatevalid">
<cfparam name="afsp" default="N"><!--- access from succession planning --->
<!--- Penjagaan bila, form dibuka di dua atau lebih browser tanpa merefresh listing page saat form sudah direquest dari salah satunya --->
<cfset flgUnfinal = 0>

<!---TCK2002-0548467--->
<cfset VarNumFormatConf = request.config.NUMERIC_FORMAT>
<cfset VargetDecimalAfter = ListLast(VarNumFormatConf,'.')>
<cfset InitVarCountDeC = LEN(VargetDecimalAfter)> 
<!---TCK2002-0548467--->


<cfquery name="qCheckIfRequestHasBeenSubmitted" datasource="#request.sdsn#">
    SELECT reviewer_empid, head_status,review_step 
    FROM TPMDPERFORMANCE_EVALH EH
    LEFT JOIN TPMMPERIOD P
        ON P.period_code = EH.period_code
        AND P.company_code = EH.company_code
        AND EH.reference_date = EH.reference_date
    WHERE EH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
    	AND EH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
        AND EH.company_code = <cfqueryparam value="#varcocode#" cfsqltype="cf_sql_varchar">
		AND head_status = 1
    ORDER BY EH.review_step ASC
</cfquery>
<cfquery name="qCheckSelf" datasource="#REQUEST.SDSN#" >
	SELECT form_no,head_status from TPMDPERFORMANCE_EVALH
	where reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
	AND reviewer_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	and form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
	and request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
</cfquery>

<cfset allowskipCompParam = "Y">
<cfquery name="qCompParam" datasource="#request.sdsn#">
	SELECT field_value from tclcappcompany where UPPER(field_code) = 'ALLOW_SKIP_REVIEWER' and company_id = '#REQUEST.SCookie.COID#'
</cfquery>
<cfif qCompParam.field_value neq "">
	<cfset allowskipCompParam = qCompParam.field_value>
</cfif>

<cfif qCheckIfRequestHasBeenSubmitted.recordcount and len(reqno) eq 0>
	<cfset SFLANG=Application.SFParser.TransMLang("JSThis performance form has been submitted before, please reopen this form",true)>
	<cfoutput>
		<script>
			alert("#SFLANG#");
			setTimeout(function(){popClose()},500);
			refreshPage();
		</script>
		<CF_SFABORT>
    </cfoutput>
</cfif>

<cfset FORMMLANG = "FDFormNo|EmpNo|Name|BCPosition|OrgUnit|BCjobgrade|BCworklocation|EmploymentStatus|JoinDate|FDPerformancePeriodName|FDPerformanceDate|Previous Step Reviewer|">
<cfset FORMMLANG = FORMMLANG & "Appraisal|OrgUnitObj|PersonalObj|Competency|Task|Feedback|Summary|OverallRating|Incomplete|AdditionalNotes|NoAdditionalNotes">

<cfset REQUEST.SFMLANG=Application.SFParser.TransMLang(FORMMLANG)>
<cfset emplogin = request.scookie.user.empid>
<cfset objSFPEV = createobject("component","SFPerformanceEvaluation")>
<cfif NOT isDefined('objSFPEV.isGeneratePrereviewer')>
    <cfset retVarCheckParam = false>
<cfelse>
    <cfset retVarCheckParam = objSFPEV.isGeneratePrereviewer()>
</cfif>

<cfquery name="qCheckHPerReviewer" datasource="#REQUEST.SDSN#" >
	SELECT head_status from TPMDPERFORMANCE_EVALH
	where reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
	AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
</cfquery>

 <cfset reqorder = objSFPEV.getApprovalOrder(reviewee=URL.empid,reviewer=request.scookie.user.empid)>
<cfset strckListApprover = objSFPEV.GetApproverList(empid=URL.empid,reqno=reqno,reqorder=reqorder,varcoid=varcoid,varcocode=varcocode)>


 <cfif isDefined('URL.isdebugyes')>
	<cfdump var="#reqorder#">
	<cfdump var="#strckListApprover#">
</cfif>

<cfset willskipFlag = 0>
<cfquery name="qCheckLastReviewer" datasource="#request.sdsn#">
SELECT 
<cfif request.dbdriver eq "MSSQL">
    top 1    
</cfif>
    A.lastreviewer_empid,A.request_no,A.form_no,B.full_name,A.reviewee_empid,A.modified_date
    FROM TPMDPERFORMANCE_EVALH A
    INNER JOIN TEOMEMPPERSONAL B ON B.emp_id = A.lastreviewer_empid
    INNER JOIN TCLTREQUEST C ON A.request_no = C.req_no AND C.req_type = 'PERFORMANCE.EVALUATION' 
    AND C.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer"> 
    AND C.reqemp = A.reviewee_empid
    WHERE request_no =  <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
    ORDER BY A.modified_date DESC
<cfif request.dbdriver eq "MYSQL">
    limit 1    
</cfif>    
</cfquery>

<cfquery name="qCheckIfRequestIsUnfinal" datasource="#request.sdsn#">
	SELECT modified_by, reviewer_empid
	FROM TPMDPERFORMANCE_EVALH 
	WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	ORDER BY review_step DESC
</cfquery>
<cfif ListFindNoCase(qCheckIfRequestIsUnfinal.modified_by,"unfinal","|") gt 0 AND qCheckIfRequestIsUnfinal.reviewer_empid neq REQUEST.SCOOKIE.USER.EMPID>
	<cfset flgUnfinal = 1>
</cfif>

<cfset flagHigherApprover = 0>
<cfset flagNotAuthorizedMakeTheRequest = 0>
<cfset flagDraftStuck = 0>

<cfif listfindnocase("2,3,4,9",StrckListApprover.status) and StrckListApprover.approver_headstatus lt 0 AND StrckListApprover.APPROVERBEFORE_HEADSTATUS eq 0>
	<cfset flagHigherApprover = 1>
	
</cfif>
<cfif not StrckListApprover.index>
	<cfset flagNotAuthorizedMakeTheRequest = 1>
</cfif>


<cfif qCheckHPerReviewer.head_status eq 0 AND listfindnocase("2,3,9",StrckListApprover.status) AND strckListApprover.APPROVERBEFORE_HEADSTATUS neq 1>
	<cfset flagDraftStuck = 1>
</cfif>

<cfif flgUnfinal eq 1 and qCheckHPerReviewer.recordcount eq 0>
	<cfset flagHigherApprover = 1>
<cfelseif flgUnfinal eq 1 and qCheckHPerReviewer.recordcount gt 0 and qCheckHPerReviewer.head_status eq 0>
	<cfset flagDraftStuck = 1>
</cfif>
<cfif flagNotAuthorizedMakeTheRequest eq 1 >
	<cfset SFLANG=Application.SFParser.TransMLang("JSYou're not Authorized to make This Request",true)>	
<cfelseif flagDraftStuck eq 1>
	<cfset SFLANG=Application.SFParser.TransMLang("JSApprover in higher step has approved this performance form, your draft can't be proceed",true)>
<cfelseif flagHigherApprover eq 1>
	<cfset SFLANG=Application.SFParser.TransMLang("JSApprover in higher step has approved this performance form",true)>
<cfelseif flgUnfinal eq 1>
	<cfset SFLANG=Application.SFParser.TransMLang("JSThis form has opened by Last Approver",true)>
</cfif>
<cfset objEnterpriseUser= CreateObject("component", "SFEnterpriseUser") />
<cfset retValidateEntSum=objEnterpriseUser.isEntExceedWithDefinedEmp(lstEmp_id=empid)>
<cfif retValidateEntSum.retVal EQ false>
	<cfset SFLANG=retValidateEntSum.message>
</cfif>


<cfif flagHigherApprover eq 1 OR flagNotAuthorizedMakeTheRequest eq 1 OR retValidateEntSum.retVal EQ false>
	<cfoutput>
		<script>
		   
			alert("#SFLANG#");
			setTimeout(function(){popClose()},500);
		</script>
	</cfoutput>
    <CF_SFABORT>
<cfelseif flagDraftStuck eq 1 OR flgUnfinal eq 1>
<cfoutput>
		<script>
			alert("#SFLANG#");
		</script>
	</cfoutput>
</cfif>



<cfquery name="qCheckEvalHAllRev" datasource="#REQUEST.SDSN#" >
	SELECT max(review_step) maxstep from TPMDPERFORMANCE_EVALH
	where reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
	<cfif strckListApprover.status neq 4>
		AND head_status = 1
	</cfif>
	<cfif formno neq "">
		and form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
	</cfif>
	<cfif reqno neq "">
			and request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	</cfif>
</cfquery>

<cfif qCheckEvalHAllRev.recordcount gt 0>
	<cfset laststepfill = val(qCheckEvalHAllRev.maxstep)>
</cfif>


<cfset varSetStep = objSFPEV.getApproverStep(reviewee_empid=empid, period_code = periodcode,reviewer_empid = REQUEST.SCOOKIE.USER.EMPID)>
<cfif qCheckEvalHAllRev.recordcount eq 0>
	<cfif varSetStep gt 1>
		<cfset willskipFlag = 1>
	</cfif>
<cfelse>
	<cfif val(varSetStep-laststepfill) gt 1>
		<cfset willskipFlag = 1>
	</cfif>
</cfif>


<cfif willskipFlag eq 1 >  
   <cfif UCASE(allowskipCompParam) EQ 'Y' AND laststepfill eq 0> <!---TCK1907-0513574---> 
        <cfset SFLANG5=Application.SFParser.TransMLang("JSThere are some approver skipped, Are you sure you want to continue?",true)>
    	<cfoutput>
    		<script>
	
    		    var giveSkipAlert = confirm("#SFLANG5#");
    			if(!giveSkipAlert){setTimeout(function(){popClose()},500);}
    		</script>
    	</cfoutput>
  
    </cfif>
</cfif>


<!--- harusnya dilempar aja dari mainform.cfm --->
<cfset qReviewerInfo = objSFPEV.getEmpDetail(empid=request.scookie.user.empid,varcoid=varcoid)>
<cfset qEmpInfo = objSFPEV.getEmpDetail(empid=empid,varcoid=varcoid)>
<cfset qPeriodData = objSFPEV.getPeriodData(periodcode=periodcode,refdate=refdate,varcocode=varcocode)>
<cfset qScoreDet = objSFPEV.getScoringDetail(scorecode=qPeriodData.score_type,varcocode=varcocode)>
<cfset qLookUpDet = objSFPEV.getScoringDetail(scorecode=qPeriodData.conclusion_lookup,varcocode=varcocode)>
<cfset qEvalGrade = objSFPEV.getPlanGradeStat(empid=empid,formno=formno,reqno=reqno)> <!---ENC50616-80432 RS:160615--->
<cfset lstReviewer = StrckListApprover.LSTAPPROVER>
<cfset getPerCompDataFromSetting = 0>
<cfset qEmpPerCompData = objSFPEV.getReqEmpData(reqno=reqno,formno=formno,empid=empid,periodcode=periodcode,refdate=refdate,reviewer=lstReviewer,compcode="COMPONENT",varcocode=varcocode)>

<cfif not qEmpPerCompData.recordcount>
	<cfif len(strckListApprover.LastApprover)>
		<cfset qEmpPerCompData = objSFPEV.getReqEmpData(reqno=reqno,formno=formno,empid=empid,periodcode=periodcode,refdate=refdate,reviewer=lstReviewer,compcode="COMPONENT",varcocode=varcocode)>
	<cfelse>
		<cfset getPerCompDataFromSetting = 1>
		<cfset qEmpPerCompData = objSFPEV.getPeriodCompData(periodcode=periodcode,refdate=refdate,posid=qEmpInfo.posid)>
    </cfif>
</cfif>
<cfif getPerCompDataFromSetting>
	<cfset listPeriodComp = valuelist(qEmpPerCompData.component_code)>
<cfelse>
	<cfset listPeriodComp = valuelist(qEmpPerCompData.lib_code)>
</cfif>

<cfset compData = structnew()>
<cfloop list="#ucase(listPeriodComp)#" index="idx">
	<cfset compData[idx] = structnew()>
    <cfif getPerCompDataFromSetting>
		<cfset compData[idx].score = 0>
		<cfset compData[idx].weightedscore = 0>
    <cfelse>
		<cfset compData[idx].score = listgetat(valuelist(qEmpPerCompData.score),listfindnocase(listPeriodComp,idx))>
		<cfset compData[idx].weightedscore = listgetat(valuelist(qEmpPerCompData.weightedscore),listfindnocase(listPeriodComp,idx))>
    </cfif>
	<cfset compData[idx].weight = listgetat(valuelist(qEmpPerCompData.weight),listfindnocase(listPeriodComp,idx))>
</cfloop>
<cfoutput>
<style>
	body {
		font: 0.8em arial, helvetica, sans-serif;
	}
	##eval-title{
		margin-bottom:10px;
	}
	##eval-summary .left{
		width: 30%; height: 100%; float: left; margin-left: 5px;
	}
	##eval-summary .right{
		width: 65%; height: 100%; float: left; margin-left: 25px;
	}
	##eval-summary .right .notes{
		height:95%;	width:95%;
		text-align: left;
	}
	.addnotes{
		width:100%;
	}
	
	##eval-mysum, ##eval-empdetail {
    	font-family: sans-serif; border: 2px solid ##1F497D; 
		background: ##eee;
	}
	
	.eval-iframe{
		margin-bottom:-35px;
	}

	##eval-legend {
    	font-size: 12px;
	}
	
	##emp-photo{
	    float: left;
		margin-top: 5px;
		margin-right: 15px;
	}
	
	##emp-detail{
		float: left;
		/* margin-left: 10px; */
		vertical-align:middle;
	}
	##emp-detail ##detail{
		vertical-align:middle;
	}
	
	##clearfloat{
		clear:both;
	}
	
	.evalgauge{
		border: 1px solid black;
		text-align: center;
		background-color:##FFF;
		margin-top: 20px;
	}
	
	.gauge-title{
		float:left;
		font-size: 10pt;
		margin-left: 5px;
	}
	.gauge-weight{
		float:right;
		font-size: 14pt;
		margin-right: 5px;
	}
	
	.smallgauge{
		float:right;
		text-align: center;
	}
	.smallgauge ##clearfloat{
		clear:both;
	}
	.smallgauge ##title{
		font-size: 12px;
		font-weight:bold;
	}
	.smallgauge img{
		height:50px;
	}
	.smallgauge ##gauge1,##gauge2,##gauge3{
		float:left;
		margin-bottom:10px;
		margin-right:15px;
		margin-top:5px;
		width:115px;
	}
	.smallgauge ##gauge4,##gauge5,##gauge6{
		float:left;
		margin-right:15px;
		margin-top:10px;
		width:115px;
	}
	.gaugeimg{
		position: relative;
	}
	.gaugescore{
		left: 0;
		position: absolute;
		text-align: center;
		width: 100%;
		font-size: 12px;
		bottom: -14px;
		font-weight:bold;
	}
	
	##evalcurve{
		margin-top:10px;
	}
</style>

	<div id="eval-title">
   	<fieldset id="eval-empdetail">
		<table width="100%">
			<tr>
				<td align="center" width="10%" valign="middle">
						<table>
							<tr>
								<td>
									<cfif len(qEmpInfo.empphoto)>
										<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;thumb=1&amp;fname=#qEmpInfo.empphoto#" style="height:170px;">
									<cfelseif val(qEmpInfo.empgender) eq 1>
										<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_noemployee.gif" style="height:170px;">
									<cfelse>
										<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_nofemployee.gif" style="height:170px;">
									</cfif>
								</td>
							</tr>
						</table>
				</td>
				<td align="left" valign="top">
					<table>
						<tr>
							<td nowrap width="20%">#REQUEST.SFMLANG['FDFormNo']#</td>
							<td width="5%">:</td>
							<td width="75%"><cfif not len(reqno)>#Application.SFUtil.getCode("PERFEVALFORM",'yes','false')#<cfelse>#formno#</cfif></td>
						</tr>
						<tr>
							<td nowrap >#REQUEST.SFMLANG['EmpNo']#</td>
							<td>:</td>
							<td>#qEmpInfo.empno#</td>
						</tr>
						<tr>
							<td nowrap >#REQUEST.SFMLANG['Name']#</td>
							<td>:</td>
							<td>#HTMLEDITFORMAT(qEmpInfo.empname)#</td>
						</tr>
						<tr>
							<td nowrap >#REQUEST.SFMLANG['BCPosition']#</td>
							<td>:</td>
							<td>#HTMLEDITFORMAT(qEmpInfo.emppos)#</td>
						</tr>
						<tr>
							<td nowrap >#REQUEST.SFMLANG['OrgUnit']#</td>
							<td>:</td>
							<td>#HTMLEDITFORMAT(qEmpInfo.orgunit)#</td>
						</tr>
						<tr>
							<td nowrap >#REQUEST.SFMLANG['BCjobgrade']#</td>
							<td>:</td>
							<td><cfif not len(qEvalGrade.empgrade)>#HTMLEDITFORMAT(qEmpInfo.empgrade)#<cfelse>#HTMLEDITFORMAT(qEvalGrade.empgrade)#</cfif></td>
						</tr>
						<tr>
							<td nowrap >#REQUEST.SFMLANG["BCworklocation"]#</td>
							<td>:</td>
							<td>#htmleditformat(qEmpInfo.worklocation_name)#</td>
						</tr>
						<tr>
							<td nowrap >#REQUEST.SFMLANG['EmploymentStatus']#</td>
							<td>:</td>
							<td><cfif not len(qEvalGrade.emp_status)>#HTMLEDITFORMAT(qEmpInfo.emp_status)#<cfelse>#HTMLEDITFORMAT(qEvalGrade.emp_status)#</cfif></td>
						</tr>
						<tr>
							<td nowrap >#REQUEST.SFMLANG['JoinDate']#</td>
							<td>:</td>
							<td>#dateformat(qEmpInfo.empjoindate,request.config.date_output_format)#</td>
						</tr>
						<tr>
							<td nowrap >#REQUEST.SFMLANG['FDPerformancePeriodName']#</td>
							<td>:</td>
							<td>#HTMLEDITFORMAT(qPeriodData.period_name)#</td>
						</tr>
						<tr>
							<td nowrap >#REQUEST.SFMLANG['FDPerformanceDate']#</td>
							<td>:</td>
							<td>#dateformat(qPeriodData.reference_date,request.config.date_output_format)#</td>
						</tr>
						<tr>
						<td nowrap >#REQUEST.SFMLANG["PreviousStepReviewer"]#</td>
						<td>:</td>
						<td>#qCheckLastReviewer.full_name neq '' ? HTMLEDITFORMAT(qCheckLastReviewer.full_name) : '-'#</td>
					</tr>
					</table>
				</td>
				<td align="left" valign="top">
					<div class="smallgauge">
						<cfif qPeriodData.gauge_type eq 'LOWER'>
							<cfset emptygauge = 'Gauge-0'>
						<cfelse>
							<cfset emptygauge = 'Gauge0'>
						</cfif>
						<cfif listfindnocase(listPeriodComp,"APPRAISAL")>
						<div id="gauge1">
							<div id="title">#REQUEST.SFMLANG['Appraisal']# (#compData["APPRAISAL"].weight#)</div>
							<div class="gaugeimg">
							<img id="apprGauge" src="#application.path.lib#/images/charts/kpi/#emptygauge#.png" border="0" title="#compData['APPRAISAL'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
							<div class="gaugescore" id="apprgaugescore">
								<cfif compData["APPRAISAL"].score neq 0>#compData["APPRAISAL"].score#<cfelse>#numberformat(0,"0.00")#</cfif>
							</div>
							</div>
							<input type="hidden" name="appraisal" id="appraisal" value="#compData['APPRAISAL'].score#" />
							<input type="hidden" name="appraisal_weight" id="appraisal_weight" value="#compData['APPRAISAL'].weight#" />
							<input type="hidden" name="appraisal_weighted" id="appraisal_weighted" value="#compData['APPRAISAL'].weightedscore#" />
							<input type="hidden" name="appraisal_totallookup" id="appraisal_totallookup" value="" />
							<input type="hidden" name="appraisal_totallookupSc" id="appraisal_totallookupSc" value="" />
						</div>
						</cfif>
						<cfif listfindnocase(listPeriodComp,"ORGKPI")>
						<div id="gauge2">
							<div id="title">#REQUEST.SFMLANG['OrgUnitObj']# (#compData["ORGKPI"].weight#)</div>
							<div class="gaugeimg">
							<img id="objOrgGauge" src="" border="0" title="#compData['ORGKPI'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
							<div class="gaugescore" id="objorggaugescore">
								<cfif compData["ORGKPI"].score neq 0>#compData["ORGKPI"].score#<cfelse>#numberformat(0,"0.00")#</cfif>
							</div>
							</div>
							<input type="hidden" name="objectiveorg" id="objectiveorg" value="#compData['ORGKPI'].score#" />
							<input type="hidden" name="objectiveorg_weight" id="objectiveorg_weight" value="#compData['ORGKPI'].weight#" />
							<input type="hidden" name="objectiveorg_weighted" id="objectiveorg_weighted" value="#compData['ORGKPI'].weightedscore#" />
							<input type="hidden" name="objectiveorg_totallookup" id="objectiveorg_totallookup" value="" />
							<input type="hidden" name="objectiveorg_totallookupSc" id="objectiveorg_totallookupSc" value="" />
						</div>
						</cfif>
						<cfif listfindnocase(listPeriodComp,"PERSKPI")>
						<div id="gauge3">
							<div id="title">#REQUEST.SFMLANG['PersonalObj']# (#compData["PERSKPI"].weight#)</div>
							<div class="gaugeimg">
							<img id="objGauge" src="#application.path.lib#/images/charts/kpi/#emptygauge#.png" border="0" title="#compData['PERSKPI'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
							<div class="gaugescore" id="objgaugescore">
								<cfif compData["PERSKPI"].score neq 0>#compData["PERSKPI"].score#<cfelse>#numberformat(0,"0.00")#</cfif>
							</div>
							</div>
							<input type="hidden" name="objective" id="objective" value="#compData['PERSKPI'].score#" />
							<input type="hidden" name="objective_weight" id="objective_weight" value="#compData['PERSKPI'].weight#" />
							<input type="hidden" name="objective_weighted" id="objective_weighted" value="#compData['PERSKPI'].weightedscore#" />
							<input type="hidden" name="objective_totallookup" id="objective_totallookup" value="" />
							<input type="hidden" name="objective_totallookupSc" id="objective_totallookupSc" value="" />
						</div>
						</cfif>
						<div id="clearfloat"></div>
						<cfif listfindnocase(listPeriodComp,"COMPETENCY")>
						<div id="gauge4">
							<div id="title">#REQUEST.SFMLANG['Competency']# (#compData["COMPETENCY"].weight#)</div>
							<div class="gaugeimg">
							<img id="compGauge" src="#application.path.lib#/images/charts/kpi/#emptygauge#.png" border="0" title="#compData['COMPETENCY'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
							<div class="gaugescore" id="compgaugescore">
								<cfif compData["COMPETENCY"].score neq 0>#compData["COMPETENCY"].score#<cfelse>#numberformat(0,"0.00")#</cfif>
							</div>
							</div>
							<input type="hidden" name="competency" id="competency" value="#compData['COMPETENCY'].score#" />
							<input type="hidden" name="competency_weight" id="competency_weight" value="#compData['COMPETENCY'].weight#" />
							<input type="hidden" name="competency_weighted" id="competency_weighted" value="#compData['COMPETENCY'].weightedscore#" />
						</div>
						</cfif>
						<cfif listfindnocase(listPeriodComp,"TASK")>
						<div id="gauge5">
							<div id="title">#REQUEST.SFMLANG['Task']# (#compData["TASK"].weight#)</div>
							<div class="gaugeimg">
							<img id="taskGauge" src="#application.path.lib#/images/charts/kpi/#emptygauge#.png" border="0" title="#compData['TASK'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
							<div class="gaugescore" id="taskgaugescore">
								<cfif compData["TASK"].score neq 0>#compData["TASK"].score#<cfelse>#numberformat(0,"0.00")#</cfif>
							</div>
							</div>
							<input type="hidden" name="task" id="task" value="#compData['TASK'].score#" />
							<input type="hidden" name="task_weight" id="task_weight" value="#compData['TASK'].weight#" />
							<input type="hidden" name="task_weighted" id="task_weighted" value="#compData['TASK'].weightedscore#" />
						</div>
						</cfif>
						<cfif listfindnocase(listPeriodComp,"FEEDBACK")>
						<div id="gauge6">
							<div id="title">#REQUEST.SFMLANG['Feedback']# (#compData["FEEDBACK"].weight#)</div>
							<div class="gaugeimg">
								<img id="feedbackGauge" src="#application.path.lib#/images/charts/kpi/#emptygauge#.png" border="0" title="#compData['FEEDBACK'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
								<div class="gaugescore" id="feedgaugescore">
									<cfif compData["FEEDBACK"].score neq 0>#compData["FEEDBACK"].score#<cfelse>#numberformat(0,"0.00")#</cfif>
								</div>
							</div>
							<input type="hidden" name="feedback" id="feedback" value="#compData['FEEDBACK'].score#" />
							<input type="hidden" name="feedback_weight" id="feedback_weight" value="#compData['FEEDBACK'].weight#" />
							<input type="hidden" name="feedback_weighted" id="feedback_weighted" value="#compData['FEEDBACK'].weightedscore#" />
						</div>
						</cfif>
					</div>
				</td>
			</tr>
		</table>
		
		<!-----
    	<div id="emp-photo">
            <cfif len(qEmpInfo.empphoto)>
	            <img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;thumb=1&amp;fname=#qEmpInfo.empphoto#" style="height:170px;">
            <cfelseif val(qEmpInfo.empgender) eq 1>
            	<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_noemployee.gif" style="height:170px;">
            <cfelse>
            	<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_nofemployee.gif" style="height:170px;">
            </cfif>
        </div>
		
        <div id="emp-detail">
        	<div id="detail">
        	<table>
            	<tr>
                	<td nowrap width="20%">#REQUEST.SFMLANG['FDFormNo']#</td>
                	<td width="5%">:</td>
                	<td width="75%"><cfif not len(reqno)>#Application.SFUtil.getCode("PERFEVALFORM",'yes','false')#<cfelse>#formno#</cfif></td>
                </tr>
            	<tr>
                	<td nowrap >#REQUEST.SFMLANG['EmpNo']#</td>
                	<td>:</td>
                	<td>#qEmpInfo.empno#</td>
                </tr>
            	<tr>
                	<td nowrap >#REQUEST.SFMLANG['Name']#</td>
                	<td>:</td>
                	<td>#HTMLEDITFORMAT(qEmpInfo.empname)#</td>
                </tr>
            	<tr>
                	<td nowrap >#REQUEST.SFMLANG['BCPosition']#</td>
                	<td>:</td>
                	<td>#HTMLEDITFORMAT(qEmpInfo.emppos)#</td>
                </tr>
            	<tr>
                	<td nowrap >#REQUEST.SFMLANG['OrgUnit']#</td>
                	<td>:</td>
                	<td>#HTMLEDITFORMAT(qEmpInfo.orgunit)#</td>
                </tr>
            	<tr>
                	<td nowrap >#REQUEST.SFMLANG['BCjobgrade']#</td>
                	<td>:</td>
                	<td><cfif not len(reqno)>#HTMLEDITFORMAT(qEmpInfo.empgrade)#<cfelse>#HTMLEDITFORMAT(qEvalGrade.empgrade)#</cfif></td>
                </tr>
				<tr>
					<td nowrap >#REQUEST.SFMLANG["BCworklocation"]#</td>
					<td>:</td>
					<td>#htmleditformat(qEmpInfo.worklocation_name)#</td>
				</tr>
                <tr>
                	<td nowrap >#REQUEST.SFMLANG['EmploymentStatus']#</td>
                	<td>:</td>
                	<td><cfif not len(reqno)>#HTMLEDITFORMAT(qEmpInfo.emp_status)#<cfelse>#HTMLEDITFORMAT(qEvalGrade.emp_status)#</cfif></td>
                </tr>
            	<tr>
                	<td nowrap >#REQUEST.SFMLANG['JoinDate']#</td>
                	<td>:</td>
                	<td>#dateformat(qEmpInfo.empjoindate,request.config.date_output_format)#</td>
                </tr>
                <tr>
                    <td nowrap >#REQUEST.SFMLANG['FDPerformancePeriodName']#</td>
                	<td>:</td>
                    <td>#HTMLEDITFORMAT(qPeriodData.period_name)#</td>
                </tr>
                <tr>
                    <td nowrap >#REQUEST.SFMLANG['FDPerformanceDate']#</td>
                	<td>:</td>
                    <td>#dateformat(qPeriodData.reference_date,request.config.date_output_format)#</td>
                </tr>
            </table>
            </div>
        </div>
        <div class="smallgauge">
            <cfif qPeriodData.gauge_type eq 'LOWER'>
            	<cfset emptygauge = 'Gauge-0'>
            <cfelse>
            	<cfset emptygauge = 'Gauge0'>
            </cfif>
        	<cfif listfindnocase(listPeriodComp,"APPRAISAL")>
        	<div id="gauge1">
            	<div id="title">#REQUEST.SFMLANG['Appraisal']# (#compData["APPRAISAL"].weight#)</div>
                <div class="gaugeimg">
	        	<img id="apprGauge" src="#application.path.lib#/images/charts/kpi/#emptygauge#.png" border="0" title="#compData['APPRAISAL'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
                <div class="gaugescore" id="apprgaugescore">
                	<cfif compData["APPRAISAL"].score neq 0>#numberformat(compData["APPRAISAL"].score,"0.00")#<cfelse>#numberformat(0,"0.00")#</cfif>
                </div>
                </div>
	            <input type="hidden" name="appraisal" id="appraisal" value="#compData['APPRAISAL'].score#" />
	            <input type="hidden" name="appraisal_weight" id="appraisal_weight" value="#compData['APPRAISAL'].weight#" />
	            <input type="hidden" name="appraisal_weighted" id="appraisal_weighted" value="#compData['APPRAISAL'].weightedscore#" />
            </div>
            </cfif>
        	<cfif listfindnocase(listPeriodComp,"ORGKPI")>
        	<div id="gauge2">
            	<div id="title">#REQUEST.SFMLANG['OrgUnitObj']# (#compData["ORGKPI"].weight#)</div>
                <div class="gaugeimg">
	        	<img id="objOrgGauge" src="" border="0" title="#compData['ORGKPI'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
                <div class="gaugescore" id="objorggaugescore">
                	<cfif compData["ORGKPI"].score neq 0>#numberformat(compData["ORGKPI"].score,"0.00")#<cfelse>#numberformat(0,"0.00")#</cfif>
                </div>
                </div>
	            <input type="hidden" name="objectiveorg" id="objectiveorg" value="#compData['ORGKPI'].score#" />
	            <input type="hidden" name="objectiveorg_weight" id="objectiveorg_weight" value="#compData['ORGKPI'].weight#" />
	            <input type="hidden" name="objectiveorg_weighted" id="objectiveorg_weighted" value="#compData['ORGKPI'].weightedscore#" />
            </div>
            </cfif>
          	<cfif listfindnocase(listPeriodComp,"PERSKPI")>
        	<div id="gauge3">
            	<div id="title">#REQUEST.SFMLANG['PersonalObj']# (#compData["PERSKPI"].weight#)</div>
                <div class="gaugeimg">
	        	<img id="objGauge" src="#application.path.lib#/images/charts/kpi/#emptygauge#.png" border="0" title="#compData['PERSKPI'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
                <div class="gaugescore" id="objgaugescore">
                	<cfif compData["PERSKPI"].score neq 0>#numberformat(compData["PERSKPI"].score,"0.00")#<cfelse>#numberformat(0,"0.00")#</cfif>
                </div>
                </div>
	            <input type="hidden" name="objective" id="objective" value="#compData['PERSKPI'].score#" />
	            <input type="hidden" name="objective_weight" id="objective_weight" value="#compData['PERSKPI'].weight#" />
	            <input type="hidden" name="objective_weighted" id="objective_weighted" value="#compData['PERSKPI'].weightedscore#" />
            </div>
            </cfif>
            <div id="clearfloat"></div>
        	<cfif listfindnocase(listPeriodComp,"COMPETENCY")>
        	<div id="gauge4">
            	<div id="title">#REQUEST.SFMLANG['Competency']# (#compData["COMPETENCY"].weight#)</div>
                <div class="gaugeimg">
	        	<img id="compGauge" src="#application.path.lib#/images/charts/kpi/#emptygauge#.png" border="0" title="#compData['COMPETENCY'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
                <div class="gaugescore" id="compgaugescore">
                	<cfif compData["COMPETENCY"].score neq 0>#numberformat(compData["COMPETENCY"].score,"0.00")#<cfelse>#numberformat(0,"0.00")#</cfif>
                </div>
                </div>
	            <input type="hidden" name="competency" id="competency" value="#compData['COMPETENCY'].score#" />
	            <input type="hidden" name="competency_weight" id="competency_weight" value="#compData['COMPETENCY'].weight#" />
	            <input type="hidden" name="competency_weighted" id="competency_weighted" value="#compData['COMPETENCY'].weightedscore#" />
            </div>
            </cfif>
        	<cfif listfindnocase(listPeriodComp,"TASK")>
        	<div id="gauge5">
            	<div id="title">#REQUEST.SFMLANG['Task']# (#compData["TASK"].weight#)</div>
                <div class="gaugeimg">
	        	<img id="taskGauge" src="#application.path.lib#/images/charts/kpi/#emptygauge#.png" border="0" title="#compData['TASK'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
                <div class="gaugescore" id="taskgaugescore">
                	<cfif compData["TASK"].score neq 0>#numberformat(compData["TASK"].score,"0.00")#<cfelse>#numberformat(0,"0.00")#</cfif>
                </div>
                </div>
	            <input type="hidden" name="task" id="task" value="#compData['TASK'].score#" />
	            <input type="hidden" name="task_weight" id="task_weight" value="#compData['TASK'].weight#" />
	            <input type="hidden" name="task_weighted" id="task_weighted" value="#compData['TASK'].weightedscore#" />
            </div>
            </cfif>
        	<cfif listfindnocase(listPeriodComp,"FEEDBACK")>
        	<div id="gauge6">
            	<div id="title">#REQUEST.SFMLANG['Feedback']# (#compData["FEEDBACK"].weight#)</div>
                <div class="gaugeimg">
		        	<img id="feedbackGauge" src="#application.path.lib#/images/charts/kpi/#emptygauge#.png" border="0" title="#compData['FEEDBACK'].score# out of 5" style="display: block;margin-left: auto;margin-right: auto;">
	                <div class="gaugescore" id="feedgaugescore">
	                	<cfif compData["FEEDBACK"].score neq 0>#numberformat(compData["FEEDBACK"].score,"0.00")#<cfelse>#numberformat(0,"0.00")#</cfif>
	                </div>
                </div>
				<input type="hidden" name="feedback" id="feedback" value="#compData['FEEDBACK'].score#" />
	            <input type="hidden" name="feedback_weight" id="feedback_weight" value="#compData['FEEDBACK'].weight#" />
	            <input type="hidden" name="feedback_weighted" id="feedback_weighted" value="#compData['FEEDBACK'].weightedscore#" />
            </div>
            </cfif>
        </div>
        <div id="clearfloat"></div>
		---->
		
    </fieldset>
    </div>
	
    <iframe id="iframe1" name="iframe1" class="eval-iframe" runat="server" scrolling="no" src="?xfid=hrm.performance.evalform.evaluationtab&posid=#qEmpInfo.posid#&isdashboard=2&planformno=#planformno#&reqno=#reqno#&empid=#empid#&periodcode=#periodcode#&lstcomp=#listPeriodComp#&refdate=#refdate#&formno=#formno#&lpr=#StrckListApprover.lstApprover#&lastrevby=#strckListApprover.lastapprover#&emplogin=#emplogin#&varcoid=#varcoid#&varcocode=#varcocode#" height="410px" width="100%" frameBorder="0"></iframe>

   
     <cfif afsp neq "Y">
        <!--- ENC50315-06123 --->
		   <cfset showPlanningTab = false>
			<cftry> 
				<cfset funcAuth=REQUEST.SFSec.AuthAccess(acscode="hrm.performance.evalform",acslist="hrm.performance.evalform.trainingplan:edit,hrm.performance.evalform.devplan:edit,hrm.performance.evalform.careerplan:edit,hrm.performance.evalform.boxanalysis:edit,hrm.performance.evalform.successionplan:edit",isReturn=true)>
			<cfloop collection=#funcAuth# item="key">
				<cfif funcAuth[key]>
					<cfset showPlanningTab = true>
					<cfbreak>
				</cfif>
			</cfloop>
			<cfcatch> 
				<cfoutput>
				<script>
			alert("Please check your authorization for HR Planning module");
				</script>
				<CF_SFABORT>
				</cfoutput>
			</cfcatch> 
		</cftry>
		 <cfif showPlanningTab>
			<iframe id="iframe2" name="iframe2"  src="?xfid=hrm.performance.evalform.planningtab&planformno=#planformno#&reqno=#reqno#&empid=#empid#&periodcode=#periodcode#&posid=#qEmpInfo.posid#&succode=&isdashboard=2&prevposid=&refdate=#refdate#&formno=#formno#&lpr=#StrckListApprover.lstApprover#&lastrevby=#strckListApprover.lastapprover#&varcoid=#varcoid#&varcocode=#varcocode#&org_unit=#qEmpInfo.dept_id#" height="410px" width="100%" frameBorder="0"></iframe>
        </cfif>  
    </cfif> 
    
    <fieldset id="eval-mysum" style="margin-top:10px">
    	<legend id="eval-legend">#REQUEST.SFMLANG['Summary']#</legend>
		<div id="eval-summary">
            <div class="left">
	            <div class="evalgauge" id="summary">
		        	<div class="gauge-title">#REQUEST.SFMLANG['OverallRating']#</div>
		        	<div class="gauge-weight conclusion">#REQUEST.SFMLANG['Incomplete']#</div>
			        <div id="clearfloat"></div>
			        <cfif qPeriodData.gauge_type eq 'LOWER'>
			        	<cfset emptygg='-0'>
			        <cfelse>
			        	<cfset emptygg='0'>
			        </cfif>	
		        	<img id="overallGauge" src="#application.path.lib#/images/charts/kpi/Gauge#emptygg#.png" border="0" style="display: block;margin-left: auto;margin-right: auto;">
		        	<div class="gauge-rate-all">0</div>
		            <input type="hidden" name="score" id="overall" value="0" />
		            <input type="hidden" name="conclusion" id="overall_concl" value="0" />
		        </div>
		        <cfif qPeriodData.usenormalcurve eq "Y">
				<div id="evalcurve" style="width:400px;height:350px;position:relative;">
					<iframe id="iframescore" name="iframescore" class="eval-iframe" scrolling="no" height="350px" width="100%" frameBorder="0"></iframe>
    			</div>
    			</cfif>
            </div>
        	<div class="right">
    			<cfquery name="qGetLstNoteOrder" datasource="#request.sdsn#">
    			    SELECT note_order, isopen FROM TPMDPERIODNOTE
                    WHERE period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
                        AND company_code = <cfqueryparam value="#varcocode#" cfsqltype="cf_sql_varchar">
                    ORDER BY note_order ASC
    			</cfquery>
    			<cfset lstOpenOrCloseNote = valuelist(qGetLstNoteOrder.isopen)>
    			<cfset lstNoteOrder = valuelist(qGetLstNoteOrder.note_order)>
    			
                <fieldset>
                <legend>#REQUEST.SFMLANG['AdditionalNotes']#</legend>
                   
					 <!----<cfset REFULLLISTAPPROVER = Replace(StrckListApprover.FULLLISTAPPROVER,"|",",","ALL") /> --->
					<cfset tempFullListAppr =  Replace(StrckListApprover.FULLLISTAPPROVER,"|",",","ALL")>
					<cfset REFULLLISTAPPROVER = "">
					<cfloop list="#tempFullListAppr#" index="idxApp">
						<cfif ListFindNoCase(REFULLLISTAPPROVER,idxApp) eq 0>
							<cfset REFULLLISTAPPROVER = ListAppend(REFULLLISTAPPROVER,idxApp)>
						</cfif>
						
					</cfloop>
					
					
					
                    <cfset qEmpNoteData = objSFPEV.getEmpNoteData(formno=formno,periodcode=periodcode,refdate=refdate,lstreviewer=REFULLLISTAPPROVER,planformno=planformno,varcocode=varcocode)>
                    
                    <div class="notes">
	                	<table width="100%">
                        <cfif not qEmpNoteData.recordcount>
                        	<tr><td>#REQUEST.SFMLANG['NoAdditionalNotes']#</td></tr>
                        <cfelse>
		                    <cfquery name="qGetMaxOrder" dbtype="query">
		                    	SELECT MAX(note_order) as maks
		                        FROM qEmpNoteData
		                    </cfquery>
		                    <cfquery name="qGetNoteName" dbtype="query">
		                    	SELECT DISTINCT note_name, note_order
		                        FROM qEmpNoteData
                                ORDER BY note_order
		                    </cfquery>
                            <cfset lstApproverNotes = "">
               	            <input type="hidden" name="evalnoterecords" value="#qGetMaxOrder.maks#" />
                            <cfloop from="1" to="#qGetMaxOrder.maks#" index="idxOrder">
								<cfif lstOpenOrCloseNote neq "">
									<cfif listgetat(lstOpenOrCloseNote,listfindnocase(lstNoteOrder,idxOrder)) eq "Y">
        								<cfset lstApproverNotes = REFULLLISTAPPROVER>
        							<cfelse>
        								<!---cfset lstApproverNotes = StrckListApprover.lstApprover--->
        								<cfif len(StrckListApprover.lstApprover) eq 0>
        									<cfset lstApproverNotes = REFULLLISTAPPROVER>
        								<cfelse>
											<!---cfset lstApproverNotes = StrckListApprover.lstApprover--->
											<cfloop list="#StrckListApprover.lstApprover#" index="idxlist">
												<cfif ListFindNoCase(lstApproverNotes,idxlist) eq 0>
													<cfset lstApproverNotes = ListAppend(lstApproverNotes,idxlist)>
												</cfif>
											</cfloop>
											<cfloop query="qEmpNoteData">
												<cfif ListFindNoCase(lstApproverNotes,qEmpNoteData.rvid) eq 0>
													<cfset lstApproverNotes = ListAppend(lstApproverNotes,qEmpNoteData.rvid)>
												</cfif>
											</cfloop>
											
        								</cfif>
        							</cfif>
        							 <cfif listfindnocase(lstApproverNotes,request.scookie.user.empid) eq 0>
        								<cfset lstApproverNotes = listappend(lstApproverNotes,request.scookie.user.empid)>
        							</cfif>
								</cfif>
		                        <tr>
									<td colspan="2"><b>#HTMLEditFormat(qGetNoteName.note_name[idxOrder])#</b><!--- custom doffice ---></td>
								</tr>
								
								<cfloop list="#lstApproverNotes#" index="idxR">
		                        	<cfquery name="qRNoteData" dbtype="query">	
		                            	SELECT * FROM qEmpNoteData
	    	                            WHERE rvid = <cfqueryparam value="#idxR#" cfsqltype="cf_sql_varchar">
                                        	AND note_order = <cfqueryparam value="#idxOrder#" cfsqltype="cf_sql_numeric">
	        	                    </cfquery>
                                    <cfif not qRNoteData.recordcount>
                                    	<cfif idxR eq request.scookie.user.empid>
                                    	<!---
										<cfinvoke component="SFPerformanceEvaluation" method="getEmpDetail" empid="#idxR#" returnVariable="qRInfo"></cfinvoke>
										--->
					                    <cfset qRInfo = objSFPEV.getEmpDetail(empid=idxR,varcoid=varcoid)>

	                            		<tr>
		                                	<td width="20%" align="center" valign="middle">
											<cfif len(qRInfo.empphoto)>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;thumb=1&amp;fname=#qRInfo.empphoto#" height="70" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qRInfo.empname#">
											<cfelseif len(qRInfo.empgender)>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_noemployee.gif" height="70" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qRInfo.empname#">
											<cfelse>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_nofemployee.gif" height="70" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qRInfo.empname#">
											</cfif>
                                		    </td>
    		                            
        	    	                    	<td>
												<input type="hidden" name="evalnotename_#idxOrder#" value="#qGetNoteName.note_name[idxOrder]#" />
	            	    	                    <textarea name="evalnote_#idxOrder#"  class="addnotes" rows="4"></textarea>
	        	                            </td>
    	        	                    </tr>
                                        </cfif>
                                    <cfelseif len(qRNoteData.note_answer) or qRNoteData.rvid eq request.scookie.user.empid>
                                       
					                    <cfset qRInfo = objSFPEV.getEmpDetail(empid=qRNoteData.rvid,varcoid=varcoid)>

	                            		<tr>
		                                	<td width="20%" align="center" valign="middle">
											<cfif len(qRInfo.empphoto)>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;thumb=1&amp;fname=#qRInfo.empphoto#" height="70" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qRInfo.empname#">
											<cfelseif len(qRInfo.empgender)>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_noemployee.gif" height="70" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qRInfo.empname#">
											<cfelse>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_nofemployee.gif" height="70" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qRInfo.empname#">
											</cfif>
                                		    </td>
    		                            	<td>
            	    	                    <cfif qRNoteData.rvid eq request.scookie.user.empid>
	            	    	                    <textarea name="evalnote_#qRNoteData.note_order#"  class="addnotes" rows="4">#HTMLEditFormat(qRNoteData.note_answer)#</textarea>
                    	    	                <input type="hidden" name="evalnotename_#qRNoteData.note_order#" value="#qRNoteData.note_name#" />
                        	    	        <cfelse>
	    	                	                #HTMLEditFormat(qRNoteData.note_answer)#
    	                        	        </cfif>
	        	                            </td>
    	        	                    </tr>
                                    </cfif>
                                </cfloop>
                            </cfloop>
                        </cfif>
                    	</table>
                    </div>
                </fieldset>
            </div>
	    </div>
    </fieldset>

    <!--- input hidden lainnya --->
	<input type="hidden" name="period_code" value="#periodcode#">
	<input type="hidden" name="reference_date" value="#refdate#">
	<input type="hidden" name="request_no" value="#reqno#">
	<input type="hidden" name="formno" value="#formno#">
	<input type="hidden" name="coid" value="#varcoid#">
	<input type="hidden" name="cocode" value="#varcocode#">
	<input type="hidden" name="planformno" value="#planformno#">
	<input type="hidden" name="listPeriodComponentUsed" value="#listPeriodComp#">
	
	<!--- baru 19 mei 15--->
	<input type="hidden" name="reqformulaorder" value="#reqorder#">

    <!--- contekan simple form --->
	<input type="hidden" name="UserInReviewStep" value="#StrckListApprover.index#" />
	<input type="hidden" name="RevieweeAsApprover" value="#StrckListApprover.reviewee_as_approver#" />
	<input type="hidden" name="FullListAppr" value="#StrckListApprover.FULLLISTAPPROVER#" />  <!---parse for BUG51115-54516--->
    

	<!--- diambil dari iframe dalam --->
	<textarea name="orgKPIArray" id="objectiveorgArray" style="display:none"> </textarea>
	<textarea name="orgKPI_lib" id="objectiveorg_lib" style="display:none"> </textarea>
	<textarea name="persKPIArray" id="objectiveArray" style="display:none"> </textarea>
	<textarea name="persKPI_lib" id="objective_lib" style="display:none"> </textarea>
	<textarea name="appraisalArray" id="appraisalArray" style="display:none"> </textarea>
	<textarea name="appraisal_lib" id="appraisal_lib" style="display:none"> </textarea>
	<textarea name="competencyArray" id="competencyArray" style="display:none"> </textarea>
	<textarea name="competency_lib" id="competency_lib" style="display:none"> </textarea>
    
    <!--- tanda seluruh form sudah ke load --->
    <input type="hidden" id="appraisalform_loaded" value="<cfif not listfindnocase(listPeriodComp,"APPRAISAL")>1<cfelse>0</cfif>" />
    <input type="hidden" id="objectiveorgform_loaded" value="<cfif not listfindnocase(listPeriodComp,"ORGKPI")>1<cfelse>0</cfif>" />
    <input type="hidden" id="objectiveform_loaded" value="<cfif not listfindnocase(listPeriodComp,"PERSKPI")>1<cfelse>0</cfif>" />
    <input type="hidden" id="competencyform_loaded" value="<cfif not listfindnocase(listPeriodComp,"COMPETENCY")>1<cfelse>0</cfif>" />
    <input type="hidden" id="taskform_loaded" value="<cfif not listfindnocase(listPeriodComp,"TASK")>1<cfelse>0</cfif>" />
    <input type="hidden" id="feedbackform_loaded" value="<cfif not listfindnocase(listPeriodComp,"FEEDBACK")>1<cfelse>0</cfif>" />
    
	
	<!----StrckListApprover.approver_headstatus : #StrckListApprover.approver_headstatus# <br>
	StrckListApprover.revise_list_approver : #StrckListApprover.revise_list_approver# <br>
	StrckListApprover.approverbefore_headstatus : #StrckListApprover.approverbefore_headstatus# <br>
	StrckListApprover.index : #StrckListApprover.index# <br>
	StrckListApprover.revise_pos_atstep : #StrckListApprover.revise_pos_atstep# <br>
	request.scookie.user.empid : #request.scookie.user.empid# ---->
	
	
    <!--- get lookup --->
    <cfif len(qPeriodData.conclusion_lookup)>
      	<cfset tempLookUpJSON = objSFPEV.getJSONForLookUp(lookupcode=qPeriodData.conclusion_lookup,periodcode=periodcode,varcocode=varcocode)>
    	<script>
			objConclLookup=JSON.parse('#tempLookUpJSON#');
		</script>
    </cfif>

    <script>
		var plotEvalForm;
		var toplookuptotal = 0;
		function loadPMGaugeImage(skor,skormin,skormax,imgid){
			var gaugescorename = imgid.toLowerCase()+"score";
			if(imgid == 'feedbackGauge'){
				gaugescorename = 'feedgaugescore';}
			if(imgid == 'apprGauge'){
				toplookuptotal = parseInt(document.getElementById('appraisal_totallookup').value);
			}
			if(imgid == 'objOrgGauge'){
				toplookuptotal = parseInt(document.getElementById('objectiveorg_totallookup').value);
			}
			if(imgid == 'objGauge'){
				toplookuptotal = parseInt(document.getElementById('objective_totallookup').value);
			}
			
			var gauge_type = '#qPeriodData.gauge_type#';
			if( toplookuptotal != 1){
				gaugeNo = parseInt(parseFloat((skor-skormin)/(skormax-skormin)) * 20);
			}
			else{
				gaugeNo = parseInt(parseFloat((skor-skormin)/(skormax-skormin)) * 20);
				
			}
			
			
			if(gaugeNo <= 0) {
				if(gauge_type == 'LOWER'){
					gaugeNo = 'kpi/Gauge-0';
					if(parseFloat($('##'+gaugescorename).text()) > 0){
						gaugeNo = 'kpi2/Gauge-20';
					}
				}else{
					gaugeNo= 'kpi/Gauge0';
					if(parseFloat($('##'+gaugescorename).text()) > 0){
						gaugeNo = 'kpi2/Gauge-1';
					}
				}
				top.$("##"+imgid).attr("src","#application.path.lib#/images/charts/"+gaugeNo+".png");
			}
			else{  
				if(gauge_type == 'LOWER'){
			    	gaugeNo = parseInt(20-gaugeNo);
			    	if(gaugeNo <= 1){
			    		gaugeNo = 1;
			    	}
			    }else{
			    	gaugeNo = parseInt(gaugeNo);
			    	if(gaugeNo >= 20){
			    		gaugeNo = 20;
			    	}
			    }
				top.$("##"+imgid).attr("src","#application.path.lib#/images/charts/kpi2/Gauge-"+gaugeNo+".png");
			}
		}

		function calcOverallScore(){
		   
			var gauge_type = '#qPeriodData.gauge_type#';
			var lstConclusion = '#valuelist(qLookUpDet.scoredet_mask,"|")#';
			var lstConclScore = '#valuelist(qLookUpDet.scoredet_value,"|")#';
			var arrCompCode = '#ucase(listPeriodComp)#'.split(',');
			var arrCompWeight = '#valuelist(qEmpPerCompData.weight)#'.split(',');
			
			//console.log(arrCompCode);
			//console.log(arrCompWeight);
			
			var minScore = '#qScoreDet.optvalue[1]#';
			var maxScore = '#qScoreDet.optvalue[qScoreDet.recordcount]#';
			var scoreInd = 0; var scoreTask = 0; var scoreFeed = 0; var scoreAppr = 0; var scoreObj = 0; var scoreComp = 0;

			var overallScore = 0; var totalCredit = 0;
			var arrMultipliedScore = [];
			var objWeightedScore = {};
			var objComponentScore = {};

			if(parseInt($.inArray('APPRAISAL',arrCompCode))>=0){
				var apprCredit = parseFloat(arrCompWeight[$.inArray('APPRAISAL',arrCompCode)]);
				if(parseInt(document.getElementById('appraisal_totallookup').value) != 1){
					scoreAppr	= parseFloat($("##appraisal").val());
				}
				else{
					scoreAppr	= parseFloat($("##appraisal_totallookupSc").val());
				}
				
				loadPMGaugeImage(scoreAppr,minScore,maxScore,'apprGauge');
				arrMultipliedScore.push(scoreAppr * apprCredit);
				objComponentScore['APPRAISAL'] = scoreAppr;
				
				totalCredit += apprCredit;
			}
			if($.inArray('ORGKPI',arrCompCode)>=0){
				var orgKPICredit = parseFloat(arrCompWeight[$.inArray('ORGKPI',arrCompCode)]);
				if(parseInt(document.getElementById('objectiveorg_totallookup').value) != 1){
					scoreOrgKPI	= parseFloat($("##objectiveorg").val());
				}
				else{
					scoreOrgKPI	= parseFloat($("##objectiveorg_totallookupSc").val());
				}
				
				loadPMGaugeImage(scoreOrgKPI,minScore,maxScore,'objOrgGauge');
				
				arrMultipliedScore.push(scoreOrgKPI * orgKPICredit);
				objComponentScore['ORGKPI'] = scoreOrgKPI;

				totalCredit += orgKPICredit;
			}
			
			if(parseInt($.inArray('PERSKPI',arrCompCode))>=0){
				var persKPICredit = parseFloat(arrCompWeight[$.inArray('PERSKPI',arrCompCode)]);
				
				if(parseInt(document.getElementById('objective_totallookup').value) != 1){
					scorePersKPI	= parseFloat($("##objective").val());
				}
				else{
					scorePersKPI	= parseFloat($("##objective_totallookupSc").val());
				}
				var scoreTemp = document.getElementById("objective").value;
				loadPMGaugeImage(scorePersKPI,minScore,maxScore,'objGauge');
				arrMultipliedScore.push(scorePersKPI * persKPICredit);
				objComponentScore['PERSKPI'] = scorePersKPI;
				totalCredit += persKPICredit;
			}
			if(parseInt($.inArray('COMPETENCY',arrCompCode))>=0){
				var compCredit = parseFloat(arrCompWeight[$.inArray('COMPETENCY',arrCompCode)]);
				scoreComp	= parseFloat($("##competency").val());
				
				loadPMGaugeImage(scoreComp,minScore,maxScore,'compGauge');
				
				arrMultipliedScore.push(scoreComp * compCredit);
				objComponentScore['COMPETENCY'] = scoreComp;
				
				totalCredit += compCredit;
			}
			if(parseInt($.inArray('TASK',arrCompCode))>=0){
				var taskCredit = parseFloat(arrCompWeight[$.inArray('TASK',arrCompCode)]);
				scoreTask	= parseFloat($("##task").val());

				loadPMGaugeImage(scoreTask,minScore,maxScore,'taskGauge');

				arrMultipliedScore.push(scoreTask * taskCredit);
				objComponentScore['TASK'] = scoreTask;

				totalCredit += taskCredit;
			}
			if($.inArray('FEEDBACK',arrCompCode)>=0){
				var feedbackCredit = parseFloat(arrCompWeight[$.inArray('FEEDBACK',arrCompCode)]);
				scoreFeed	= parseFloat($("##feedback").val());
				
				loadPMGaugeImage(scoreFeed,minScore,maxScore,'feedbackGauge');
				
				arrMultipliedScore.push(scoreFeed * feedbackCredit);
				objComponentScore['FEEDBACK'] = scoreFeed;

				totalCredit += feedbackCredit;
			}

			overallScore = 0;
			$.each( arrMultipliedScore, function( i, val ) {
				overallScore += parseFloat(val);
			});
			
			overallScore = parseFloat(overallScore/totalCredit);
			overallScore = round(overallScore,#InitVarCountDeC#);
			
			//gaugeNo = parseInt(parseFloat(overallScore/maxScore) * 20);
			var minOverallScore = '#qLookUpDet.optvalue[1]#';
			var maxOverallScore = '#qLookUpDet.optvalue[qLookUpDet.recordcount]#';
			gaugeNo = parseInt(parseFloat((overallScore-minOverallScore)/(maxOverallScore-minOverallScore)) * 20);

			//console.log(overallScore+" "+minOverallScore+" "+maxOverallScore+" "+gaugeNo);
			if(gaugeNo <= 0) {
				var emptygg = '';
				if(gauge_type == 'LOWER'){
					emptygg = 'kpi/Gauge-0';
					if(parseFloat(overallScore) > 0){
						emptygg = 'kpi2/Gauge-20';
					}
				}else{
					emptygg = 'kpi/Gauge0';
					if(parseFloat(overallScore) > 0){
						emptygg = 'kpi2/Gauge-1';
					}
					/*
					console.log("overall score2 " + overallScore);
					*/
				}
				/*
				console.log("gauge type "+gauge_type);
				console.log("emptygg " + emptygg);
				*/
				top.$("##overallGauge").attr("src","#application.path.lib#/images/charts/"+emptygg+".png");
				/*
				console.log("overall score3 " + overallScore);
				*/
			}
			else{
				if(gauge_type == 'LOWER'){
			    	gaugeNo = parseInt(20-gaugeNo);
			    	if(gaugeNo <= 1){
			    		gaugeNo = 1;
			    	}
			    }else{
			    	gaugeNo = parseInt(gaugeNo);
			    	if(gaugeNo >= 20){
			    		gaugeNo = 20;
			    	}
			    }
			    /*
			    console.log("gaugeNo " + gaugeNo);
				*/
				top.$("##overallGauge").attr("src","#application.path.lib#/images/charts/kpi2/Gauge-"+gaugeNo+".png");
			}
			
			//BUG50515-43230 START
			/*
			if(overallScore<parseFloat(minOverallScore)){
				$("div[class='gauge-rate-all']").html(overallScore); // minOverallScore
				$("##overall").val(minOverallScore);
			}
			else{
				$("div[class='gauge-rate-all']").html(overallScore);
				$("##overall").val(overallScore);
			}
			*/
			$("div[class='gauge-rate-all']").html(overallScore);
			$("##overall").val(overallScore);
			//BUG50515-43230 END

			//ganti conclusion
			var changeConclusion = 1;
			$.each( objComponentScore, function( key, value ) {
				switch(key){
					case 'APPRAISAL' : 
						$('##appraisal_weighted').val((objComponentScore[key]*arrCompWeight[$.inArray('APPRAISAL',arrCompCode)])/totalCredit);
						$('##iframe1').contents().find('##framecontent_1').contents().find('select[name^="appr_score_"]').each(function(){
						   if(!$(this).val().length){
            					changeConclusion = 0;
						        return false;
						   }
						});
					case 'ORGKPI' : 
						$('##objectiveorg_weighted').val((objComponentScore[key]*arrCompWeight[$.inArray('ORGKPI',arrCompCode)])/totalCredit);
						$('##iframe1').contents().find('##framecontent_2').contents().find('select[name^="org_score_"]').each(function(){
						   if(!$(this).val().length){
            					changeConclusion = 0;
						        return false;
						   }
						});
					case 'PERSKPI' : 
						$('##objective_weighted').val((objComponentScore[key]*arrCompWeight[$.inArray('PERSKPI',arrCompCode)])/totalCredit);
						$('##iframe1').contents().find('##framecontent_3').contents().find('select[name^="pers_score_"]').each(function(){
						   if(!$(this).val().length){
            					changeConclusion = 0;
						        return false;
						   }
						});
					case 'COMPETENCY' : 
						$('##competency_weighted').val((objComponentScore[key]*arrCompWeight[$.inArray('COMPETENCY',arrCompCode)])/totalCredit);
						$('##iframe1').contents().find('##framecontent_4').contents().find('select[name^="comp_score_"]').each(function(){
						   if(!$(this).val().length){
            					changeConclusion = 0;
						        return false;
						   }
						});
					case 'TASK' : 
						$('##task_weighted').val((objComponentScore[key]*arrCompWeight[$.inArray('TASK',arrCompCode)])/totalCredit);
					case 'FEEDBACK' : 
						$('##feedback_weighted').val((objComponentScore[key]*arrCompWeight[$.inArray('FEEDBACK',arrCompCode)])/totalCredit);
				}
				if(changeConclusion == 0){
					return;
				}
				/*
				if(objComponentScore[key] == 0){
					changeConclusion = 0;
					return;
				}
				*/
			});
			
			if(changeConclusion){
				var arrConclScore = lstConclScore.split("|");
				var conclOrderNo = arrConclScore.length - 1 ;

				for(z=0;z<arrConclScore.length;z++){
					//console.log(parseFloat(overallScore) + ' < '+parseFloat(arrConclScore[z]))				
					if(parseFloat(overallScore) <= parseFloat(arrConclScore[z])){
						conclOrderNo = z;
						break;
					}
				}
				
				if(conclOrderNo < 0) conclOrderNo = 0;

				$(".conclusion").html(lstConclusion.split("|")[conclOrderNo]);
				$("##overall_concl").val(lstConclusion.split("|")[conclOrderNo]);
				empscore = lstConclusion.split("|")[conclOrderNo];

				/*
				$(".conclusion").html(lstConclusion.split("|")[Math.round(overallScore)-1]);
				$("##overall_concl").val(lstConclusion.split("|")[Math.round(overallScore)-1]);
				empscore = lstConclusion.split("|")[Math.round(overallScore)-1]
				*/
			}
			else{
				$(".conclusion").html("#REQUEST.SFMLANG['Incomplete']#");
				$("##overall_concl").val("-");
				empscore = lstConclusion.split("|")[Math.round(overallScore)-1]
				//empscore = ''
			}
			
			//reload distribution curve
			if(('#UCASE(qPeriodData.usenormalcurve)#' == 'Y')&&(oldempscore!=empscore)){
    			$('##iframescore').attr('src', '?sfid=hrm.performance.evalform.normalcurve&reqno=#reqno#&empid=#empid#&periodcode=#periodcode#&empscore='+empscore+'&gaugetype=#qPeriodData.gauge_type#');
    			oldempscore=empscore;
			}
		}
		
		var oldempscore = ""; //BUG50515-43695
		
		calcOverallScore();

	function pmShowHideBtn(showList){
		
		yPMShowHideBTnCalled = true;
		var arrBtnList = showList.split(",");
		var indexPrevbtn = arrBtnList.indexOf("6"); //<!---TCK1907-0513574 remove preview button--->
		if(indexPrevbtn !== -1){
		    arrBtnList.splice(indexPrevbtn, 1);
		}
			
			
		$('a[id^="btn_a_"]').each(function(){
			if(jQuery.inArray($(this).attr("id").split("_")[2],arrBtnList) > -1){
				$(this).css("display","");
			}
			else{
				$(this).css("display","none");
			}
		});
	}
	
	
	//<!---TCK2002-0548467--->
    function Startmathround(value, exp) {
        if (typeof exp === 'undefined' || +exp === 0)
        return Math.round(value);
        
        value = +value;
        exp = +exp;
        
        if (isNaN(value) || !(typeof exp === 'number' && exp % 1 === 0))
        return NaN;
        
        // Shift
        value = value.toString().split('e');
        value = Math.round(+(value[0] + 'e' + (value[1] ? (+value[1] + exp) : exp)));
        
        // Shift back
        value = value.toString().split('e');
        return +(value[0] + 'e' + (value[1] ? (+value[1] - exp) : -exp));
    }
    function round(value, exp){
        var result = Startmathround(value, exp);
        return result.toString();
    }
    //<!---TCK2002-0548467--->
	
	</script>
<cfset lstBtnToShow = "0">
<div id="script-to-show-or-hide-buttons">

<cfif len(reqno)>
	<cfif retVarCheckParam eq true> <!--- set display button for case :  system using pre-generate reviewer ---->
    	
    	<cfif (ListFindNoCase(strckListApprover.FULLLISTAPPROVER,strckListApprover.lastapprover) gt ListFindNoCase(strckListApprover.FULLLISTAPPROVER,strckListApprover.lstapprover)) AND (strckListApprover.lastapprover neq strckListApprover.lstapprover) AND qCheckHPerReviewer.head_status eq 0 AND NOT ListFindNoCase(strckListApprover.CURRENT_OUTSTANDING_LIST,request.scookie.user.uid) >
			<cfset SFLANG=Application.SFParser.TransMLang("JSApprover in higher step has approved this performance form, you draft can't be proceed",true)>
			<cfoutput>
				<script>
				pmShowHideBtn("0,1");
				alert("#SFLANG#");
				</script>
			</cfoutput>
		<cfelse>
				
		<cfswitch expression="#StrckListApprover.status#"> 
		
		
				<cfcase value="1">
						
						<cfif qCheckSelf.recordcount eq 0 >
							<cfif qCheckHPerReviewer.recordcount gt 0>
								<cfif qCheckHPerReviewer.head_status eq '0'>
									<cfset lstBtnToShow = "0,1,3,4,6">
								</cfif>
							<cfelse>
								<cfset lstBtnToShow = "0,3,4,6">
							</cfif>
						<cfelse>
							<cfif qCheckHPerReviewer.recordcount gt 0>
								<cfif qCheckHPerReviewer.head_status eq '0' AND qCheckSelf.head_status eq 1>
									<cfset lstBtnToShow = "0,1,2,3,4,6">
								<cfelse>
									<cfif qCheckHPerReviewer.head_status neq 1>
										<cfset lstBtnToShow = "0,1,3,4,6">
									<cfelse>
										<cfset lstBtnToShow = "0">
									</cfif>
								</cfif>
							<cfelse>
								<cfif strckListApprover.lastapprover eq "">
									<cfset lstBtnToShow = "0,3,4,6">
								<cfelse>
									<cfset lstBtnToShow = "0,2,3,4,6">
								</cfif>
								
							</cfif>
						</cfif>
						<cfif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
							<script>
							setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
							/*	$('##btn_a_4').attr("onclick","");
								$('##btn_a_4').click(function(){
									sendDirectFinal();
								});*/
							</script>
						
						<cfelse>
							<script>
							setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
								$('##btn_a_4').attr("onclick","");
								$('##btn_a_4').click(function(){
									sendDirectPartially(); 
								});
							</script>
						</cfif>
							
					</cfcase>
					
				
				<cfcase value="2">
					<cfset yesIsApprover = 0>
					<cfloop list="#StrckListApprover.FullListApprover#" delimiters="," index="idxLoop">
						<cfif Listfindnocase(idxLoop,request.scookie.user.empid,"|") gt 0>
							<cfset yesIsApprover = 1>
						<cfelseif idxLoop eq request.scookie.user.empid>
							<cfset yesIsApprover = 1>
						</cfif>
					</cfloop>
					<cfif StrckListApprover.approver_headstatus eq 1 or (not listfindnocase(StrckListApprover.LstApprover,request.scookie.user.empid) AND yesIsApprover eq 0)>
						<cfset lstBtnToShow = "0">
					<cfelse>
						<cfif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
							<cfset lstBtnToShow = "0,3,4,6">
							<script>
								setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
								$('##btn_a_4').attr("onclick","");
								$('##btn_a_4').click(function(){
									sendDirectFinal();
								});
							</script>
						<cfelse>
							<cfset lstBtnToShow = "0,3,4,6">
							<script>
								setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
								$('##btn_a_4').attr("onclick","");
								$('##btn_a_4').click(function(){
									sendDirectPartially(); 
								});
							</script>
						</cfif>

						<cfif StrckListApprover.approverbefore_headstatus and not listfindnocase(listfirst(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
					        <cfset lstBtnToShow = "0,2,3,4,6">
    						<script>
        						setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
        						//$('a[id="btn_a_2"]').css("display","");
    						</script>
						</cfif>
					</cfif>
					<cfif flgUnfinal eq 1>
						<cfset lstBtnToShow = "0">
					<cfelseif ListFindNoCase(qCheckIfRequestIsUnfinal.modified_by,"unfinal","|") gt 0 AND qCheckIfRequestIsUnfinal.reviewer_empid eq REQUEST.SCOOKIE.USER.EMPID>
					 <!---   <cfset lstBtnToShow = ListDeleteAt( lstBtnToShow, ListFind(lstBtnToShow,'2')) />  --->
					    <!---<cfset lstBtnToShow = ListDeleteAt( lstBtnToShow, ListFind(lstBtnToShow,'3')) />--->
					    <cfset lstBtnToShow =  "0,3,4,6"/> 
						<cfif StrckListApprover.approverbefore_headstatus and not listfindnocase(listfirst(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
							<cfset lstBtnToShow =ListAppend(lstBtnToShow, '2' ) >
						</cfif>
						<script>
						
						setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
						//$('a[id="btn_a_2"]').css("display","none");
						//$('a[id="btn_a_3"]').css("display","none");
						</script>
					</cfif>
				</cfcase>
				<cfcase value="3">
					<cfif StrckListApprover.lastapprover eq REQUEST.SCOOKIE.USER.EMPID>
						<cfset lstBtnToShow = "0,5">
					</cfif>
				</cfcase>
				<cfcase value="4">
						<cfset newlistrevise = StrckListApprover.REVISE_LIST_APPROVER>
						<cfset delmulaidari = ListFindNoCase(StrckListApprover.REVISE_LIST_APPROVER,StrckListApprover.LASTAPPROVER,",")>
						<cfif delmulaidari gt 0 AND val(delmulaidari-1) gt 1 >
			                <cfset tempDelTo = val(listlen(StrckListApprover.REVISE_LIST_APPROVER) - delmulaidari)> <!---TCK1906-0510896--->
							<!---<cfloop from="#delmulaidari#" to="#val(delmulaidari-1)#" index="idxdel">--->
							<cfloop from="#delmulaidari#" to="#val(delmulaidari+tempDelTo)#" index="idxdel">
								<cfset newlistrevise = ListDeleteAt(newlistrevise, "#idxdel#",",")>
							</cfloop>
						<cfelse>
							<cfset newlistrevise = ListDeleteAt(newlistrevise, "#delmulaidari#",",")>
						</cfif>
						<cfif ListLen(ListLast(newlistrevise,','),'|') eq 1>
							<cfif REQUEST.SCOOKIE.USER.EMPID eq ListLast(newlistrevise)>
									<cfif REQUEST.SCOOKIE.USER.EMPID neq empid>
										<cfif qCheckSelf.recordcount gt 0>
											<cfset lstBtnToShow = "0,2,3,4,6">
										<cfelse>
											<cfset lstBtnToShow = "0,3,4,6">
										</cfif>
										
									<cfelse>
										<cfset lstBtnToShow = "0,3,4,6">
									</cfif>
							</cfif>
						<cfelse>
							<cfloop list="#ListLast(newlistrevise,',')#" delimiters="|" index="idxRevise">
								<cfif REQUEST.SCOOKIE.USER.EMPID eq idxRevise>
									<cfif idxRevise neq empid>
										<cfif qCheckSelf.recordcount gt 0>
											<cfset lstBtnToShow = "0,2,3,4,6">
										<cfelse>
											<<cfset lstBtnToShow = "0,3,4,6">
										</cfif>
										
									<cfelse>
										<cfset lstBtnToShow = "0,3,4,6">
									</cfif>
								</cfif>
							</cfloop>
						</cfif>
						
						
				</cfcase>
				<cfdefaultcase>
					<cfset lstBtnToShow = "0">
				</cfdefaultcase> 
			</cfswitch>
		</cfif>
		
	<cfelse> <!---- when system not using pregenerate reviewer ---->
	
	<cfif (ListFindNoCase(strckListApprover.FULLLISTAPPROVER,strckListApprover.lastapprover) gt ListFindNoCase(strckListApprover.FULLLISTAPPROVER,strckListApprover.lstapprover)) AND (strckListApprover.lastapprover neq strckListApprover.lstapprover) AND qCheckHPerReviewer.head_status eq 0 AND NOT ListFindNoCase(strckListApprover.CURRENT_OUTSTANDING_LIST,request.scookie.user.uid) >
			<cfset SFLANG=Application.SFParser.TransMLang("JSApprover in higher step has approved this performance form, you draft can't be proceed",true)>
			<cfoutput>
				<script>
				pmShowHideBtn("0,1");
				alert("#SFLANG#");
				</script>
			</cfoutput>
		
	<cfelse>
		
	<cfswitch expression="#StrckListApprover.status#"> 
	    <cfcase value="0">
        	<cfif StrckListApprover.approver_headstatus eq 1>
		    	<cfset lstBtnToShow = "0">
            <cfelseif StrckListApprover.approver_headstatus eq 0>
				<cfset lstBtnToShow = "0,1,3,4,6">
		    	<script>
					setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
					
					$('##btn_a_4').attr("onclick","");
					$('##btn_a_4').click(function(){
						sendfromdraft(); //sama biar ke fungsi Save aja.
					});
                </script>
			<cfelseif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
				<cfset lstBtnToShow = "0,1,3,4,6">
				<script>
					setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
					$('##btn_a_4').attr("onclick","");
					$('##btn_a_4').click(function(){
						sendDirectFinal();
					});
				</script>
            <cfelse>
		    	<cfset lstBtnToShow = "0,1,3,4,6">
            </cfif>
	    </cfcase>
	    <cfcase value="1"><!--- udah bisa revise, tapi head_status belum berubah --->
        	<cfif StrckListApprover.lastapprover eq request.scookie.user.empid AND StrckListApprover.APPROVER_HEADSTATUS EQ 1>
		    	<cfset lstBtnToShow = "0">
			<cfelseif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
				<cfset lstBtnToShow = "0,2,3,4,6">
				<script>
					setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
					$('##btn_a_4').attr("onclick","");
					$('##btn_a_4').click(function(){
						FinalConclusion();
					});
				</script>
            <cfelseif StrckListApprover.approver_headstatus eq 0>
				<cfset lstBtnToShow = "0,2,3,4,6">
		    	<script>
					setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
					$('##btn_a_4').attr("onclick","");
					$('##btn_a_4').click(function(){
						sendfromdraft(); //sama biar ke fungsi Save aja.
					});
                </script>
            <cfelse>
		    	<cfset lstBtnToShow = "0,2,3,4,6">
            </cfif>
	    </cfcase>
	    <cfcase value="2">
	         <cfset yesIsApprover = 0>
					<cfloop list="#StrckListApprover.FullListApprover#" delimiters="," index="idxLoop">
						<cfif Listfindnocase(idxLoop,request.scookie.user.empid,"|") gt 0>
							<cfset yesIsApprover = 1>
						<cfelseif idxLoop eq request.scookie.user.empid>
							<cfset yesIsApprover = 1>
						</cfif>
					</cfloop>
					<cfif StrckListApprover.approver_headstatus eq 1 or (not listfindnocase(StrckListApprover.LstApprover,request.scookie.user.empid) AND yesIsApprover eq 0)>
						<cfset lstBtnToShow = "0">
					<cfelse>
						<cfif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
							<cfset lstBtnToShow = "0,3,4,6">
							<script>
								setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
								$('##btn_a_4').attr("onclick","");
								$('##btn_a_4').click(function(){
									sendDirectFinal();
								});
							</script>
						<cfelse>	
							<cfset lstBtnToShow = "0,3,4,6">
							<script>
								setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
								$('##btn_a_4').attr("onclick","");
								$('##btn_a_4').click(function(){
									sendDirectPartially(); 
								});
								
							</script>
						</cfif>

						<cfif StrckListApprover.approverbefore_headstatus and not listfindnocase(listfirst(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
							<cfset lstBtnToShow =ListAppend(lstBtnToShow, '2' ) >
						<script>
						setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
						//$('a[id="btn_a_2"]').css("display","");
						</script>
						</cfif>
					</cfif>
					<cfif flgUnfinal eq 1>
						<cfset lstBtnToShow = "0">
					<cfelseif ListFindNoCase(qCheckIfRequestIsUnfinal.modified_by,"unfinal","|") gt 0 AND qCheckIfRequestIsUnfinal.reviewer_empid eq REQUEST.SCOOKIE.USER.EMPID>
					   <!--- <cfset lstBtnToShow = ListDeleteAt( lstBtnToShow, ListFind(lstBtnToShow,'2')) />---->
					    <!---<cfset lstBtnToShow = ListDeleteAt( lstBtnToShow, ListFind(lstBtnToShow,'3')) />--->
					    <cfset lstBtnToShow =  "0,3,4,6"/> 
						<cfif StrckListApprover.approverbefore_headstatus and not listfindnocase(listfirst(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
							<cfset lstBtnToShow =ListAppend(lstBtnToShow, '2' ) >
						</cfif>
						<script>
						setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
						//$('a[id="btn_a_2"]').css("display","none");
						//$('a[id="btn_a_3"]').css("display","none");
						</script>
					</cfif>
	    </cfcase>
	    <cfcase value="3">
	        <!---cfif listlast(StrckListApprover.FullListApprover) eq request.scookie.user.empid--->
	        <cfif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
		    	<cfset lstBtnToShow = "0,5">
	        <cfelse>
		    	<cfset lstBtnToShow = "0">
	        </cfif>
        </cfcase>
		<cfcase value="4">
        	<cfif StrckListApprover.approver_headstatus eq 1>
				<cfset lstBtnToShow = "0">
        	<cfelseif not listfindnocase(StrckListApprover.revise_list_approver,request.scookie.user.empid)>
            	<cfif StrckListApprover.index lte StrckListApprover.revise_pos_atstep>
					<cfset lstBtnToShow = "0">
                <cfelse>
			    	<cfset lstBtnToShow = "0">
                </cfif>
            <cfelseif StrckListApprover.approverbefore_headstatus eq 0>
            	<cfif listfirst(StrckListApprover.revise_list_approver) eq request.scookie.user.empid>
			    	<cfset lstBtnToShow = "0,1,3,4,6">
                <cfelse>
			    	<cfset lstBtnToShow = "0">
                </cfif>
            <cfelse>
		    	<cfset lstBtnToShow = "0,3,4,6">
	        	<cfif StrckListApprover.approverbefore_headstatus and listfirst(StrckListApprover.revise_list_approver) neq request.scookie.user.empid>
	        	    <cfset lstBtnToShow =ListAppend(lstBtnToShow, '2' ) >
			    	<script>
					setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
					//$('a[id="btn_a_2"]').css("display","");
					</script>
	            </cfif>
            </cfif>
            
            
            <!--- Tombol revise tidak tampil dengan logic diatas, copy dari yg kondisi pregenerate tombol berhasil muncul --->
			<cfset newlistrevise = StrckListApprover.REVISE_LIST_APPROVER>
			<cfset delmulaidari = ListFindNoCase(StrckListApprover.REVISE_LIST_APPROVER,StrckListApprover.LASTAPPROVER,",")>
			<cfif delmulaidari gt 0 AND val(delmulaidari-1) gt 1 >
			    <cfset tempDelTo = val(listlen(StrckListApprover.REVISE_LIST_APPROVER) - delmulaidari)> <!---TCK1906-0510896--->
				<!--- <cfloop from="#delmulaidari#" to="#val(delmulaidari-1)#" index="idxdel"> --->
				<cfloop from="#delmulaidari#" to="#val(delmulaidari+tempDelTo)#" index="idxdel"> <!---TCK1906-0510896--->
					<cfset newlistrevise = ListDeleteAt(newlistrevise, "#idxdel#",",")>
				</cfloop>
			<cfelse>
				<cfset newlistrevise = ListDeleteAt(newlistrevise, "#delmulaidari#",",")>
			</cfif>
			<cfif ListLen(ListLast(newlistrevise,','),'|') eq 1>
				<cfif REQUEST.SCOOKIE.USER.EMPID eq ListLast(newlistrevise)>
						<cfif REQUEST.SCOOKIE.USER.EMPID neq empid>
							<cfif qCheckSelf.recordcount gt 0>
								<cfset lstBtnToShow = "0,2,3,4,6">
							<cfelse>
								<cfset lstBtnToShow = "0,3,4,6">
							</cfif>
							
						<cfelse>
							<cfset lstBtnToShow = "0,3,4,6">
						</cfif>
				</cfif>
			<cfelse>
				<cfloop list="#ListLast(newlistrevise,',')#" delimiters="|" index="idxRevise">
					<cfif REQUEST.SCOOKIE.USER.EMPID eq idxRevise>
						<cfif idxRevise neq empid>
							<cfif qCheckSelf.recordcount gt 0>
								<cfset lstBtnToShow = "0,2,3,4,6">
							<cfelse>
								<<cfset lstBtnToShow = "0,3,4,6">
							</cfif>
							
						<cfelse>
							<cfset lstBtnToShow = "0,3,4,6">
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
            <!--- Tombol revise tidak tampil dengan logic diatas, copy dari yg kondisi pregenerate tombol berhasil muncul --->
            
            
	    </cfcase>
		 <cfcase value="9">
	        <cfif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
		    	<cfset lstBtnToShow = "0,5">
	        <cfelse>
		    	<cfset lstBtnToShow = "0">
	        </cfif>
        </cfcase>
	    <cfdefaultcase>
	    	<cfset lstBtnToShow = "0">
	    </cfdefaultcase> 
	</cfswitch>
	
	
	</cfif>
	
	
	
	</cfif>
	
<cfelseif not len(periodcode)>
	<cfset lstBtnToShow = "0">
<cfelseif listlast(StrckListApprover.FullListApprover) eq request.scookie.user.empid>
	<cfset lstBtnToShow = "0,3,4,6">
   	<script>
		setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
		$('##btn_a_4').attr("onclick","");
		$('##btn_a_4').click(function(){
			pmFinalConclusion();
		});
    </script>
<cfelse>
   	<cfset lstBtnToShow = "0,3,4,6">
</cfif>
<!--- compare now() vs range of evaluation date range from setting --->
<cfset finalstartdate = DateFormat(qPeriodData.final_startdate)>
<cfset finalenddate = DateFormat(qPeriodData.final_enddate)>
<cfset harini = DateFormat(Now())>
<cfset dayafterstart = DateDiff('d', finalstartdate, harini)>
<cfset daybeforeend = DateDiff('d', harini, finalenddate)>
<cfif dayafterstart lt 0 OR daybeforeend lt 0>
	<cfset lstBtnToShow = "0">
</cfif>
<cfif (DateDiff("d", qPeriodData.final_enddate, Now()) gt 0 OR DateDiff("d", qPeriodData.final_startdate, Now()) lt 0)>
	<cfset lstBtnToShow = "0">
</cfif>

<input type="hidden" id="IdlstLoadedTab" value="">
<input type="hidden" id="IdlstDefinedTab" value="">

<script>
	//setTimeout(function(){pmShowHideBtn("#lstBtnToShow#");}, 15000);
	lstDefinedTab = [];
	<cfloop list="#listPeriodComp#" index="idxname">
	    <cfif ListFindNoCase('APPRAISAL,ORGKPI,PERSKPI,COMPETENCY,TASK,FEEDBACK',idxname)>
	        lstDefinedTab['#UCase(idxname)#'] = '#UCase(idxname)#';
	    </cfif>
	</cfloop>
	document.getElementById('IdlstDefinedTab').value = Object.keys(lstDefinedTab).length;
	
	lstLoadedTab = [];
	function checkIsAllTabLoaded(a=''){
	    //console.log(a);
	    lstLoadedTab[a.toUpperCase()] = a.toUpperCase();
	    
	    if(Object.keys(lstLoadedTab).length == Object.keys(lstDefinedTab).length){
	        pmShowHideBtn("#lstBtnToShow#");
	    }
		document.getElementById('IdlstLoadedTab').value = Object.keys(lstLoadedTab).length;
	}
</script>

  <!---TCK1907-0513574---> 
   
    <cfif strckListApprover.status EQ '0' AND strckListApprover.APPROVER_HEADSTATUS NEQ '0' AND UCASE(allowskipCompParam) NEQ 'Y' AND len(reqno)> <!--- Jika status draft dan yg membuka form bukan pembuat draft--->
        <cfset willskipFlag=1>
    </cfif>

    <cfif willskipFlag eq 1>
        <cfif UCASE(allowskipCompParam) NEQ 'Y'  > <!---TCK1907-0513574 AND jika status bukan fully approve atau closed--->  
            <cfset SFLANG5=Application.SFParser.TransMLang("JSYou can’t submit this form before previous reviewer submit it first",true)>
        	<cfoutput>
        		<script>
        		    alert("#SFLANG5#");
        		    setTimeout(function(){popClose()},500);
        		</script>
        	</cfoutput>
        </cfif>
    </cfif>
    <!---TCK1907-0513574---> 
</div>    
</cfoutput>
















