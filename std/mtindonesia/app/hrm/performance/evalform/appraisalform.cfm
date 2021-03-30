<cfsetting showdebugoutput="Yes" enablecfoutputonly="Yes">
<cfparam name="isajax" default="No">

<cfparam name="reqno" default="">
<cfparam name="formno" default="">
<cfparam name="empid" default="">
<cfparam name="periodcode" default="">
<cfparam name="refdate" default="">
<cfparam name="posid" default="">
<cfparam name="varcoid" default="#REQUEST.SCOOKIE.COID#">
<cfparam name="varcocode" default="#request.scookie.cocode#">

<cfparam name="preview" default="false">
<!--- list preview reviewer--->
<cfparam name="lpr" default="">
<!--- last reviewer --->
<cfparam name="lastrevby" default="">
<cfset FORMMLANG="Appraisal|Target|Score|Weight|Weighted Score|Lookup Result|Total Weight|No Records|Reviewer|Achievement|Not Specified|View Chart|Total Weighted Score">
<cfset REQUEST.SFMLANG=Application.SFParser.TransMLang(listAppend("No|",(isdefined("FORMMLANG")?FORMMLANG:"")))>
<cfset achievementtype = "">
<cfset lookuptype = "">
<cfset LstPrevReviewer = lpr>
<cfset emplogin = request.scookie.user.empid>
<cfset objSFPEV = createobject("component","SFPerformanceEvaluation")>
<!--- ambil data info si reviewee (sementara)--->
<cfset qEmpInfo = objSFPEV.getEmpDetail(empid=empid,varcoid=varcoid)>
<!--- ambil data info si reviewer --->
<cfset qReviewerInfo = objSFPEV.getEmpDetail(empid=request.scookie.user.empid,varcoid=varcoid)>

<!---TCK0818-81809--->
<cfset strckListApproverEvalH = objSFPEV.GetApproverList(empid=empid,reqno=reqno,emplogin=request.scookie.user.empid,varcoid=varcoid,varcocode=varcocode)>
<!---TCK0818-81809--->


<!---TCK2002-0548467--->
<cfset VarNumFormatConf = request.config.NUMERIC_FORMAT>
<cfset VargetDecimalAfter = ListLast(VarNumFormatConf,'.')>
<cfset InitVarCountDeC = LEN(VargetDecimalAfter)>
<!---TCK2002-0548467--->


<!--- ambil data form reviewee (baik sudah direquest ataupun tidak) --->
<!--- <cfset qEmpFormData = objSFPEV.getEmpFormData(empid=empid,periodcode=periodcode,reqno=reqno,formno=formno,refdate=refdate,compcode="APPRAISAL",reviewerempid=request.scookie.user.empid,lastreviewer=lastrevby,varcoid=varcoid,varcocode=varcocode)> --->
<!---TCK0818-81809--->
<cfif strckListApproverEvalH.STATUS EQ 4 AND strckListApproverEvalH.INDEX GTE strckListApproverEvalH.REVISE_POS_ATSTEP> <!--- Status revise dan step approver login >= revise step --->
	<cfset qEmpFormData = objSFPEV.getEmpFormData(empid=empid,periodcode=periodcode,reqno=reqno,formno=formno,refdate=refdate,compcode="APPRAISAL",reviewerempid=strckListApproverEvalH.LASTAPPROVER,lastreviewer=lastrevby,varcoid=varcoid,varcocode=varcocode)>
<cfelse>
	<cfset qEmpFormData = objSFPEV.getEmpFormData(empid=empid,periodcode=periodcode,reqno=reqno,formno=formno,refdate=refdate,compcode="APPRAISAL",reviewerempid=request.scookie.user.empid,lastreviewer=lastrevby,varcoid=varcoid,varcocode=varcocode)>
</cfif>
<!---TCK0818-81809--->
<!--- <cfdump var='#qEmpFormData#' label='qEmpFormData' expand='yes'>
Marc@linenumber<cfabort> --->
<cfset qGetApprWeight = objSFPEV.getPeriodCompData(periodcode=periodcode,refdate=refdate,compcode="APPRAISAL",posid=qEmpInfo.posid)>
<cfset varlookupontotal =val(qGetApprWeight.lookup_total)>
<cfset qGetScoring = objSFPEV.getActualAndScoreType(periodcode=periodcode,compcode="APPRAISAL",varcocode=varcocode)>
<!--- ambil default ach score type--->
<cfif not len(qGetScoring.actual_type)><CF_SFABORT></cfif>
<cfset qAchDefScoreDet = objSFPEV.getScoringDetail(scorecode=qGetScoring.actual_type,varcocode=varcocode)>
<!--- ambil score type--->

<cfset qPeriodData = objSFPEV.getPeriodData(periodcode=periodcode,refdate=refdate,varcocode=varcocode)>
<cfset qTotalLookupScTy = objSFPEV.getScoringDetail(scorecode=qPeriodData.score_type,varcocode=varcocode)>

<cfset qScoreDet = objSFPEV.getScoringDetail(scorecode=qGetScoring.score_type,varcocode=varcocode)>
<!--- JSON Default Look Up for APPRAISAL component (Default) --->
<cfset defLookUpJSON = objSFPEV.getJSONForLookUp(lookupcode=qGetScoring.lookup_code,periodcode=periodcode,varcocode=varcocode)>
<cfoutput>
<style>
	.rotextinput{
		border:none; background-color:transparent; text-align:center;
	}
	.coltitle{
		font-size:12px; padding:5px; color:white;
		text-align:center;
	}
	.grpbtnlib{
		float:right;
	}
</style>
<cfquery name="qGetMinAndMaksDepth" dbtype="query">
	SELECT MAX(depth) as maxdepth, MIN(depth) as mindepth
    FROM qEmpFormData
</cfquery>
<cfquery name="qGetAllQuestLibCode" dbtype="query">
	SELECT libcode
    FROM qEmpFormData
    <!--- remark, karena yang Y disimpan juga di eval
    WHERE iscategory = 'N'
    --->
</cfquery>

<script>
top.$("##appraisal_lib").val('#valuelist(qGetAllQuestLibCode.libcode)#');

var objLstApprLookup = {};
var sortTRAppraisal = {}
	sortTRAppraisal.maxdepth = parseInt('#qGetMinAndMaksDepth.maxdepth#');
	sortTRAppraisal.mindepth = parseInt('#qGetMinAndMaksDepth.mindepth#');
	sortTRAppraisal.sortThem = function(){
		for(i=sortTRAppraisal.mindepth+1;i<=sortTRAppraisal.maxdepth+1;i++){
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

<table border="0" width="100%" id="appraisalform">

	<thead>
		<tr class="colheaderrel header-data">
			<th class="header coltitle" colspan="2" >#REQUEST.SFMLANG['Appraisal']#</th>
			<th class="header coltitle" >#REQUEST.SFMLANG['Target']#</th>
			<th class="header coltitle" style="display:none">#REQUEST.SFMLANG['Achievement']#</th>
			<th class="header coltitle" >#REQUEST.SFMLANG['Score']# (S)</th>
			<th class="header coltitle" >#REQUEST.SFMLANG['Weight']# (W)</th>
			<th class="header coltitle" >#REQUEST.SFMLANG['WeightedScore']#<br/>(S x W / #REQUEST.SFMLANG['TotalWeight']#)</th>
		</tr>
	</thead>
    <tbody id="tdata">
    <cfif val(qEmpFormData.recordcount) eq 0>
		<tr>
			<td colspan="7" align="center" class="oddrow" style="font-size:14px;">#REQUEST.SFMLANG['NoRecords']#</td>
		</tr>
    <cfelse>
		
	    <cfloop query="#qEmpFormData#">
	        <cfset libcode = qEmpFormData.libcode>

			<!--- for get achievement type --->
			<cfif currentrow % 2 eq 1>
	    		<tr class="evenrow <cfif iscategory eq "N">appraisaldata</cfif>" libcode="#libcode#" parentcode="#pcode#" depth="#depth#" <cfif negative_component eq 'Y'>style="background-color:pink"</cfif>>
			<cfelse>
	    		<tr class="oddrow <cfif iscategory eq "N">appraisaldata</cfif>" libcode="#libcode#" parentcode="#pcode#" depth="#depth#" <cfif negative_component eq 'Y'>style="background-color:pink"</cfif>>
			</cfif>
	        <cfif UCASE(iscategory) eq "Y">
    	    	<td colspan="7">
        	    <span class="liblbl"><cfloop index="idx" from="1" to="#depth-1#">&nbsp;&nbsp;&nbsp;</cfloop>#HTMLEDITFORMAT(libname)#</span>
            	</td>
    	    <cfelse>
        		<td nowrap="nowrap" <cfif len(libname) gt 47>title="#HTMLEDITFORMAT(libname)#"</cfif>>
				<cfif len(achscoretype) and achscoretype neq "~">
					<cfset qAchScoreDet = objSFPEV.getScoringDetail(scorecode=achscoretype,varcocode=varcocode)>
					<cfset achievementtype = achscoretype>
    	        <cfelse>
        	    	<cfset qAchScoreDet = qAchDefScoreDet>
        	    	<cfset achievementtype = qGetScoring.actual_type>
            	</cfif>
            	<span class="liblbl"><cfloop index="idx" from="1" to="#depth-1#">&nbsp;&nbsp;&nbsp;</cfloop>
				<a href="javascript:void(0);" onclick="window.open('?xfid=hrm.performance.evalform.detailappraisal&amp;periodcode=#periodcode#&amp;libcode=#libcode#&amp;refdate=#refdate#&amp;achievement_type=#achscoretype#&amp;achievement=#qGetScoring.actual_type#','Detail Appraisal',400,300);" style="text-decoration:none;">
				<!--- Remarked by Marc
				<cfif len(libname) lte 22>#HTMLEDITFORMAT(libname)# <cfelse>#HTMLEDITFORMAT(left(libname,20))#...</cfif> --->
				#HTMLEDITFORMAT(libname)#
				</a></span>
                </td>
                <td nowrap="nowrap">
	           	<span class="grpbtnlib">
    	           	<img class="button" src="#Application.PATH.LIB#/images/icons/acssedit.png" height="15px" onclick="javascript:openApprPopUp(this,'popup_apprnote_#libcode#',1);" title="note">
	                <a href="javascript:void(0);" onclick="compareOthersApprLib('#libcode#')" style="text-decoration:none;">
	                <img src="#Application.PATH.LIB#/images/pm/icon_objcompare.png" height="15px" title="compare with others"/></a>
    	            <img src="#Application.PATH.LIB#/skins/def/images/temp/glasses.png" class="button" height="15px" onclick="javascript:openApprPopUp(this,'popup_approtherdata_#libcode#',1);" title="other reviewer">
	            </span>
    	        <div id="popup_apprnote_#libcode#" style="background-color:##cfcfcf;z-index:200;position:absolute;overflow:auto;display:none;border:solid black 1px;">
	               	<table>
    	               	<tr>
        	              	<td>&nbsp;</td>
							<td align="right"><a class="minus" onClick="closeApprPopUp('popup_apprnote_#libcode#');" style="position:relative;left:1px;top:2px"><img src="#Application.PATH.LIB#/images/icons/delete.png" alt="[-]" class="button"></a></td>
		                </tr>

		                <cfif preview>
		                    <tr>
                	           	<td>
    	                        <img src="?sfid=sys.util.getfile&code=empphoto&fname=icon_noemployee.gif" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="Approver">
    							</td>
        	                   	<td>
    		                       <textarea name="appr_note_preview" cols="30" rows="2"></textarea>
	                            </td>
        	                </tr>
		                <cfelse>

                        <!---start new lst notes--->
		                <cfquery name="qGetDataEvalD" datasource="#request.sdsn#">
            				SELECT a.form_no, a.reviewer_empid, a.lib_code, a.company_code, a.notes, a.achievement, a.score, b.head_status
            				,b.review_step,b.isfinal
            				FROM TPMDPERFORMANCE_EVALD a LEFT JOIN TPMDPERFORMANCE_EVALH b
            				ON a.form_no = b.form_no AND a.reviewer_empid = b.reviewer_empid
            				WHERE  a.form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
            				AND a.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
            				AND a.lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
            				AND b.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
            				AND UPPER(a.lib_type) = UPPER('appraisal')
							<cfif strckListApproverEvalH.FULLLISTAPPROVER neq "">
							    AND a.reviewer_empid in (#ListQualify(replacenocase(strckListApproverEvalH.FULLLISTAPPROVER,"|",",","ALL"),"'",",","ALL")#)
							</cfif>
							ORDER BY b.review_step
            			</cfquery>

            			<!---Get status final--->
            			<cfset qOthReviewerApprCek = qGetDataEvalD>
						<cfquery name="qCekStatusFinal" dbtype="query">
							SELECT * FROM qGetDataEvalD
							WHERE isfinal = 1
						</cfquery>
						<cfif qCekStatusFinal.recordcount eq 0>
							<cfquery name="qGetDataEvalD" dbtype="query">
								SELECT * FROM qOthReviewerApprCek
								WHERE review_step <= #strckListApproverEvalH.index#
								ORDER BY review_step
							</cfquery>
						<cfelse>
							<cfquery name="qGetDataEvalD" dbtype="query">
								SELECT * FROM qOthReviewerApprCek
								WHERE (review_step <= #strckListApproverEvalH.index# OR reviewer_empid = <cfqueryparam value="#qCekStatusFinal.reviewer_empid#" cfsqltype="cf_sql_varchar" > )
								ORDER BY review_step
							</cfquery>
						</cfif>
            			<!---Get status final--->
                        <!---end new lst notes--->

                        <cfif qGetDataEvalD.recordcount eq 0 OR (qGetDataEvalD.recordCount gt 0 AND ListfindNoCase( valuelist(qGetDataEvalD.reviewer_empid),emplogin ) eq 0 )>
                            <cfset temp = QueryAddRow(qGetDataEvalD)>
                            <cfset QuerySetCell(qGetDataEvalD, "form_no",'#formno#')>
                            <cfset QuerySetCell(qGetDataEvalD, "reviewer_empid",'#emplogin#')>
                            <cfset QuerySetCell(qGetDataEvalD, "lib_code",'#libcode#')>
                            <cfset QuerySetCell(qGetDataEvalD, "company_code",'#varcocode#')>
                            <cfset QuerySetCell(qGetDataEvalD, "notes",'')>
                            <cfset QuerySetCell(qGetDataEvalD, "achievement",'')>
                            <cfset QuerySetCell(qGetDataEvalD, "score",'0')>
                            <cfset QuerySetCell(qGetDataEvalD, "head_status",'')>
                            <cfset QuerySetCell(qGetDataEvalD, "review_step",'#strckListApproverEvalH.index#')>
                            <cfset QuerySetCell(qGetDataEvalD, "isfinal",0)>
                        </cfif>

						<!---<cfloop list="#lstPrevReviewer#" index="idxPrevR">--->
						<cfloop query="qGetDataEvalD">
						    <cfset idxPrevR = qGetDataEvalD.reviewer_empid >
    						<cfset qPrevRInfo = objSFPEV.getEmpDetail(empid=idxPrevR,varcoid=varcoid)>
    						<!---<cfset qGetDataEvalD = objSFPEV.GetDataEvalD(empid=idxPrevR,periodcode=periodcode,formno=formno,compcode="APPRAISAL",refdate=refdate,libcode=libcode,reviewerempid=LstPrevReviewer,varcocode=varcocode)>--->

            	           	<cfif idxPrevR eq emplogin>
    						<tr>
            	               	<td>
            	            	<cfif len(qReviewerInfo.empphoto)>
					        	    <img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;thumb=1&amp;fname=#qReviewerInfo.empphoto#" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qReviewerInfo.EmpName#">
					            <cfelseif qReviewerInfo.empgender>
				        	    	<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_noemployee.gif" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#HTMLEDITFORMAT(qReviewerInfo.EmpName)#">
					            <cfelse>
				    	        	<img src="?sfid=sys.util.getfile&amp;code=empphoto&amp;fname=icon_nofemployee.gif" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#HTMLEDITFORMAT(qReviewerInfo.EmpName)#">
					            </cfif>
    	                        </td>
    	                       	<td>
            	                    <textarea name="appr_note_#libcode#" cols="30" rows="2">#HTMLEDITFORMAT(qGetDataEvalD.notes)#</textarea>
            	                </td>
    	                    </tr>
    						<cfelse>
    						<tr>
                	           	<td>
    	                        <img src="?sfid=sys.util.getfile&code=empphoto&fname=#qPrevRInfo.empphoto#" width="40" height="40" style="-moz-border-radius: 20px;border-radius: 20px;" title="#qPrevRInfo.empname#">
    							</td>
        	                   	<td>
    		                       #HTMLEDITFORMAT(qGetDataEvalD.notes)#
	                            </td>
        	                </tr>
    						</cfif>
        	            </cfloop>
    	                </cfif>
            	   </table>
	            </div>
    	        <div id="popup_approtherdata_#libcode#" style="background-color:##cfcfcf;z-index:201;position:absolute;overflow:auto;display:none;border:solid black 1px;">
        	       	<table>
            	       	<tr>
							<td colspan="3" align="right"><a class="minus" onClick="closeApprPopUp('popup_approtherdata_#libcode#');" style="position:relative;left:1px;top:2px"><img src="#Application.PATH.LIB#/images/icons/delete.png" alt="[-]" class="button"></a></td>
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

			        	          <!----  <cfloop list="#lstPrevReviewer#" index="idxPrevR">
									<cfset qPrevRInfo = objSFPEV.getEmpDetail(empid=idxPrevR,varcoid=varcoid)>
            						<cfset qGetDataEvalD = objSFPEV.GetDataEvalD(empid=idxPrevR,periodcode=periodcode,formno=formno,compcode="APPRAISAL",refdate=refdate,libcode=qEmpFormData.libcode,reviewerempid=LstPrevReviewer,varcocode=varcocode)>

									<cfif qPrevRInfo.recordcount>
										<cfif qPrevRInfo.empid eq emplogin>
											<cfbreak>
										<cfelseif qPrevRInfo.empid neq emplogin>
										<tr>
											<td align="left">#HTMLEDITFORMAT(qPrevRInfo.empname)#</td>
											<td align="center">#qGetDataEvalD.achievement#</td>
											<td align="center">#qGetDataEvalD.score#</td>
										</tr>
										</cfif>
									</cfif>
			    	                </cfloop>
									----->



									<cfquery name="qOthReviewer" datasource="#request.sdsn#">
										SELECT TPMDPERFORMANCE_EVALH.head_status, lib_code libcode, TEOMEMPPERSONAL.full_name, weight, target, lib_name_#request.scookie.lang# libname,
										notes, photo, gender, TPMDPERFORMANCE_EVALD.reviewer_empid,  lib_desc_#request.scookie.lang# libdesc, achievement_type, TGEMSCORE.score_desc , TPMDPERFORMANCE_EVALD.achievement, TPMDPERFORMANCE_EVALD.score
										,TPMDPERFORMANCE_EVALH.isfinal,TPMDPERFORMANCE_EVALH.review_step
										FROM TPMDPERFORMANCE_EVALD
										INNER JOIN TPMDPERFORMANCE_EVALH ON TPMDPERFORMANCE_EVALD.form_no = TPMDPERFORMANCE_EVALH.form_no AND TPMDPERFORMANCE_EVALD.reviewer_empid = TPMDPERFORMANCE_EVALH.reviewer_empid
										INNER JOIN TEOMEMPPERSONAL ON TPMDPERFORMANCE_EVALD.reviewer_empid = TEOMEMPPERSONAL.emp_id
										LEFT JOIN TGEMSCORE ON TGEMSCORE.score_code = TPMDPERFORMANCE_EVALD.achievement_type
										WHERE TPMDPERFORMANCE_EVALD.form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
										AND TPMDPERFORMANCE_EVALD.company_code = <cfqueryparam value="#varcocode#" cfsqltype="cf_sql_varchar">
										AND lib_code = <cfqueryparam value="#qEmpFormData.libcode#" cfsqltype="cf_sql_varchar">
										AND UPPER(lib_type) = 'APPRAISAL'
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
        							    <cfset qOthReviewer = qOthReviewerCek >
        							</cfif>
        							<!--- TCK1909-0523930 --->

			        	            <cfloop query="qOthReviewer" >
										<cfif qOthReviewer.reviewer_empid neq request.scookie.user.empid>
											<cfset qPrevRInfo = objSFPEV.getEmpDetail(empid=qOthReviewer.reviewer_empid,varcoid=varcoid)>
											<tr>
												<td align="left">#qPrevRInfo.empname#</td>
												<td align="center">#qOthReviewer.achievement#</td>
												<td align="center">#qOthReviewer.score#</td>
											</tr>
										</cfif>
			    	                </cfloop>

									<cfset Totlist =  listlen(lstPrevReviewer,',')>
									<cfif qOthReviewer.recordcount eq 0>
										<tr>
											<td colspan="3" align="center">-- #REQUEST.SFMLANG['NoRecords']# --</td>
										</tr>
									</cfif>

	                            </table>
    	                    </fieldset>
	                        </td>
		                </tr>
        	       </table>
            	</div>
	            </td>

	            <!--- target --->
    	    	<td align="center">
                	<!--- evaluation ga bisa editable --->
                    <!---
					<input type='text' style="text-align:center;" <cfif targetedit eq "N">class='rotextinput' readonly='readonly'</cfif> maxlength='255' name='appr_target_#libcode#' id='appr_target_#libcode#' value='#target#' size='10'>
					--->
					<input type='text' style="text-align:center;" class='rotextinput' readonly='readonly' maxlength='255' name='appr_target_#libcode#' id='appr_target_#libcode#' value='#target#' size='10'>
				</td>

    	        <!--- achievement --->
				<td valign="center" style="display:none">
            	<!--- <cfif len(achscoretype) and achscoretype neq "~">
					<cfinvoke component="SFPerformanceEvaluation" method="getScoringDetail" scorecode="#achscoretype#" returnVariable="qAchScoreDet"></cfinvoke>
    	        <cfelse>
        	    	<cfset qAchScoreDet = qAchDefScoreDet>
            	</cfif>  --->
	            <cfif not len(achievement)>
    	            <cfset valtemp = "">
        	    <cfelse>
	                <cfset valtemp = achievement>
    	        </cfif>

        	    <cfif qAchScoreDet.score_type eq "R">
            	   	<input type="text" maxlength="255" name="appr_achievement_#libcode#" id="appr_achievement_#libcode#" onblur="if(checkRange(this.name)==0)return false;chgApprAch(this,'#libcode#')" value="#valtemp#" defaultval="#valtemp#" maxval="#qAchScoreDet.optvalue[2]#" minval="#qAchScoreDet.optvalue[1]#" style="text-align:right" title="Range Value between #qAchScoreDet.optvalue[1]# and #qAchScoreDet.optvalue[2]#"/>
	            <cfelse>
    	           	<select name="appr_achievement_#libcode#" id="appr_achievement_#libcode#" onchange="chgApprAch(this,'#libcode#')" style="width:150px;">
	                	<option value="0" <cfif not len(valtemp)>selected</cfif>>#REQUEST.SFMLANG['NotSpecified']#</option>
		               	<cfloop query="qAchScoreDet">
        	            	<option value="#val(qAchScoreDet.optvalue)#" <cfif qAchScoreDet.optvalue eq valtemp>selected</cfif>>#qAchScoreDet.opttext#</option>
            	        </cfloop>
                	</select>
	            </cfif>

	            <!--- get lookup --->
	            <cfif len(lookupscoretype)>

    	        	<cfset lookuptype = lookupscoretype>
					<cfset tempLookUpJSON = objSFPEV.getJSONForLookUp(lookupcode=lookupscoretype,periodcode=periodcode,varcocode=varcocode)>
        	    	<script>
						objLstApprLookup['#libcode#']=JSON.parse('#tempLookUpJSON#');
					</script>
	            <cfelse>
    	            <cfset lookuptype = qGetScoring.lookup_code>
    	        	<script>
						objLstApprLookup['#libcode#']=JSON.parse('#defLookUpJSON#');
					</script>
    	        </cfif>

	            <input type="hidden" name="appr_achtype_#libcode#" value="#achievementtype#">
	            <input type="hidden" name="appr_looktype_#libcode#" value="#lookuptype#">

				</td>

				<!--- Scoring --->
    	        <td valign="center">
	            <cfif not len(score)>
    	            <cfset valtemp = "">
        	    <cfelse>
	                <cfset valtemp = score>
    	        </cfif>


        	    <cfif qScoreDet.score_type eq "R">
						<!---- start : ENC51017-81177 --->
						<input type="text" maxlength="255" name="appr_score_#libcode#" id="appr_score_#libcode#" onblur="if(checkRange(this.name)==0)return false;chgApprScore(this,'#libcode#')" value="#valtemp#" defaultval="#valtemp#" maxval="#qScoreDet.optvalue[2]#" minval="#qScoreDet.optvalue[1]#" style="text-align:right" title="Range Value between #qScoreDet.optvalue[1]# and #qScoreDet.optvalue[2]#"/>
						<!---- end : ENC51017-81177 --->
	            <cfelse>
    	           	<select name="appr_score_#libcode#" id="appr_score_#libcode#" 
					 	<!--- Add by marc --->
					   	<cfif negative_component eq 'Y'>
					    	onchange="chgApprScore(this,'#libcode#',3)" 
						<cfelse>
					    	onchange="chgApprScore(this,'#libcode#',1)" 
						</cfif>  	
					style="width:150px;">
	                	<option value="" <cfif not len(valtemp)>selected</cfif>>#REQUEST.SFMLANG['NotSpecified']#</option>
						
						<!--- Add by marc --->
						<cfif negative_component eq 'Y'>
							<option value="0">[0] 0</option>
						</cfif>

		               	<cfloop query="qScoreDet">
						   	<!--- Add by Marc --->
						   	<!--- <cfif negative_component eq 'Y'>
							   <option value="#val(qScoreDet.optvalue*-1)#" <cfif (qScoreDet.optvalue*-1) eq valtemp>selected</cfif>>#qScoreDet.opttext#</option>
						   	<cfelse> --->
        	            		<option value="#val(qScoreDet.optvalue)#" <cfif qScoreDet.optvalue eq valtemp>selected</cfif>>#qScoreDet.opttext#</option>
						   	<!--- </cfif> --->
            	        </cfloop>
                	</select>
	            </cfif>
				</td>

        	    <!--- Weight --->
	            <td align="center">
                	<!--- evaluation ga bisa editable --->
                    <!---
    	        	<input type='text' style="text-align:center;" <cfif weightedit eq "N">class='rotextinput' readonly='readonly'</cfif> maxlength='255'  name='appr_weight_#libcode#' id='appr_weight_#libcode#' value='#weight#' size='10'>
					--->
					<!--- Add by Marc --->
					<cfif negative_component eq 'Y'>
	    	        	<input type='text' style="text-align:center;" class='rotextinput' readonly='readonly' maxlength='255'  name='appr_weight_#libcode#' id='appr_weight_#libcode#' value='-#weight#' size='10'>
					<cfelse>
    	        		<input type='text' style="text-align:center;" class='rotextinput' readonly='readonly' maxlength='255'  name='appr_weight_#libcode#' id='appr_weight_#libcode#' value='#weight#' size='10'>
					</cfif>
        	    </td>

            	<!--- Weighted Score --->
	            <td align="center">
    	        	<input type='text' class='rotextinput' readonly='readonly' maxlength='255'  name='appr_weightedscore_#libcode#' id='appr_weightedscore_#libcode#' value='#weightedscore#' size='10'>
    	        	<input type='hidden' class='rotextinput' maxlength='255'  name='hdnappr_weightedscore_#libcode#' id='hdnappr_weightedscore_#libcode#' value='#weightedscore#' size='10'>
        	    </td>
	        </tr></cfif>

	    </cfloop>
	</cfif>
	</tbody>

    <tbody id="tsummary">
		<tr>
			<td colspan="7" align="center" class="colheaderrel coltitle header-data" style="font-size:12px; font-family:ARIAL,Verdana;">
            <cfif qEmpFormData.recordcount><div style="text-align:left;float:left;"><input type="button" onclick="viewApprRadar()" value="#REQUEST.SFMLANG['ViewChart']#"></div></cfif>
			<!---- start : ENC51017-81177 --->
            <cfif varlookupontotal eq 0>
				 #REQUEST.SFMLANG['TotalWeightedScore']# : <input type="text" style="font-weight:bold; font-family:ARIAL,Verdana; font-size:10pt; color:##FFF" class="rotextinput" readonly="readonly" maxlength="255"  name="appscore" id="appscore" value="0" size="10"/>
				<div style="text-align:right;float:right;padding-top: 4px;">#REQUEST.SFMLANG['Weight']# : #qGetApprWeight.weight#</div>
			<cfelse>
				 #REQUEST.SFMLANG['LookupResult']# : <input type="text" style="font-weight:bold; font-family:ARIAL,Verdana; font-size:10pt; color:##FFF" class="rotextinput" readonly="readonly" maxlength="255"  name="appscore" id="lookupresultapp" value="0" size="10"/>
				<div style="text-align:right;float:right;">
					<table class="header coltitle" >
						<tr>
							<td>
							#REQUEST.SFMLANG['TotalWeightedScore']#
							</td>
							<td>
							:
							</td>
							<td>
							<input type="text" style="font-weight:bold; font-family:ARIAL,Verdana; font-size:10pt; color:##FFF" class="rotextinput" readonly="readonly" maxlength="255"  name="appscore_totalweighted" id="appscore" value="0" size="10"/>
							</td>
						</tr>
						<tr>
							<td>#REQUEST.SFMLANG['Weight']#</td>
							<td>:</td>
							<td>#val(qGetApprWeight.weight)# </td>
						</tr>
					</table>
				</div>
			</cfif>
			<!---- end : ENC51017-81177 --->
	        </td>
		</tr>
	</tbody>
</table>

<input type="hidden" id="lookup_total" value="#varlookupontotal#"> <!---- added by ENC51017-81177 --->
<script>
	sortTRAppraisal.sortThem();
	function closeApprPopUp(divId) {
		$('##'+divId).hide();
	}

	function openApprPopUp(obj,cbDiv,flagShow) {
		if (flagShow == 1) {
			var arrPos=getElementPos(obj);
			//console.log(arrPos);
			//$('##'+cbDiv).css("top",arrPos[1]+11); --BUG50215-37906--
			$('##'+cbDiv).css("top",$('##formspace').scrollTop()+arrPos[1]+11);
			//$('##'+cbDiv).css("left",arrPos[0]-11);
			$('##'+cbDiv).show();
		}
	}

	function viewApprRadar(){
		var param={sname:[],starget:[],sactual:[]};
		$('##appraisalform tr.appraisaldata').each(function(pos,el){
				thesname = $(el).children().eq(0).text();
				thesname = thesname.replace(/\n/g,'');
				thesname = thesname.replace(/\t/g,'').trim();
				thesname = thesname.replace(/</g, "&lt;").replace(/>/g, "&gt;");
				thesname = encodeURIComponent(thesname);
				param.sname.push(thesname);
				if ($($(el).children()[2]).find('input').val() != null){
					param.starget.push($($(el).children()[2]).find('input').val())
				}else{
					param.starget.push(0)
				}
				if ($($(el).children()[3]).find('select').val() != null){
					param.sactual.push($($(el).children()[3]).find('select').val())
				}else if($($(el).children()[3]).find('input').val() != null && $($(el).children()[3]).find('input').val() != ''){
					param.sactual.push($($(el).children()[3]).find('input').val())
				}else{
					param.sactual.push(0)
				}
		})
		//console.log(param);
		//console.log(JSON.stringify(param));

		var chartURL='?sfid=hrm.performance.evalform.viewradar&param='+JSON.stringify(param);
		popWindow(chartURL,null,null,null,'location=no,scrollbars=yes,status=no,toolbar=no,resizable=yes,menubar=no');
	}

	function compareOthersApprLib(libcode){
		var empscore = $('##appr_score_'+libcode).val();
		window.open('?xfid=hrm.performance.evalform.comparison.lib&type=1&empid=#empid#&refdate=#refdate#&empscore='+empscore+'&periodcode=#periodcode#&objCode='+libcode,'Objective Comparison',400,250);
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
	function chgApprAch(objAch,libcode){
		if(objAch.value.length){
			if(parseInt(document.getElementById('lookup_total').value) == 0){ /*added by : ENC51017-81177 */
					$("##appr_score_"+libcode).val(parent.getLookUpReturn(objLstApprLookup[libcode],objAch.value,$('##appr_target_'+libcode).val()));
			}
		    chgApprScore(objAch,libcode,2);  /*untuk hitung weighted score*/
		}else{
		    //<!--- TCK0918-197064 --->
            try {
    			if(parseInt(document.getElementById('lookup_total').value) == 0){ /*added by : ENC51017-81177 */
    					$("##appr_score_"+libcode).val(parent.getLookUpReturn(objLstApprLookup[libcode],objAch.value,$('##appr_target_'+libcode).val()));
    			}
    		    chgApprScore(objAch,libcode,2);  /*untuk hitung weighted score*/
            }
            catch(err) {
                console.log(err.message);
            }
		    //<!--- TCK0918-197064 --->
		}
	}

	function chgApprScore(objSel,libcode,type){
		var totCredit = 0;
		var totDeduct = 0;
		var libWeight = $("##appr_weight_"+libcode).val();
		var apprScore = document.getElementById("appscore").value;
		$("input[name^='appr_weight_']").each(function(){
			if($(this).val() > 0){
				totCredit += parseFloat($(this).val());
			}else{
				totDeduct += parseFloat($(this).val());
			}
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
			apprScore = (parseFloat(objSel.val())*parseFloat(libWeight))/parseFloat(totCredit);
		}
		else{
			apprScore = 0;
		}

		$("##hdnappr_weightedscore_"+libcode).val(round(apprScore,5)); /*add : BUG50816-67356*/
		// Remark by Marc : pembulatan hanya 2 angka dibelakang koma
		// $("##appr_weightedscore_"+libcode).val(round(apprScore,#InitVarCountDeC#));
		$("##appr_weightedscore_"+libcode).val(round(apprScore,5));
		console.log(totCredit);
		calcApprScore();

	}

	function calcApprScore(){
		var apprScore = 0;
		// var deductpoint = 0;

		var minApprScore = '#val(qScoreDet.optvalue[1])#';
		if(parseInt(document.getElementById('lookup_total').value) != 1){
			var maxApprScore = '#val(qScoreDet.optvalue[qScoreDet.recordcount])#';
		}
		else{
			var maxApprScore = '#val(qTotalLookupScTy.optvalue[qTotalLookupScTy.recordcount])#';
		}

		var gaugeNo = 0;

		//$("input[name^='appr_weightedscore_']").each(function(){
		$("input[name^='hdnappr_weightedscore_']").each(function(){
			console.log($(this).val());

			//add by Marc
			//if($(this).val() > 0){
				apprScore += parseFloat($(this).val());
			// }else{
			// 	deductpoint += parseFloat($(this).val());
			// }
			
		});

		
		//var cekapprScore = round(apprScore,#InitVarCountDeC#);
		var cekapprScore = round(apprScore,5);

		cekapprScore = cekapprScore.substr(cekapprScore.length - 2);
		if(cekapprScore == '99'){
		    apprScore += 0.01;
		}
		else if(cekapprScore == '01'){
		    apprScore -= 0.01;
		}
		/*--BUG51215-56212--*/
		// apprScore = round(apprScore,#InitVarCountDeC#);
		apprScore = round(apprScore,5);
		document.getElementById("appscore").value = apprScore

		top.$("##appraisal").val(apprScore);
		/*start :  ENC51017-81177 */
		/*if(parseInt(document.getElementById('lookup_total').value) == 1){
			top.$("##apprgaugescore").html(document.getElementById('lookupresultapp').value);
		}else{
			top.$("##apprgaugescore").html(apprScore);

		}*/
		//top.calcOverallScore();
		if(parseInt(document.getElementById('lookup_total').value) != 1){
			gaugeNo = parseInt(parseFloat((apprScore-minApprScore)/(maxApprScore-minApprScore)) * 20);
			if(gaugeNo > maxApprScore){
				gaugeNo = 20;
			}
			if(gaugeNo > 20){
				gaugeNo = 20;
			}
			if(gaugeNo <= 0) {
				gaugeNo = 0;
				top.$("##apprGauge").attr("src","#application.path.lib#/images/charts/kpi/Gauge"+gaugeNo+".png");
			}
			else{
				top.$("##apprGauge").attr("src","#application.path.lib#/images/charts/kpi2/Gauge-"+gaugeNo+".png");
			}

			top.$("##apprGauge").attr("title",apprScore+" out of "+maxApprScore);

		}
		else{
			var totallookup = getLookUpForTotal(JSON.parse('#defLookUpJSON#'),document.getElementById("appscore").value);
			gaugeNo = parseInt(parseFloat((totallookup-minApprScore)/(maxApprScore-minApprScore)) * 20);
			//gaugeNo = parseInt(parseFloat((totallookup/maxApprScore)*10));
			/*if(maxApprScore >= 100){
				gaugeNo = parseInt(parseFloat(totallookup/(maxApprScore/10)));
			}

			if(gaugeNo > maxApprScore){
				gaugeNo = maxApprScore;
			}
			if(totallookup > maxApprScore){
				gaugeNo = maxApprScore;
			}
			if(totallookup <= 20 && maxApprScore <= 20){
				gaugeNo = totallookup;
			}*/

			if(gaugeNo <= 0) {
				gaugeNo = 0;
				top.$("##apprGauge").attr("src","#application.path.lib#/images/charts/kpi/Gauge"+gaugeNo+".png");
			}
			else{
				top.$("##apprGauge").attr("src","#application.path.lib#/images/charts/kpi2/Gauge-"+gaugeNo+".png");
			}

			top.$("##apprGauge").attr("title",totallookup+" out of "+maxApprScore);
		}

		if(parseInt(document.getElementById('lookup_total').value) == 1){
			document.getElementById("lookupresultapp").value = getLookUpForTotal(JSON.parse('#defLookUpJSON#'),document.getElementById("appscore").value);
		}
		if(parseInt(document.getElementById('lookup_total').value) == 1){
			top.$("##apprgaugescore").html(document.getElementById('lookupresultapp').value);
			var totallookup = document.getElementById('lookupresultapp').value;
			top.$("##apprGauge").attr("title",totallookup+" out of "+maxApprScore);
			top.document.getElementById('appraisal_totallookupSc').value = totallookup;
			top.document.getElementById('appraisal_totallookup').value = parseInt(document.getElementById('lookup_total').value);
		}else{
			top.$("##apprgaugescore").html(apprScore);

		}

		/*end :  ENC51017-81177 */
		//top.calcOverallScore(); janganlupa
	}
	calcApprScore();


	function checkRange(objid){
		// if (($('input[name="'+objid+'"]').val().length == 0)||(isNaN($('input[name="'+objid+'"]').val()))){
		/*--BUG51117-85207--*/
	    if (isNaN($('input[name="'+objid+'"]').val())){
			alert('Score value must be a number');
			$('input[name="'+objid+'"]').val($('input[name='+objid+']').attr("defaultval"));
			$('input[name="'+objid+'"]').focus();
			return 0;
		}
		else if ( (parseFloat($('input[name='+objid+']').val()) < parseFloat($('input[name='+objid+']').attr("minval"))) || (parseFloat($('input[name='+objid+']').val()) > parseFloat($('input[name='+objid+']').attr("maxval")))){
			alert('out of range, set the value between '+$('input[name='+objid+']').attr("minval")+' and '+$('input[name='+objid+']').attr("maxval"));
			$('input[name='+objid+']').val($('input[name='+objid+']').attr("defaultval"));
			return 0;
		}
		else{
			$('input[name='+objid+']').attr("defaultval",$('input[name='+objid+']').val());
			return 1;
		}
	}

	top.$('##appraisalform_loaded').val(1);


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
<script>
    try { top.checkIsAllTabLoaded("APPRAISAL"); } catch(err) { }
</script>
</cfoutput>













