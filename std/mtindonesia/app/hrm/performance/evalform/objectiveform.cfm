<cfsetting showdebugoutput="Yes" enablecfoutputonly="Yes">
<cfparam name="isajax" default="No">
<cfparam name="reqno" default="">
<cfparam name="formno" default="">
<cfparam name="empid" default="">
<cfparam name="periodcode" default="">
<cfparam name="refdate" default="">
<cfparam name="planformno" default="">
<cfparam name="preview" default="false">
<cfparam name="depth" default="2">
<!--- start : ENC51115-79853 --->
<cfparam name="varcoid" default="#REQUEST.SCOOKIE.COID#">
<cfparam name="varcocode" default="#request.scookie.cocode#">
<!--- end : ENC51115-79853 --->
<!--- list preview reviewer--->
<cfparam name="lpr" default="">
<!--- last reviewer --->
<cfparam name="lastrevby" default="">


<cfset FORMMLANG="Action|No|Recommended Training|Due Date|Actual Date|Recommended By|Add Training Plan|Delete Training Plan|Fill Event|Feedback|Evaluation|Or|Not Yet|View Chart|Weight|Weighted Score|Total Weight|Total Weighted Score|Lookup Result">
<!---<cfset REQUEST.SFMLANG=Application.SFParser.TransMLang(listAppend("No|",(isdefined("FORMMLANG")?FORMMLANG:"")))>--->
<cfset REQUEST.SFMLANG=Application.SFParser.TransMLang(FORMMLANG)>

<cfset achievementtype = "">
<cfset lookuptype = "">

<cfset objSFPEV = createobject("component","SFPerformanceEvaluation")>
<cfif NOT isDefined('objSFPEV.isGeneratePrereviewer')>
    <cfset retVarCheckParam = false>
<cfelse>
    <cfset retVarCheckParam = objSFPEV.isGeneratePrereviewer()>
</cfif>

<!---TCK0818-81809--->
<cfset strckListApproverEvalH = objSFPEV.GetApproverList(empid=empid,reqno=reqno,emplogin=request.scookie.user.empid,varcoid=varcoid,varcocode=varcocode)>
<!---TCK0818-81809--->

<!---TCK2002-0548467--->
<cfset VarNumFormatConf = request.config.NUMERIC_FORMAT>
<cfset VargetDecimalAfter = ListLast(VarNumFormatConf,'.')>
<!--- <cfset InitVarCountDeC = LEN(VargetDecimalAfter)> --->
<cfset InitVarCountDeC = 10>
<!---TCK2002-0548467--->


<cfset objSFPMON = createobject("component","SFPerformanceMonitoring")>
<cfset LstPrevReviewer = lpr>
<cfset emplogin = request.scookie.user.empid>
<cfif reqno eq "">
	<cfquery name="qCheckPlanH" datasource="#request.sdsn#">
		SELECT reviewer_empid FROM TPMDPERFORMANCE_PLANH
		WHERE form_no = <cfqueryparam value="#planformno#" cfsqltype="cf_sql_varchar">
		AND isfinal=1 order by created_date desc
	 </cfquery>

	 <cfif qCheckPlanH.recordcount gt 0 >
		<cfset lastrevby = qCheckPlanH.reviewer_empid>
	 </cfif>
</cfif>
<!--- ambil data info si reviewee (sementara)--->
<cfset qEmpInfo = objSFPEV.getEmpDetail(empid=empid,varcoid=varcoid)>
<!--- ambil data info si reviewer --->
<cfset qReviewerInfo = objSFPEV.getEmpDetail(empid=request.scookie.user.empid,varcoid=varcoid)>

<!--- ambil data form reviewee (baik sudah direquest ataupun tidak) --->
<cfif preview>
    <cfset objSFPLAN = createobject("component","SFPerformancePlanning")>
    <cfset qEmpFormData = objSFPLAN.getEmpFormData(empid=empid,periodcode=periodcode,reqno=reqno,formno=formno,refdate=refdate,compcode="PERSKPI",reviewerempid=request.scookie.user.empid,posid=qEmpInfo.dept_id)>
<cfelse>
	 <cfquery name="qCheckEvalH" datasource="#request.sdsn#">
		SELECT head_status FROM TPMDPERFORMANCE_EVALH
		WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
		AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
		AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
	 </cfquery>
	  <cfif (strckListApproverEvalH.STATUS EQ 4 AND qCheckEvalH.head_status eq 1) OR reqno eq "">
		<cfset qEmpFormData = objSFPEV.getEmpFormData(empid=empid,periodcode=periodcode,reqno=reqno,formno=formno,refdate=refdate,compcode="PERSKPI",reviewerempid=lastrevby,lastreviewer=lastrevby,varcoid=varcoid,varcocode=varcocode)>
	 <cfelse>
		<cfset qEmpFormData = objSFPEV.getEmpFormData(empid=empid,periodcode=periodcode,reqno=reqno,formno=formno,refdate=refdate,compcode="PERSKPI",reviewerempid=REQUEST.SCOOKIE.USER.EMPID,lastreviewer=lastrevby,varcoid=varcoid,varcocode=varcocode)>
	 </cfif>
</cfif>

<!--- ambil personal KPI weight --->
<cfset qGetPersKPIWeight = objSFPEV.getPeriodCompData(periodcode=periodcode,refdate=refdate,compcode="PERSKPI",posid=qEmpInfo.posid)>

<!--- ambil semua score type yang diperlukan--->
<cfset qGetScoring = objSFPEV.getActualAndScoreType(periodcode=periodcode,compcode="PERSKPI",varcocode=varcocode)>
<!--- ambil default ach score type--->
<cfset qAchDefScoreDet = objSFPEV.getScoringDetail(scorecode=qGetScoring.actual_type, varcocode=varcocode)>

<cfset qPeriodData = objSFPEV.getPeriodData(periodcode=periodcode,refdate=refdate,varcocode=varcocode)>
<cfset qTotalLookupScTy = objSFPEV.getScoringDetail(scorecode=qPeriodData.score_type,varcocode=varcocode)>

<!--- ambil score type--->
<cfset qScoreDet = objSFPEV.getScoringDetail(scorecode=qGetScoring.score_type,varcocode=varcocode)>
<!--- JSON Default Look Up for Pers Obj component (Default) --->
<cfset defLookUpJSON = objSFPEV.getJSONForLookUp(lookupcode=qGetScoring.lookup_code,periodcode=periodcode,varcocode=varcocode)>

<!--- ENC51017-81177 cek lookup total status --->
<cfset varlookupontotal =val(qGetPersKPIWeight.lookup_total)>
<!--- END --->

<!--- add : ENC50216-80177 cek kalo ada di PLAND --->
<cfquery name="qGetFromPlan" datasource="#request.sdsn#">
    SELECT form_no, reviewer_empid FROM TPMDPERFORMANCE_PLANH
    WHERE period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
   	AND company_code = <cfqueryparam value="#varcocode#" cfsqltype="cf_sql_varchar">
    AND reference_date = <cfqueryparam value="#refdate#" cfsqltype="cf_sql_timestamp">
    AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
    AND isfinal = 1
    order by created_date desc
</cfquery>
<!---end : ENC50216-80177--->
<cfoutput>
<style>
	.rotextinput{
		border:none;
		/*text-align:center;*/
		background-color:transparent;
	}
	.coltitle{
		font-size:12px; padding:5px; color:white;
		text-align:center;
	}
	.grpbtnlib{
		float:right;
	}
	.oddrow{
		background-color:white;
	}

	textarea {
		width: 250px;
		padding: 5px;
		vertical-align: top;
	}

</style>

<cfquery name="qGetMinAndMaksDepth" dbtype="query">
	SELECT MAX(depth) as maxdepth, MIN(depth) as mindepth
    FROM qEmpFormData
</cfquery>
<cfquery name="qGetAllQuestLibCode" dbtype="query">
	SELECT libcode
    FROM qEmpFormData
    <!--- remark, semua masuk ke evald
    WHERE iscategory = 'N'
    --->
</cfquery>
<!--- bikin variabel untuk lookup dan maks depth--->
<script>
top.$("##objective_lib").val('#valuelist(qGetAllQuestLibCode.libcode)#');

var objLstPersLookup = {};
var sortTRPersKPI = {}
	sortTRPersKPI.maxdepth = parseInt('#qGetMinAndMaksDepth.maxdepth#');
	sortTRPersKPI.mindepth = parseInt('#qGetMinAndMaksDepth.mindepth#');
	sortTRPersKPI.sortThem = function(){
		for(i=sortTRPersKPI.mindepth+1;i<=sortTRPersKPI.maxdepth+1;i++){
			$("tbody[id='tdata'] tr[depth='"+i+"']").each(function(){
				var objParent = $( "tr[libcode='"+$(this).attr("parentcode")+"']" );
				var posParent = $("tbody[id='tdata'] > tr").index( objParent );
				var posItem = $("tbody[id='tdata'] > tr").index( $(this) );
				var objItem = $("tbody[id='tdata'] > tr").eq(posItem).remove();

				oldPC = $(this).attr("parentcode");
				var temp = 0;

				while(!temp){
					if($("tbody[id='tdata'] > tr").eq(posParent+1).attr("parentcode") != oldPC){
						temp = 1;
					}
					else{
						++posParent;
					}
				}
				$("tbody[id='tdata'] > tr").eq(posParent).after(objItem);
			});
		}
	}
</script>

<table border="0" width="100%" id="objectiveform">
	<thead>
		<tr class="colheaderrel header-data">
			<!--- Remarked by Marc
			<th class="header coltitle" colspan="2" >Objective</th>
			<th class="header coltitle" >Target</th>
			<th class="header coltitle" >Achievement</th>
			<th class="header coltitle" >Score (S)</th>
			<th class="header coltitle" >Weight (W)</th>
			<th class="header coltitle" >Weighted Score<br/>(S x W / Total Weight)</th> --->

			<th class="header coltitle" colspan="2" >Objective</th>
			<th class="header coltitle" >Weight (W)</th>
			<th class="header coltitle" >Criteria</th>
			<th class="header coltitle" >Target</th>
			<th class="header coltitle" >Initiative</th>
			<th class="header coltitle" >Schedule Plan</th>
			<th class="header coltitle" >Action Result</th>
			<th class="header coltitle" >Score (S)</th> <!--- Marc : Sebelumnya ini adalah kolom Achievement tapi diganti jadi Score sedangkan kolom score sendiri dihilangkan agar tidak muncul 2 kali penilaian (pilih achievement dan score) --->
			<th class="header coltitle" style="display:none">Score (S)</th>
			<th class="header coltitle" >Weighted Score<br/>(S x W / Total Weight)</th>
			<th class="header coltitle" >Points Criteria</th>

		</tr>
	</thead>
    <tbody id="tdata">
    <!--- <cfdump var='#qEmpFormData#' label='qEmpFormData' expand='yes'>
	Marc@linenumber<cfabort> --->
    <cfif not qEmpFormData.recordcount or len(qEmpFormData.libcode) eq 0>
		<tr>
			<td colspan="12" align="center" class="oddrow" style="font-size:14px;">No Records</td>
		</tr>
    <cfelse>
        <cfif not qGetFromPlan.recordcount and not preview> <!---ENC50216-80177--->
            <tr><td colspan="12" align="center" class="oddrow" style="font-size:14px;">Personal Objective not available yet</td></tr>
        <cfelse> <!---ENC50216-80177--->
			<!--- <cfdump var='#qEmpFormData#' label='qEmpFormData' expand='yes'>
			Marc@linenumber<cfabort> --->
    	    <cfloop query="#qEmpFormData#">
    			<cfif currentrow % 2 eq 1>
    	    		<tr class="evenrow appraisaldata" libcode="#libcode#" parentcode="#pcode#" depth="#depth#">
    			<cfelse>
    	    		<tr class="oddrow appraisaldata" libcode="#libcode#" parentcode="#pcode#" depth="#depth#">
    			</cfif>
    	        <cfif iscategory eq "Y">
        	    	<td colspan="12">
            	    <span class="liblbl">
    				<cfif depth gte 2><cfloop index="idx" from="1" to="#depth-1#">&nbsp;&nbsp;&nbsp;</cfloop></cfif>#libname#</span>
                	</td>
        	    <cfelse>
    				<cfif len(achscoretype) and achscoretype neq "~">
    					<cfset qAchScoreDet = objSFPEV.getScoringDetail(scorecode=achscoretype,varcocode=varcocode)>
    					<cfset achievementtype = achscoretype>

        	        <cfelse>
            	    	<cfset qAchScoreDet = qAchDefScoreDet>
            	    	<cfset achievementtype = qGetScoring.actual_type>

                	</cfif>

            		<td <cfif libname eq ''>style="visibility:hidden;"</cfif>>

                	<span class="liblbl"><cfif depth gte 2><cfloop index="idx" from="1" to="#depth-1#">&nbsp;&nbsp;&nbsp;</cfloop></cfif>
    				<cfset comp = 'PERSKPI' >
    				<!--- <a href="javascript:void(0);" onclick="window.open('?xfid=hrm.performance.evalform.detailobjective&amp;periodcode=#periodcode#&amp;libcode=#libcode#&amp;refdate=#refdate#&amp;achievement_type=#achscoretype#&amp;achievement=#qGetScoring.actual_type#&amp;compcode=#comp#','Detail Objective Personal',400,300);" style="text-decoration:none;" <cfif len(libname) gt 15>title="#libname#"</cfif>><cfif len(libname) lte 15>#libname#<cfelse>#left(libname,13)#...</cfif> #libname#</a></span> --->
    				<textarea class="rotextinput">#libname#</textarea>
					</span>
                    </td>
                    <td nowrap="nowrap" <cfif libname eq ''>style="visibility:hidden;"</cfif>>
    	           	<span class="grpbtnlib">
        	           	<img class="button" src="#Application.PATH.LIB#/images/icons/acssedit.png" height="15px" onclick="javascript:openPersPopUp(this,'popup_persnote_#libcode#',1);" title="note">
    	                <a href="javascript:void(0);" onclick="compareOthersPersLib('#libcode#')" style="text-decoration:none;">
    	                <img src="#Application.PATH.LIB#/images/pm/icon_objcompare.png" height="15px" title="compare with others"/></a>
        	            <img src="#Application.PATH.LIB#/skins/def/images/temp/glasses.png" class	="button" height="15px" onclick="javascript:openPersPopUp(this,'popup_persotherdata_#libcode#',1);" title="other reviewer">
    	            </span>

        	        <div id="popup_persnote_#libcode#" style="background-color:##cfcfcf;z-index:200;position:absolute;overflow:auto;display:none;border:solid black 1px;">
    	               	<table>
        	               	<tr>
            	              	<td>&nbsp;</td>
    							<td align="right"><a class="minus" onClick="closePersPopUp('popup_persnote_#libcode#');" style="position:relative;left:1px;top:2px"><img src="#Application.PATH.LIB#/images/icons/delete.png" alt="[-]" class="button"></a></td>
    		                </tr>

    		                <cfif preview>
    		                    <tr>
                    	           	<td>
        	                        <img src="?sfid=sys.util.getfile&code=empphoto&fname=icon_noemployee.gif" width="40" height="40" style="-moz-border-radius: 20px; border-radius: 20px;" title="Approver">
        							</td>
            	                   	<td>
        		                       <textarea name="pers_note_preview" cols="30" rows="2"></textarea>
    	                            </td>
            	                </tr>
    		                <cfelse>

								<cfquery name="qOthReviewer" datasource="#request.sdsn#">
									SELECT TPMDPERFORMANCE_EVALH.head_status, lib_code libcode, TEOMEMPPERSONAL.full_name, weight, target, lib_name_#request.scookie.lang# libname,
									notes, photo, gender, TPMDPERFORMANCE_EVALD.reviewer_empid,  lib_desc_#request.scookie.lang# libdesc, achievement_type, TGEMSCORE.score_desc
									,TPMDPERFORMANCE_EVALH.review_step,TPMDPERFORMANCE_EVALH.isfinal
									FROM TPMDPERFORMANCE_EVALD
									INNER JOIN TPMDPERFORMANCE_EVALH ON TPMDPERFORMANCE_EVALD.form_no = TPMDPERFORMANCE_EVALH.form_no AND TPMDPERFORMANCE_EVALD.reviewer_empid = TPMDPERFORMANCE_EVALH.reviewer_empid
									INNER JOIN TEOMEMPPERSONAL ON TPMDPERFORMANCE_EVALD.reviewer_empid = TEOMEMPPERSONAL.emp_id
									LEFT JOIN TGEMSCORE ON TGEMSCORE.score_code = TPMDPERFORMANCE_EVALD.achievement_type
									WHERE TPMDPERFORMANCE_EVALD.form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
									AND TPMDPERFORMANCE_EVALD.company_code = <cfqueryparam value="#varcocode#" cfsqltype="cf_sql_varchar">
									AND TPMDPERFORMANCE_EVALD.lib_name_#request.scookie.lang# = <cfqueryparam value="#libname#" cfsqltype="cf_sql_varchar">
									<cfif ListQualify(replacenocase(strckListApproverEvalH.FULLLISTAPPROVER,"|",",","ALL"),"'",",","ALL") neq "">
									AND TPMDPERFORMANCE_EVALD.reviewer_empid in (#ListQualify(replacenocase(strckListApproverEvalH.FULLLISTAPPROVER,"|",",","ALL"),"'",",","ALL")#)
									</cfif>
									AND TPMDPERFORMANCE_EVALH.request_no =  <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
									ORDER BY TPMDPERFORMANCE_EVALH.review_step
								</cfquery>


								<!--- TCK1909-0523930 --->
								<cfset qOthReviewerCek = qOthReviewer>
								<cfquery name="qCekStatusFinal" dbtype="query">
									SELECT * FROM qOthReviewerCek
									WHERE isfinal = 1
								</cfquery>

								<cfif qCekStatusFinal.recordcount eq 0>
									<cfquery name="qOthReviewer" dbtype="query">
										SELECT * FROM qOthReviewerCek
										WHERE review_step <= #strckListApproverEvalH.index#
										ORDER BY review_step
									</cfquery>
								<cfelse>
									<!---<cfset qOthReviewer = qOthReviewerCek >--->
									<cfquery name="qOthReviewer" dbtype="query">
										SELECT * FROM qOthReviewerCek
										WHERE (review_step <= #strckListApproverEvalH.index# OR reviewer_empid = <cfqueryparam value="#qCekStatusFinal.reviewer_empid#" cfsqltype="cf_sql_varchar" > )
										ORDER BY review_step
									</cfquery>

								</cfif>
								<!--- TCK1909-0523930 --->

								<cfif qOthReviewer.recordcount gt 0>
									<cfloop query="#qOthReviewer#">
										<cfset qPrevRInfo = objSFPEV.getEmpDetail(empid=qOthReviewer.reviewer_empid,varcoid=varcoid)>

										<cfif qOthReviewer.reviewer_empid eq emplogin>
										<tr>
											<td>
											<cfif len(qReviewerInfo.empphoto)>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;thumb=1&amp;fname=#qReviewerInfo.empphoto#" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
											<cfelseif qReviewerInfo.empgender>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_noemployee.gif" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
											<cfelse>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_nofemployee.gif" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
											</cfif>
											</td>
											<td>
												<textarea name="pers_note_#libcode#" cols="30" rows="2">#qOthReviewer.notes#</textarea>
											</td>
										</tr>
										<cfelse>
											<cfif qOthReviewer.head_status eq 1>

												<tr>
													<td>
														<img src="?sfid=sys.util.getfile&code=empphoto&fname=#qPrevRInfo.empphoto#" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qPrevRInfo.empname#">
													</td>
													<td>
													   #qOthReviewer.notes#
													</td>
												</tr>

											</cfif>

										</cfif>
									</cfloop>
									<cfif ListFindNoCase(replacenocase(strckListApproverEvalH.FULLLISTAPPROVER,"|",",","ALL"),REQUEST.SCOOKIE.USER.EMPID) gt 0 AND ListFindNoCase(ValueList(qOthReviewer.reviewer_empid),REQUEST.SCOOKIE.USER.EMPID) eq 0>
										<tr>
											<td>
											<cfif len(qReviewerInfo.empphoto)>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;thumb=1&amp;fname=#qReviewerInfo.empphoto#" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
											<cfelseif qReviewerInfo.empgender>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_noemployee.gif" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
											<cfelse>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_nofemployee.gif" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
											</cfif>
											</td>
											<td>
											   <textarea name="pers_note_#libcode#" cols="30" rows="2"></textarea>
											</td>
										</tr>

									</cfif>
								<cfelse>

									<cfif request.scookie.user.empid eq empid>
										<cfset qPrevRInfo = objSFPEV.getEmpDetail(empid=empid,varcoid=varcoid)>
										<tr>
											<td>
											<cfif len(qReviewerInfo.empphoto)>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;thumb=1&amp;fname=#qReviewerInfo.empphoto#" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
											<cfelseif qReviewerInfo.empgender>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_noemployee.gif" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
											<cfelse>
												<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_nofemployee.gif" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
											</cfif>
											</td>
											<td>
												<textarea name="pers_note_#libcode#" cols="30" rows="2"></textarea>
											</td>
										</tr>

									<cfelse>


										 <cfloop list="#ReplaceNoCase(strckListApproverEvalH.FULLLISTAPPROVER,'|',',','ALL')#" index="idxlistapprover">
											<cfset qReviewerInfo = objSFPEV.getEmpDetail(empid=idxlistapprover,varcoid=varcoid)>

											<tr>
												<td>
												<cfif len(qReviewerInfo.empphoto)>
													<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;thumb=1&amp;fname=#qReviewerInfo.empphoto#" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
												<cfelseif qReviewerInfo.empgender>
													<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_noemployee.gif" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
												<cfelse>
													<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_nofemployee.gif" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
												</cfif>
												</td>
												<td>
													<textarea name="pers_note_#libcode#" cols="30" rows="2"></textarea>
												</td>
											</tr>
										</cfloop>




									</cfif>
								</cfif>
            	            </cfif>
                	   </table>
    	            </div>

        	        <div id="popup_persotherdata_#libcode#" style="background-color:##cfcfcf;z-index:201;position:absolute;overflow:auto;display:none;border:solid black 1px;">
            	       	<table>
                	       	<tr>
    							<td colspan="3" align="right"><a class="minus" onClick="closePersPopUp('popup_persotherdata_#libcode#');" style="position:relative;left:1px;top:2px"><img src="#Application.PATH.LIB#/images/icons/delete.png" alt="[-]" class="button"></a></td>
    		                </tr>
        	               	<tr>
    							<td colspan="3" align="center">
    	                        <fieldset>
        	                    	<legend>#libname#</legend>
            	                	<table>
    				                   	<tr class="colheaderrel header-data">
    				                       	<td>Reviewer</td>
    				                       	<td>Achievement</td>
    				                       	<td>Score</td>
    			    	                </tr>

							<cfquery name="qOthReviewer" datasource="#request.sdsn#">
								SELECT TPMDPERFORMANCE_EVALH.head_status, lib_code libcode, TEOMEMPPERSONAL.full_name, TPMDPERFORMANCE_EVALD.score, TPMDPERFORMANCE_EVALD.achievement, lib_name_#request.scookie.lang# libname,
								notes, photo, gender, TPMDPERFORMANCE_EVALD.reviewer_empid,  lib_desc_#request.scookie.lang# libdesc, achievement_type, TGEMSCORE.score_desc
								,TPMDPERFORMANCE_EVALH.review_step,TPMDPERFORMANCE_EVALH.isfinal
								FROM TPMDPERFORMANCE_EVALD
								INNER JOIN TPMDPERFORMANCE_EVALH ON TPMDPERFORMANCE_EVALD.form_no = TPMDPERFORMANCE_EVALH.form_no AND TPMDPERFORMANCE_EVALD.reviewer_empid = TPMDPERFORMANCE_EVALH.reviewer_empid
								INNER JOIN TEOMEMPPERSONAL ON TPMDPERFORMANCE_EVALD.reviewer_empid = TEOMEMPPERSONAL.emp_id
								LEFT JOIN TGEMSCORE ON TGEMSCORE.score_code = TPMDPERFORMANCE_EVALD.achievement_type
								WHERE TPMDPERFORMANCE_EVALD.form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
								AND TPMDPERFORMANCE_EVALD.company_code = <cfqueryparam value="#varcocode#" cfsqltype="cf_sql_varchar">
								AND lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
								<cfif strckListApproverEvalH.FULLLISTAPPROVER neq "">
								AND TPMDPERFORMANCE_EVALD.reviewer_empid in (#ListQualify(replacenocase(strckListApproverEvalH.FULLLISTAPPROVER,"|",",","ALL"),"'",",","ALL")#)
								</cfif>

								AND TPMDPERFORMANCE_EVALH.request_no =  <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
								ORDER BY TPMDPERFORMANCE_EVALH.review_step
							</cfquery>

							<!--- TCK1909-0523930 --->
							<cfset qOthReviewerCek = qOthReviewer>
							<cfquery name="qCekStatusFinal" dbtype="query">
							    SELECT * FROM qOthReviewerCek
							    WHERE isfinal = 1
							</cfquery>

							<cfif qCekStatusFinal.recordcount eq 0>
							    <cfquery name="qOthReviewer" dbtype="query">
							        SELECT * FROM qOthReviewerCek
							        WHERE review_step <= #strckListApproverEvalH.index#
							        ORDER BY review_step
							    </cfquery>
							<cfelse>
							    <cfset qOthReviewer = qOthReviewerCek >
							</cfif>
							<!--- TCK1909-0523930 --->

									<cfif qOthReviewer.recordcount gt 0>
										<cfloop query="#qOthReviewer#">
										<cfset qPrevRInfo = objSFPEV.getEmpDetail(empid=qOthReviewer.reviewer_empid,varcoid=varcoid)>

										<cfif qPrevRInfo.recordcount>
											<cfif qOthReviewer.reviewer_empid neq REQUEST.SCOOKIE.USER.EMPID AND qOthReviewer.head_status eq 1>
											<tr>
												<td align="left">#qPrevRInfo.empname#</td>
												<td align="center">#qOthReviewer.achievement#</td>
												<td align="center">#qOthReviewer.score#</td>
											</tr>
											</cfif>
										</cfif>
										</cfloop>
									<cfelse>
											<tr>
    											<td colspan="3" align="center">-- No Record --</td>
    										</tr>
									</cfif>

    									<cfset Totlist =  listlen(lstPrevReviewer,',')>

    	                            </table>
        	                    </fieldset>
    	                        </td>
    		                </tr>
            	       </table>
                	</div>
    	            </td>

    	            <!--- Weight --->
    	            <td align="center" <cfif libname eq ''>style="visibility:hidden;"</cfif>>
        	        	<input type='text' style="text-align:center;" class='rotextinput' readonly='readonly' maxlength='255' name='pers_weight_#libcode#' id='pers_weight_#libcode#' value='#val(weight)#' size='10'>
            	    </td>

					<!--- Add by Marc : Criteria --->
    	            <td align="center" <cfif libname eq ''>style="visibility:hidden;"</cfif>>
        	        	<textarea class='rotextinput' readonly='readonly' name='criteria_#libcode#' id='criteria_#libcode#' title='#criteria#'>#criteria#</textarea>
    					<!--- <input type='hidden' style="text-align:center;" class='rotextinput' name='criteria_#libcode#' id='criteria_#libcode#' value='#criteria#' title='#criteria#'> --->
            	    </td>

					<!--- target --->
        	    	<td align="center" <cfif libname eq ''>style="visibility:hidden;"</cfif>>
    					<input type='text' style="text-align:center;" class='rotextinput' readonly='readonly' maxlength='255' name='prev_pers_target_#libcode#' id='prev_pers_target_#libcode#' value='#len(target) lte 15 ? target : left(target,15)&'...' #' title='#target#' size='15'>
    					<input type='hidden' style="text-align:center;" class='rotextinput' maxlength='255' name='pers_target_#libcode#' id='pers_target_#libcode#' value='#target#' title='#target#'>
    				</td>

					<!--- Add by Marc : Initiative --->
        	    	<td align="center">
    					<textarea class='rotextinput' readonly='readonly' name='initiative_#libcode#' id='initiative_#libcode#' title='#initiative#'>#initiative#</textarea>
    				</td>

					<!--- Add by Marc : Schedule Plan --->
        	    	<td align="center">
    					<textarea class='rotextinput' readonly='readonly' name='scheduleplan_#libcode#' id='scheduleplan_#libcode#'>#scheduleplan#</textarea>
    				</td>

					<!--- Add by Marc : Action Result --->
        	    	<td align="center">
    					<textarea name='pers_actionresult_#libcode#' id='actionresult_#libcode#'>#actionresult#</textarea>
    				</td>

        	        <!--- achievement --->
    				<td valign="center" <cfif libname eq ''>style="visibility:hidden;"</cfif>>
                	<!--- <cfif len(achscoretype) and achscoretype neq "~">
    					<cfinvoke component="SFPerformanceEvaluation" method="getScoringDetail" scorecode="#achscoretype#" returnVariable="qAchScoreDet"></cfinvoke>
        	        <cfelse>
            	    	<cfset qAchScoreDet = qAchDefScoreDet>
                	</cfif> --->
    	            <cfif not len(achievement) OR achievement eq 0>
    					<cfset valtemp = "">
						<cfif achievement eq 0>
							<cfset valtemp = achievement>
						</cfif>
    					<!--- start : 03 Sept 2015 ENC50915-79511--->

        	            <cfset qAch = objSFPMON.ViewMonitoringAchievement(formno=planformno,libcode=libcode,libtype="PERSKPI")>
    						<cfquery name="qAch2" dbtype="query">
    							select monitoring_achievement,monitoring_notes from qAch where lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
    							order by yearMon,monthMon desc
    						</cfquery>

    					<cfif trim(qAch2.monitoring_achievement) neq "">
    						<cfset valtemp = qAch2.monitoring_achievement>
    					</cfif>
    					<!--- end : 03 Sept 2015 ENC50915-79511--->

    					<!---Auto set lookup untuk achievement ketika belum di set dan ambil dari monitoring--->
    					<script>
    					    setTimeout(function() {
                                $('[id^=pers_achievement_]').each(function(){
                                    var tempKpiId = this.name.replace('pers_achievement_','');
                            		chgPersAch(this,tempKpiId);
                                });
    					    }, 100);
    					</script>
    					<!---Auto set lookup untuk achievement--->
            	    <cfelse>
    	                <cfset valtemp = achievement>
        	        </cfif>

            	    <cfif qAchScoreDet.score_type eq "R">
                	   	<input type="text" maxlength="255" name="pers_achievement_#libcode#" id="pers_achievement_#libcode#" onblur="if(checkRange(this.name,'achievement')==0)return false;chgPersAch(this,'#libcode#')" value="#valtemp#" defaultval="#valtemp#" maxval="#qAchScoreDet.optvalue[2]#" minval="#qAchScoreDet.optvalue[1]#" style="text-align:right" title="Range Value between #qAchScoreDet.optvalue[1]# and #qAchScoreDet.optvalue[2]#"/>
    	            <cfelse>
        	           	<select name="pers_achievement_#libcode#" id="pers_achievement_#libcode#" onchange="chgPersAch(this,'#libcode#')" style="width:150px;">
    	                	<option value="" <cfif not len(valtemp)>selected</cfif>>Not Specified</option>
    		               	<cfloop query="qAchScoreDet">
            	            	<option value="#qAchScoreDet.optvalue#" <cfif val(qAchScoreDet.optvalue) eq val(valtemp)>selected</cfif>>#qAchScoreDet.opttext#</option>
                	        </cfloop>
                    	</select>

    	            </cfif>
    	            <!--- get lookup --->
    	            <cfif len(lookupscoretype)>
    	                <cfset lookuptype = lookupscoretype>
        	        	<cfset tempLookUpJSON = objSFPEV.getJSONForLookUp(lookupcode=lookupscoretype,periodcode=periodcode,varcocode=varcocode)>
            	    	<script>
    						objLstPersLookup['#libcode#']=JSON.parse('#tempLookUpJSON#');
    					</script>
    	            <cfelse>
						<cfquery name="qGetLookUpCode" datasource="#request.sdsn#">
						select lookup_code from TPMDPERIODKPI where kpilib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
						and company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						and position_id = <cfqueryparam value="#qempinfo.posid#" cfsqltype="cf_sql_integer">
						and period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
						and kpi_type = 'PERSONAL'
						</cfquery>
						<cfif qGetLookUpCode.lookup_code neq "">
							<cfset lookuptype = qGetLookUpCode.lookup_code>
							<cfset lookupPerLibrary = objSFPEV.getJSONForLookUp(lookupcode=lookuptype,periodcode=periodcode,varcocode=varcocode)>
							<script>
								objLstPersLookup['#libcode#']=JSON.parse('#lookupPerLibrary#');
							</script>
						<cfelse>
							<script>
								objLstPersLookup['#libcode#']=JSON.parse('#defLookUpJSON#');
							</script>
						</cfif>

        	        </cfif>

                    <input type="hidden" name="pers_achtype_#libcode#" value="#achievementtype#">
    	            <input type="hidden" name="pers_looktype_#libcode#" value="#lookuptype#">

    				</td>

    				<!--- Scoring --->
        	        <td valign="center" style="display:none;">

    	            <cfif not len(score) OR score eq 0>
        	              <cfset valtemp = achievement>
    					<!--- start : 03 Sept 2015 ENC50915-79511--->
        	            <cfset qAch = objSFPMON.ViewMonitoringAchievement(formno=planformno,libcode=libcode,libtype="PERSKPI")>

    						<cfquery name="qAch2" dbtype="query">
    							select monitoring_achievement,monitoring_notes from qAch where lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
    							order by yearMon,monthMon desc
    						</cfquery>

    					<cfif trim(qAch2.monitoring_achievement) neq "">
    						<cfset valtemp = qAch2.monitoring_achievement>
    					</cfif>
    					<!--- end : 03 Sept 2015 ENC50915-79511--->
            	    <cfelse>
    	                <cfset valtemp = score>
        	        </cfif>
            	    <cfif qScoreDet.score_type eq "R">
                		<!---- start : ENC51017-81177 --->
						<input type="text" maxlength="255" name="pers_score_#libcode#" id="pers_score_#libcode#" onblur="if(checkRange(this.name,'score')==0)return false;chgPersScore(this,'#libcode#')" value="#valtemp#" defaultval="#valtemp#" maxval="#qScoreDet.optvalue[2]#" minval="#qScoreDet.optvalue[1]#" style="text-align:right" title="Range Value between #qScoreDet.optvalue[1]# and #qScoreDet.optvalue[2]#"/>
						<!---- end : ENC51017-81177 --->
    	            <cfelse>
        	           	<select name="pers_score_#libcode#" id="pers_score_#libcode#" onchange="chgPersScore(this,'#libcode#',1)" style="width:150px;">
						   	<!--- Add by Marc : bypass scoring pada initiative --->
							<cfif libname eq ''>
    	                		<option value="0" <cfif not len(valtemp)>selected</cfif>>Not Specified</option>
							<cfelse>
    	                		<option value="" <cfif not len(valtemp)>selected</cfif>>Not Specified</option>
							</cfif>
    		               	<cfloop query="qScoreDet">
            	            	<option value="#val(qScoreDet.optvalue)#" <cfif val(qScoreDet.optvalue) eq val(valtemp)>selected</cfif>>#qScoreDet.opttext#</option>
                	        </cfloop>
                    	</select>
    					<!---<input type="hidden" name="pers_score_#libcode#" value="#valtemp#" /> remarked by maghdalenasp 28112015--->
    	            </cfif>
    				</td>

                	<!--- Weighted Score --->
    	            <td align="center" <cfif libname eq ''>style="visibility:hidden;"</cfif>>
        	        	<input type='text' class='rotextinput' readonly='readonly' maxlength='255'  name='pers_weightedscore_#libcode#' id='pers_weightedscore_#libcode#' value='#weightedscore#' size='10'>
        	        	<input type='hidden' class='rotextinput' maxlength='255'  name='hdnpers_weightedscore_#libcode#' id='hdnpers_weightedscore_#libcode#' value='#weightedscore#' size='10'>
            	    </td>

					<!--- Add by Marc : Points Criteria --->
    	            <td align="center" <cfif libname eq ''>style="visibility:hidden;"</cfif>>
        	        	<textarea style="text-align:center;" class='rotextinput' readonly='readonly' name='pointscriteria_#libcode#' id='pointscriteria_#libcode#' >#pointscriteria#</textarea>
        	        	<!--- <input type='hidden' class='rotextinput' maxlength='255'  name='hdnpers_weightedscore_#libcode#' id='hdnpers_weightedscore_#libcode#' value='#weightedscore#' size='10'> --->
            	    </td>

        	    </cfif>
    	        </tr>
    	    </cfloop>
			<!---<cfdump var="#qEmpFormData#">--->
	    </cfif> <!---ENC50216-80177--->
	</cfif>
	</tbody>
    <tbody id="tsummary">
		<tr>
			<td colspan="12" align="center" class="colheaderrel coltitle header-data" style="font-size:12px; font-family:ARIAL,Verdana;">
            <!---<cfif qEmpFormData.recordcount><div style="text-align:left;float:left;"><input type="button" onclick="viewApprRadar()" value="#REQUEST.SFMLANG['ViewChart']#"></div></cfif>--->
			<!---- start : ENC51017-81177 --->
            <cfif varlookupontotal eq 0 OR varlookupontotal eq ''>
				 #REQUEST.SFMLANG['TotalWeightedScore']# : <input type="text" style="font-weight:bold; font-family:ARIAL,Verdana; font-size:10pt; color:##FFF" class="rotextinput" readonly="readonly" maxlength="255"  name="persscore" id="persscore" value="0" size="10"/>
				<div style="text-align:right;float:right;padding-top: 4px;">#REQUEST.SFMLANG['Weight']# : #qGetPersKPIWeight.weight#</div>
			<cfelse>
				#REQUEST.SFMLANG['LookupResult']# : <input type="text" style="font-weight:bold; font-family:ARIAL,Verdana; font-size:10pt; color:##FFF" class="rotextinput" readonly="readonly" maxlength="255"  name="persscore" id="lookupresultpers" value="0" size="10"/>
				<div style="text-align:right;float:right;">
				<table class="header coltitle" >
					<tr>
						<td>#REQUEST.SFMLANG['TotalWeightedScore']#</td>
						<td>:</td>
						<td>
							<input type="text" style="font-weight:bold; font-family:ARIAL,Verdana; font-size:10pt; color:##FFF" class="rotextinput" readonly="readonly" maxlength="255"  name="persscore" id="persscore" value="0" size="10"/>
						</td>
					</tr>
					<tr>
						<td>#REQUEST.SFMLANG['Weight']#</td>
						<td>:</td>
						<td>#qGetPersKPIWeight.weight#</td>
					</tr>
				</table>
				</div>
			</cfif>
           <!---- end : ENC51017-81177 --->
	        </td>
		</tr>
	</tbody>
</table>
<input type="hidden" id="lookuppers_total" value="#varlookupontotal#"> <!---- added by ENC51017-81177 --->
<!---<cfdump var="#qEmpFormData#">--->


<script>
	sortTRPersKPI.sortThem();

	function closePersPopUp(divId) {
		$('##'+divId).hide();
	}

	function openPersPopUp(obj,cbDiv,flagShow) {
		if (flagShow == 1) {
			var arrPos=getElementPos(obj);
			//console.log(arrPos);

			//$('##'+cbDiv).css("top",arrPos[1]+11); --BUG50215-37906--
			$('##'+cbDiv).css("top",$('##formspace').scrollTop()+arrPos[1]+11);
			//$('##'+cbDiv).css("left",arrPos[0]-11);
			$('##'+cbDiv).show();
		}
	}

	function viewPersRadar(){
		var param={sname:[],starget:[],sactual:[]}
		$('##objective-form tr.objectivedata').each(function(pos,el){
			param.sname.push($(el).children()[1].innerHTML)
			param.starget.push($($(el).children()[2]).find('input').val())
			param.sactual.push($($(el).children()[3]).find('select').val())
		})
		var chartURL='?sfid=hrm.performance.evaluation.viewappraisalradar&param='+JSON.stringify(param);
		popWindow(chartURL,null,null,null,'location=no,scrollbars=yes,status=no,toolbar=no,resizable=yes,menubar=no')
	}

	function compareOthersPersLib(libcode){
		var empscore = $('##pers_score_'+libcode).val();
		window.open('?xfid=hrm.performance.evalform.comparison.lib&type=3&empid=#empid#&empscore='+empscore+'&periodcode=#periodcode#&refdate=#refdate#&objCode='+libcode,'Objective Comparison',400,250);
	}

	<!--- fungsi js buat hitung2 --->
	<!--- start : ENC51017-81177 --->
	function getLookUpForTotal(objdata,lookval){
		var returnval = "";
		for (key in objdata.look){
			if(objdata.symbol.toUpperCase() == 'LT'){
				if (parseFloat(lookval) < parseFloat(objdata.look[key])){
					returnval = objdata.return[key];
					break;
				}
			}else if(objdata.symbol.toUpperCase() == 'LTE'){
				if (parseFloat(lookval) <= parseFloat(objdata.look[key])){
					returnval = objdata.return[key];
					break;
				}
			}else if(objdata.symbol.toUpperCase() == 'GT'){
				if (parseFloat(lookval) > parseFloat(objdata.look[key])){
					returnval = objdata.return[key];
					break;
				}
			}else if(objdata.symbol.toUpperCase() == 'GTE'){
				if (parseFloat(lookval) >= parseFloat(objdata.look[key])){
					returnval = objdata.return[key];
					break;
				}
			}else if(objdata.symbol.toUpperCase() == 'EQ'){
				if (parseFloat(lookval) == parseFloat(objdata.look[key])){
					returnval = objdata.return[key];
					break;
				}
			}
		}
		if(returnval == ''){
			returnval = 0;
		}
		return returnval;
	}
	<!--- end : ENC51017-81177 --->

	function chgPersAch(objAch,libcode){
		if(objAch.value.length){
			if(parseInt(document.getElementById('lookuppers_total').value) == 0){ /*added by : ENC51017-81177 */
					$("##pers_score_"+libcode).val(parseFloat(parent.getLookUpReturn(objLstPersLookup[libcode],objAch.value,$('##pers_target_'+libcode).val())));
			}
				//$("##pers_score_"+libcode).val(parent.getLookUpReturn(objLstPersLookup[libcode],objAch.value,$('##pers_target_'+libcode).val()));
			chgPersScore(objAch,libcode,2);
		}else{
		    //<!--- TCK0918-197064 --->
            try {
                if(parseInt(document.getElementById('lookuppers_total').value) == 0){ /*added by : ENC51017-81177 */
    				$("##pers_score_"+libcode).val(parseFloat(parent.getLookUpReturn(objLstPersLookup[libcode],objAch.value,$('##pers_target_'+libcode).val())));
    			}
			    chgPersScore(objAch,libcode,2);
            }
            catch(err) {
                console.log(err.message);
            }
		    //<!--- TCK0918-197064 --->
		}
	}

	function chgPersScore(objSel,libcode,type){
		var totCredit = 0;
		var libWeight = $("##pers_weight_"+libcode).val();
		var persScore = $("##persscore").val();


		$("input[name^='pers_weight_']").each(function(){
			totCredit += parseFloat($(this).val());
		});

		if(type == 2){
			arrObjSel = objSel.id.split('_');
			arrObjSel[1] = "score";
			objSel = $("##"+arrObjSel.join('_'));

		}
		else{
			objSel = $("##"+objSel.id);

		}

		if((objSel.val().length != 0)&&(libWeight != 0)&&(totCredit != 0)){
			persScore = (parseFloat(objSel.val())*parseFloat(libWeight))/parseFloat(totCredit);
		}
		else{
			persScore = 0;
		}



		$("##pers_weightedscore_"+libcode).val(round(persScore,#InitVarCountDeC#));
		$("##hdnpers_weightedscore_"+libcode).val(persScore); /*add : BUG50816-67356*/


		calcPersScore();
	}

	function loadPersScore(){
		$('select[name*="pers_score_"]').each(function(){
			//chgOrgScore(this,this.id.split("_")[2],1); -- BUG51014-26311 --
			chgPersScore(this,$(this).parent().parent().attr("libcode"),1);
		});

	}
	loadPersScore();

	function calcPersScore(){
		var persScore = 0;

		var minPersScore = '#val(qScoreDet.optvalue[1])#';
		if(parseInt(document.getElementById('lookuppers_total').value) != 1){
			var maxPersScore = '#val(qScoreDet.optvalue[qScoreDet.recordcount])#';
		}
		else{
			var maxPersScore = '#val(qTotalLookupScTy.optvalue[qTotalLookupScTy.recordcount])#';
		}

		//var maxPersScore = '#val(qScoreDet.optvalue[qScoreDet.recordcount])#';

		var gaugeNo = 1;

		//$("input[name^='pers_weightedscore_']").each(function(){
		$("input[name^='hdnpers_weightedscore_']").each(function(){
			//console.log($(this).val());
			persScore += parseFloat($(this).val());
		});
		/*--BUG51215-56212--*/
		var cekpersScore = round(persScore,#InitVarCountDeC#);
		cekpersScore = cekpersScore.substr(cekpersScore.length - 2);
		if(cekpersScore == '99'){
		    persScore += 0.01;
		}
		else if(cekpersScore == '01'){
		    persScore -= 0.01;
		}
		/*--BUG51215-56212--*/
		persScore = round(persScore,#InitVarCountDeC#);
		$("##persscore").val(persScore);

		top.$("##objective").val(persScore);
		top.$("##objgaugescore").html(persScore);
		/*start :  ENC51017-81177 */

		/*if(parseInt(document.getElementById('lookup_total').value) == 1){
			top.$("##objgaugescore").html(document.getElementById('lookupresultpers').value);
		}else{
			top.$("##objgaugescore").html(persScore);

		}
		/*end :  ENC51017-81177 */
		//top.calcOverallScore();
		if(parseInt(document.getElementById('lookuppers_total').value) != 1){
			gaugeNo = parseInt(parseFloat(persScore/maxPersScore) * 20);
			if(gaugeNo > maxPersScore){
				gaugeNo = 20;
			}
			if(gaugeNo > 20){
				gaugeNo = 20;
			}
			//console.log(gaugeNo);
			if(gaugeNo == 0) {
				top.$("##objGauge").attr("src","#application.path.lib#/images/charts/kpi/Gauge"+gaugeNo+".png");
			}
			else{
				top.$("##objGauge").attr("src","#application.path.lib#/images/charts/kpi2/Gauge-"+gaugeNo+".png");
			}

			top.$("##objGauge").attr("title",persScore+" out of "+maxPersScore);

		}
		else{
			var totallookup = getLookUpForTotal(JSON.parse('#defLookUpJSON#'),document.getElementById("persscore").value);
			gaugeNo = parseInt(parseFloat(totallookup/maxPersScore)*20);

			/*if(maxPersScore >= 100){
				gaugeNo = parseInt(parseFloat(totallookup/(maxPersScore/10)));
			}
			if(gaugeNo > maxPersScore){
				gaugeNo = maxPersScore;
			}
			if(totallookup > maxPersScore){
				gaugeNo = maxPersScore;
			}
			if(totallookup <= 20 && maxPersScore <= 20){
				gaugeNo = totallookup;
			}*/
			if(gaugeNo == 0) {
				top.$("##objGauge").attr("src","#application.path.lib#/images/charts/kpi/Gauge"+gaugeNo+".png");
			}
			else{
				top.$("##objGauge").attr("src","#application.path.lib#/images/charts/kpi2/Gauge-"+gaugeNo+".png");
			}
			top.$("##objGauge").attr("title",totallookup+" out of "+maxPersScore);
		}

		/*start :  ENC51017-81177 */
		if(parseInt(document.getElementById('lookuppers_total').value) == 1){
			document.getElementById("lookupresultpers").value = getLookUpForTotal(JSON.parse('#defLookUpJSON#'),document.getElementById("persscore").value);
		}
		if(parseInt(document.getElementById('lookuppers_total').value) == 1){
			top.$("##objgaugescore").html(getLookUpForTotal(JSON.parse('#defLookUpJSON#'),document.getElementById("persscore").value));
			var totallookup = getLookUpForTotal(JSON.parse('#defLookUpJSON#'),document.getElementById("persscore").value);
			top.$("##objGauge").attr("title",totallookup+" out of "+maxPersScore);
			top.document.getElementById('objective_totallookupSc').value = totallookup;
			top.document.getElementById('objective_totallookup').value = parseInt(document.getElementById('lookuppers_total').value);
		}else{
			top.$("##objgaugescore").html(persScore);

		}
		top.calcOverallScore();
	}
	calcPersScore();


	function checkRange(objid,typeInput){
		if ((($('input[name="'+objid+'"]').val().length == 0)||(isNaN($('input[name="'+objid+'"]').val()))) && typeInput == 'score') {
			alert('Score value must be a number');
			$('input[name="'+objid+'"]').val($('input[name='+objid+']').attr("defaultval"));
			$('input[name="'+objid+'"]').focus();
			return 0;
		}
		else if ( (parseFloat($('input[name='+objid+']').val()) < parseFloat($('input[name='+objid+']').attr("minval"))) || (parseFloat($('input[name='+objid+']').val()) > parseFloat($('input[name='+objid+']').attr("maxval")))){
			alert('Out of range, set the value between '+$('input[name='+objid+']').attr("minval")+' and '+$('input[name='+objid+']').attr("maxval"));
			$('input[name='+objid+']').val($('input[name='+objid+']').attr("defaultval"));
			return 0;
		}
		else{
			$('input[name='+objid+']').attr("defaultval",$('input[name='+objid+']').val());
			return 1;
		}
	}

	top.$('##objectiveform_loaded').val(1);

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

	/*!
		Start Add By Marc
		autosize 4.0.2
		license: MIT
		http://www.jacklmoore.com/autosize
	*/
	(function (global, factory) {
		if (typeof define === "function" && define.amd) {
			define(['module', 'exports'], factory);
		} else if (typeof exports !== "undefined") {
			factory(module, exports);
		} else {
			var mod = {
				exports: {}
			};
			factory(mod, mod.exports);
			global.autosize = mod.exports;
		}
	})(this, function (module, exports) {
		'use strict';

	var map = typeof Map === "function" ? new Map() : function () {
		var keys = [];
		var values = [];

		return {
			has: function has(key) {
				return keys.indexOf(key) > -1;
			},
			get: function get(key) {
				return values[keys.indexOf(key)];
			},
			set: function set(key, value) {
				if (keys.indexOf(key) === -1) {
					keys.push(key);
					values.push(value);
				}
			},
			delete: function _delete(key) {
				var index = keys.indexOf(key);
				if (index > -1) {
					keys.splice(index, 1);
					values.splice(index, 1);
				}
			}
		};
	}();

	var createEvent = function createEvent(name) {
		return new Event(name, { bubbles: true });
	};
	try {
		new Event('test');
	} catch (e) {
		// IE does not support `new Event()`
		createEvent = function createEvent(name) {
			var evt = document.createEvent('Event');
			evt.initEvent(name, true, false);
			return evt;
		};
	}

	function assign(ta) {
		if (!ta || !ta.nodeName || ta.nodeName !== 'TEXTAREA' || map.has(ta)) return;

		var heightOffset = null;
		var clientWidth = null;
		var cachedHeight = null;

		function init() {
			var style = window.getComputedStyle(ta, null);

			if (style.resize === 'vertical') {
				ta.style.resize = 'none';
			} else if (style.resize === 'both') {
				ta.style.resize = 'horizontal';
			}

			if (style.boxSizing === 'content-box') {
				heightOffset = -(parseFloat(style.paddingTop) + parseFloat(style.paddingBottom));
			} else {
				heightOffset = parseFloat(style.borderTopWidth) + parseFloat(style.borderBottomWidth);
			}
			// Fix when a textarea is not on document body and heightOffset is Not a Number
			if (isNaN(heightOffset)) {
				heightOffset = 0;
			}

			update();
		}

		function changeOverflow(value) {
			{
				// Chrome/Safari-specific fix:
				// When the textarea y-overflow is hidden, Chrome/Safari do not reflow the text to account for the space
				// made available by removing the scrollbar. The following forces the necessary text reflow.
				var width = ta.style.width;
				ta.style.width = '0px';
				// Force reflow:
				/* jshint ignore:start */
				ta.offsetWidth;
				/* jshint ignore:end */
				ta.style.width = width;
			}

			ta.style.overflowY = value;
		}

		function getParentOverflows(el) {
			var arr = [];

			while (el && el.parentNode && el.parentNode instanceof Element) {
				if (el.parentNode.scrollTop) {
					arr.push({
						node: el.parentNode,
						scrollTop: el.parentNode.scrollTop
					});
				}
				el = el.parentNode;
			}

			return arr;
		}

		function resize() {
			if (ta.scrollHeight === 0) {
				// If the scrollHeight is 0, then the element probably has display:none or is detached from the DOM.
				return;
			}

			var overflows = getParentOverflows(ta);
			var docTop = document.documentElement && document.documentElement.scrollTop; // Needed for Mobile IE (ticket ##240)

			ta.style.height = '';
			ta.style.height = ta.scrollHeight + heightOffset + 'px';

			// used to check if an update is actually necessary on window.resize
			clientWidth = ta.clientWidth;

			// prevents scroll-position jumping
			overflows.forEach(function (el) {
				el.node.scrollTop = el.scrollTop;
			});

			if (docTop) {
				document.documentElement.scrollTop = docTop;
			}
		}

		function update() {
			resize();

			var styleHeight = Math.round(parseFloat(ta.style.height));
			var computed = window.getComputedStyle(ta, null);

			// Using offsetHeight as a replacement for computed.height in IE, because IE does not account use of border-box
			var actualHeight = computed.boxSizing === 'content-box' ? Math.round(parseFloat(computed.height)) : ta.offsetHeight;

			// The actual height not matching the style height (set via the resize method) indicates that
			// the max-height has been exceeded, in which case the overflow should be allowed.
			if (actualHeight < styleHeight) {
				if (computed.overflowY === 'hidden') {
					changeOverflow('scroll');
					resize();
					actualHeight = computed.boxSizing === 'content-box' ? Math.round(parseFloat(window.getComputedStyle(ta, null).height)) : ta.offsetHeight;
				}
			} else {
				// Normally keep overflow set to hidden, to avoid flash of scrollbar as the textarea expands.
				if (computed.overflowY !== 'hidden') {
					changeOverflow('hidden');
					resize();
					actualHeight = computed.boxSizing === 'content-box' ? Math.round(parseFloat(window.getComputedStyle(ta, null).height)) : ta.offsetHeight;
				}
			}

			if (cachedHeight !== actualHeight) {
				cachedHeight = actualHeight;
				var evt = createEvent('autosize:resized');
				try {
					ta.dispatchEvent(evt);
				} catch (err) {
					// Firefox will throw an error on dispatchEvent for a detached element
					// https://bugzilla.mozilla.org/show_bug.cgi?id=889376
				}
			}
		}

		var pageResize = function pageResize() {
			if (ta.clientWidth !== clientWidth) {
				update();
			}
		};

		var destroy = function (style) {
			window.removeEventListener('resize', pageResize, false);
			ta.removeEventListener('input', update, false);
			ta.removeEventListener('keyup', update, false);
			ta.removeEventListener('autosize:destroy', destroy, false);
			ta.removeEventListener('autosize:update', update, false);

			Object.keys(style).forEach(function (key) {
				ta.style[key] = style[key];
			});

			map.delete(ta);
		}.bind(ta, {
			height: ta.style.height,
			resize: ta.style.resize,
			overflowY: ta.style.overflowY,
			overflowX: ta.style.overflowX,
			wordWrap: ta.style.wordWrap
		});

		ta.addEventListener('autosize:destroy', destroy, false);

		// IE9 does not fire onpropertychange or oninput for deletions,
		// so binding to onkeyup to catch most of those events.
		// There is no way that I know of to detect something like 'cut' in IE9.
		if ('onpropertychange' in ta && 'oninput' in ta) {
			ta.addEventListener('keyup', update, false);
		}

		window.addEventListener('resize', pageResize, false);
		ta.addEventListener('input', update, false);
		ta.addEventListener('autosize:update', update, false);
		ta.style.overflowX = 'hidden';
		ta.style.wordWrap = 'break-word';

		map.set(ta, {
			destroy: destroy,
			update: update
		});

		init();
	}

	function destroy(ta) {
		var methods = map.get(ta);
		if (methods) {
			methods.destroy();
		}
	}

	function update(ta) {
		var methods = map.get(ta);
		if (methods) {
			methods.update();
		}
	}

	var autosize = null;

	// Do nothing in Node.js environment and IE8 (or lower)
	if (typeof window === 'undefined' || typeof window.getComputedStyle !== 'function') {
		autosize = function autosize(el) {
			return el;
		};
		autosize.destroy = function (el) {
			return el;
		};
		autosize.update = function (el) {
			return el;
		};
	} else {
		autosize = function autosize(el, options) {
			if (el) {
				Array.prototype.forEach.call(el.length ? el : [el], function (x) {
					return assign(x, options);
				});
			}
			return el;
		};
		autosize.destroy = function (el) {
			if (el) {
				Array.prototype.forEach.call(el.length ? el : [el], destroy);
			}
			return el;
		};
		autosize.update = function (el) {
			if (el) {
				Array.prototype.forEach.call(el.length ? el : [el], update);
			}
			return el;
		};
	}

	exports.default = autosize;
	module.exports = exports['default'];
	});

	autosize(document.querySelectorAll('textarea'));
	// End Add By Marc
</script>

<script>
    try { top.checkIsAllTabLoaded("PERSKPI"); } catch(err) { }
</script>
</cfoutput>





























