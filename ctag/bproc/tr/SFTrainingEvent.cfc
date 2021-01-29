<cfcomponent displayname="SFTrainingEvent" hint="SunFish Training Event Business Process Object" extends="sfcomp.bproc.tr.SFTrainingEvent"> 
	<cfset Init("TR","TrainingEvent","TTRDTRAINEVENT","Training Event","trnevent_code,company_code","trnevent_code,company_code","trnevent_code,company_code,trnevent_startdate,trnevent_enddate,trnevent_topic,trnevent_type")>
	

	<cffunction name="filterdelivmethod">
		<!---muadz filter deliv method--->
		<cfparam name="search" default="">
		<cfparam name="nrow" default="0">
		<cfparam name="REQUEST.KeyFields" default="">

		<cfif val(nrow) eq "0">
			<cfset nrow="100">
		</cfif>

		<cfset LOCAL.searchText=trim(search)>
		<cfset LOCAL.vResult="">
		<cfset LOCAL.arrValue = ArrayNew(1)>
		<cfset LOCAL.arrParam = ArrayNew(1)>

		<cfsavecontent variable="LOCAL.sqlAllCourse">
			<cfoutput>
			    SELECT tctmdelivmethod.code, tctmdelivmethod.name_#REQUEST.SCOOKIE.LANG# name 
			    FROM tctmdelivmethod
			    WHERE (tctmdelivmethod.code LIKE ?
					<cfset ArrayAppend(arrValue, ["%" & searchText & "%", "CF_SQL_VARCHAR"])>
					<cfset arrParam[ArrayLen(arrParam)+1]="%#searchText#%">
					OR
					tctmdelivmethod.name_#REQUEST.SCOOKIE.LANG# LIKE ?
					<cfset ArrayAppend(arrValue, ["%" & searchText & "%", "CF_SQL_VARCHAR"])>
					<cfset arrParam[ArrayLen(arrParam)+1]="%#searchText#%">
					)
				ORDER BY name ASC
			</cfoutput>
		</cfsavecontent>

		<cfset LOCAL.bResult = Application.SFDB.RunQuery(sqlAllCourse, arrValue)>

		<cfif bResult.QueryResult>
			<cfset LOCAL.qData = bResult.QueryRecords>
			<cfset LOCAL.vSQL = bResult.QueryStruck>
		</cfif>

		<cfloop query="LOCAL.qData">
			<cfset vResult=vResult & "arrEntryList[#currentrow-1#]=""#JSStringFormat(code & "=" & "[#code#]"&" "&"#name#")#"";">
		</cfloop>

		<cfoutput>
			<script>
				arrEntryList=new Array();
				<cfif len(vResult)>
					#vResult#
				</cfif>
			</script>
		</cfoutput>
	</cffunction>

	<cffunction name="SaveAll">
  	    <cfparam name="tabrowhide" default="">
		<!--- Start Training Event Info --->
		<cfparam name="trnevent_code" default="">
		<cfparam name="company_code" default="#REQUEST.Scookie.COCODE#">
		<cfparam name="trnevent_bckground" default="">
		<cfparam name="trnevent_obj" default="">
		<cfparam name="trnevent_target" default="">
		<cfparam name="trnevent_remark" default="">
		<cfparam name="trnevent_attachment" default="">
		<cfparam name="hdn_trnevent_attachment" default="">
		<!--- Muadz nambahin yang buat diinsert --->
		<cfparam name="seldelivmethod" default="">
		<cfparam name="evalmethod" default="">
		<cfparam name="acceptcriteria" default="">
		<cfparam name="material" default="">
		<!--- Muadz nambahin yang buat diinsert --->
		<!---<cfdump  var="#hdnSelectedinp_delivmethod#"> --->
		<!--- End Training Event Info --->

		<!--- Start Training Event Param --->
		<cfparam name="hdn_trncourse_code" default="">
		<cfparam name="trnevent_topic" default="">
		<cfparam name="hdn_nametype" default="">
		<cfparam name="nametype" default="">
		<cfparam name="trnevent_startdate" default="">
		<cfparam name="trnevent_enddate" default="">
		<cfparam name="trnevent_sts" default="">
		<cfparam name="sel_cost_type" default="0">
		<!--- End Training Event Param --->
		
		<!--- Start Trianing Event Venue --->
		<cfparam name="venue_code" default="">
		<cfparam name="hdn_venue_code" default="">
		<cfparam name="trnevent_address" default="">
		<cfparam name="room_code" default="">
		<cfparam name="hdn_room_code" default="">
		<cfparam name="hdn_provider_code" default="">
		<!--- End Trianing Event Venue --->
		
		<!--- Start Training Event Agenda --->
		<cfparam name="SDrowtot" default="1">
		<cfparam name="hdn_type" default="">
		<cfparam name="hdn_idx" default="1">
		<cfparam name="hdn_idx2" default="1">
		<cfparam name="hdn_idx3" default="1">
		<!--- End Training Event Agenda --->
		
		<!--- Start Training Event Participant --->
		<cfparam name="member" default="">
		<cfparam name="hdnSelectedgroup_emp" default="">
		<cfparam name="listempselect" default="">
		<cfparam name="listemp" default="">
		<cfparam name="trnevent_capacity" default="0">
		<cfparam name="emp" default="N">
		<!--- End Training Event Participant --->
			
		<!--- Start Training Event ESS --->
		<cfparam name="trnevent_enablereq" default="N">
		<cfparam name="trnevent_lastregdate" default="">
		<cfparam name="trnevent_enablecontent" default="N">
		<cfparam name="trnevent_enableallcontent" default="N">
		<cfparam name="totcoursecontent" default="0">
		<cfparam name="totchecked" default="0">
		<cfparam name="trnevent_contentstartdate" default="">
		<cfparam name="trnevent_contentenddate" default="">
		<cfparam name="trnevent_enabletest" default="N">
		<cfparam name="trnevent_enablefeedback" default="N">
		<cfparam name="trnevent_feedbackduedate" default="">
		<cfparam name="trnevent_enableeval" default="N">
		<cfparam name="esssel" default="">
		<cfparam name="statnew" default="">
		<cfparam name="idxit" default="">
		<cfset local.retVarESS = true>
		<cfset local.retVarEssStage = true>
		<cfset local.retVarInfo = true>
		<cfset LOCAL.retvarParticipant = true>
		<cfset LOCAL.retvarVenue = true>
		<cfset LOCAL.retvarAgenda = true>
		<cfset local.retvarOther = true>
		<cfset local.retvarCost = true>
		<cfset local.retDebug = "aaa">
		
		<cfif ucase(trnevent_enablecontent) eq 'Y' AND val(totcoursecontent) eq val(totchecked)>
		    <cfset trnevent_enableallcontent = 'Y'>
		</cfif>
		
		<cfif isDate(trnevent_startdate)>
			<cfset local.trnevent_lastregdate = DateAdd("d",6,trnevent_startdate)>
			<cfset local.trnevent_lastregdate = '#DateFormat(trnevent_lastregdate,"yyyy-mm-dd")#'>
		</cfif>
		<cfset local.trnevent_contentstartdate = '#DateFormat(trnevent_contentstartdate,"yyyy-mm-dd")#'>
		<cfset local.trnevent_contentenddate = '#DateFormat(trnevent_contentenddate,"yyyy-mm-dd")#'>
		<cfset local.trnevent_feedbackduedate = '#DateFormat(trnevent_feedbackduedate,"yyyy-mm-dd")#'>
		<cftry> 
			<cfif esssel eq 0 >
				<cfquery name="local.qInsEss" datasource="#REQUEST.SDSN#">
					INSERT INTO TTRRTRAINEVENTESS(trnevent_code,company_code,trnevent_enablereq,
					<cfif trnevent_lastregdate neq "">trnevent_lastregdate,</cfif>
					trnevent_enablecontent,trnevent_contentstartdate,trnevent_contentenddate,trnevent_enabletest,trnevent_enablefeedback,trnevent_feedbackduedate,trnevent_enableeval,trnevent_enableallcontent)
					VALUES(
						<cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> ,
						<cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR"> ,
						<cfqueryparam value="#trnevent_enablereq#" cfsqltype="CF_SQL_VARCHAR"> ,
						<cfif trnevent_lastregdate neq "">'#trnevent_lastregdate#',</cfif>
						<cfqueryparam value="#trnevent_enablecontent#" cfsqltype="CF_SQL_VARCHAR"> ,
						'#trnevent_contentstartdate#',
						'#trnevent_contentenddate#',
						<cfqueryparam value="#trnevent_enabletest#" cfsqltype="CF_SQL_VARCHAR"> ,
						<cfqueryparam value="#trnevent_enablefeedback#" cfsqltype="CF_SQL_VARCHAR"> ,
						'#trnevent_feedbackduedate#',
						<cfqueryparam value="#trnevent_enableeval#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#trnevent_enableallcontent#" cfsqltype="CF_SQL_VARCHAR"> 
					)
				</cfquery>
			<cfelse>
				<cfquery name="local.qInsEss" datasource="#REQUEST.SDSN#">
					UPDATE TTRRTRAINEVENTESS
					SET 
					trnevent_enablereq = <cfqueryparam value="#trnevent_enablereq#" cfsqltype="CF_SQL_VARCHAR"> ,
					<cfif trnevent_lastregdate neq "">trnevent_lastregdate = '#trnevent_lastregdate#',</cfif>
					trnevent_enablecontent =<cfqueryparam value="#trnevent_enablecontent#" cfsqltype="CF_SQL_VARCHAR"> ,
					trnevent_contentstartdate = '#trnevent_contentstartdate#',
					trnevent_contentenddate = '#trnevent_contentenddate#',
					trnevent_enabletest =<cfqueryparam value="#trnevent_enabletest#" cfsqltype="CF_SQL_VARCHAR"> ,
					trnevent_enablefeedback =<cfqueryparam value="#trnevent_enablefeedback#" cfsqltype="CF_SQL_VARCHAR"> ,
					trnevent_feedbackduedate = '#trnevent_feedbackduedate#',
					trnevent_enableeval =<cfqueryparam value="#trnevent_enableeval#" cfsqltype="CF_SQL_VARCHAR">,
					trnevent_enableallcontent = <cfqueryparam value="#trnevent_enableallcontent#" cfsqltype="CF_SQL_VARCHAR"> 
					WHERE company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR"> 
					AND trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">
				</cfquery>
			</cfif>
			<cfcatch>
				<cfset local.retVarESS = false>
			</cfcatch>
		</cftry> 
		
		<cftry>
		    <!--- Hapus semua data detail traincontentevent --->
	        <cfquery name="qDelEventContent" datasource="#request.sdsn#">
		        DELETE FROM TTRRTRAINEVENTCONTENT
		        WHERE company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR"> 
				AND trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>
		    <cfif trnevent_enableallcontent eq 'N'>
		        <cfparam name="totcoursecontent" default="1">
		        <cfloop index="cnt" from="1" to="#totcoursecontent#">
		            <cfparam name="content_#cnt#" default="">
		            <cfset local.trncontentcode = #Evaluate("content_#cnt#")# />
		            <cfif trncontentcode neq ''>
		            	<cfquery name="qInsEventContent" datasource="#REQUEST.SDSN#">
    		                INSERT INTO TTRRTRAINEVENTCONTENT
    		                (trnevent_code, trncontent_code, company_code)
    		                VALUES
    		                (<cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">, 
    		                '#trncontentcode#',
    		                <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
    		                )
		                </cfquery>
		            </cfif>

		        </cfloop>
		    <cfelse> <!--- All Enabled Content --->
		        <cfquery name="qSelCourseContent" datasource="#REQUEST.SDSN#">
                    SELECT trncontent_code
                    from TTRRTRAINCOURSECONTENT 
                    where trncourse_code = <cfqueryparam value="#hdn_trncourse_code#" cfsqltype="cf_sql_varchar"> 
                    and company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
                    and trncontent_status = 'Y'
                </cfquery>
                
                <cfloop query="qSelCourseContent">
                    <cfquery name="qInsEventContent" datasource="#REQUEST.SDSN#">
		                INSERT INTO TTRRTRAINEVENTCONTENT
		                (trnevent_code, trncontent_code, company_code)
		                VALUES
		                (<cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">, 
		                '#qSelCourseContent.trncontent_code#',
		                <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
		                )
	                </cfquery>
                </cfloop>
                
		    </cfif>
		    <cfcatch>
				<cfset local.retVarESSContent = false>
			</cfcatch>
		</cftry>
		
		<cftry>
				<cfif idxit gt 0>
					<cfset local.idxi = idxit-1>
				</cfif>
				<cfset local.idxi_ = idxi>
				<cfif trnevent_enableeval eq 'Y'>
					<cfquery name="local.qEssStage" datasource="#REQUEST.SDSN#">
						SELECT trncourse_code FROM TTRRTRAINEVENTESSSTAGE AS a
						WHERE a.company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
						AND a.trncourse_code = <cfqueryparam value="#hdn_trncourse_code#" cfsqltype="CF_SQL_VARCHAR">
						AND a.trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">
					</cfquery>
					<cfset local.jumessstage = val(qEssStage.recordcount)>
					<cfset local.idxa = "">
					<cfloop index="idxa" from="1" to="#idxi_#">
						<!---<cfparam name="trnstagestart_#idxa#" default="">
						<cfparam name="trnstageend_#idxa#" default="">--->
						<cfparam name="trnstage_code#idxa#" default="">
						<cfset local.trnstagecode = #Evaluate("trnstage_code#idxa#")# />
						<cfset local.trnstageend = #Evaluate("trnstageend_#idxa#")# />
						<cfset local.trnstagestart = #Evaluate("trnstagestart_#idxa#")# />
						
						<cfset trnstagestart = '#DateTimeFormat(trnstagestart,"yyyy-mm-dd HH:nn:ss")#'>
						<cfset trnstageend = '#DateTimeFormat(trnstageend,"yyyy-mm-dd HH:nn:ss")#'>
						
						<cfif val(qEssStage.recordcount) eq 0>
							<cfquery name="local.qInsEssStage" datasource="#REQUEST.SDSN#">
									INSERT INTO TTRRTRAINEVENTESSSTAGE 
										(trnstage_code,company_code,trncourse_code,trnevent_code,trnstageval_startdate,trnstageval_enddate)
										VALUES(
										<cfqueryparam value="#trnstagecode#" cfsqltype="CF_SQL_VARCHAR">,
										<cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">,
										<cfqueryparam value="#hdn_trncourse_code#" cfsqltype="CF_SQL_VARCHAR">,
										<cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">,
										'#trnstagestart#',
										'#trnstageend#'
										)
							</cfquery>
						<cfelse>
							<cfif len(trnstagecode)>
								<cfquery name="local.qDelEssStage" datasource="#REQUEST.SDSN#">
									DELETE FROM TTRRTRAINEVENTESSSTAGE
									WHERE trnstage_code = <cfqueryparam value="#trnstagecode#" cfsqltype="CF_SQL_VARCHAR">
									AND company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
									AND trncourse_code = <cfqueryparam value="#hdn_trncourse_code#" cfsqltype="CF_SQL_VARCHAR">
									AND trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
								</cfquery>
								<cfquery name="local.qInsEssStage" datasource="#REQUEST.SDSN#">
									INSERT INTO TTRRTRAINEVENTESSSTAGE 
										(trnstage_code,company_code,trncourse_code,trnevent_code,trnstageval_startdate,trnstageval_enddate)
										VALUES(
										<cfqueryparam value="#trnstagecode#" cfsqltype="CF_SQL_VARCHAR">,
										<cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">,
										<cfqueryparam value="#hdn_trncourse_code#" cfsqltype="CF_SQL_VARCHAR">,
										<cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">,
										'#trnstagestart#',
										'#trnstageend#'
										)
								</cfquery>
							</cfif>
						</cfif>
					</cfloop>
				</cfif>
			<cfcatch>
				<cfset local.retVarEssStage = false>
			</cfcatch>
		</cftry>
		

		<!--- End Training Event ESS --->
		
		<!--- Start Training Event Other --->
		<cfparam name="trnevent_enablecertified" default="N">
		<cfparam name="trnevent_validcertified" default="">
		<cfparam name="trnevent_agreement" default="N">
		<cfparam name="trnevent_validagreement" default="">
		
		    <!--- ENC TCK2008-0582823--->
		    <cfparam name="print_certificate" default="N">
		    <cfparam name="Printcertificate_startdate" default="">
		    <cfparam name="Printcertificate_enddate" default="">
		    <cfparam name="once_print" default="N">
		
		<!--- End Training Event Other --->
		
		<!--- Start Training Event Other --->
		<cfparam name="hdn_row_item" default="">
		<!--- End Training Event Other --->
		
		<!--- Start Training Event Cost --->
		<cfparam name="hdn_row_item" default="">
		<cfparam name="currency_list" default="">
		<cfparam name="costcenter_list" default="">
		<!--- End Training Event Cost --->
		
		<cfset LOCAL.objEventInfo= CreateObject("component", "SFTrainingEventInfo") />
		<!--- Muadz nambahin yang buat dimasukin di struct --->
		<cfset LOCAL.retVarInfo=objEventInfo.SaveInfo(trnevent_code,company_code,trnevent_bckground,trnevent_obj,trnevent_target,trnevent_remark,trnevent_attachment,hdn_trnevent_attachment,hdn_trncourse_code,trnevent_topic,nametype,trnevent_startdate,trnevent_enddate,trnevent_sts,hdn_provider_code,sel_cost_type,seldelivmethod,evalmethod,acceptcriteria,material)>
        <cfif listfindnocase(tabrowhide,"vistab_4",",")> 
		    <cfset LOCAL.objEventParticipant= CreateObject("component", "SFTrainingEventParticipant") />
		    <cfset LOCAL.retvarParticipant=objEventParticipant.SaveParticipant(trnevent_code,company_code,hdnSelectedgroup_emp,listemp,trnevent_capacity,emp,trnevent_startdate,trnevent_enddate,hdn_type,hdn_idx,hdn_idx2,hdn_idx3)>
		</cfif> 
		
		<cfset LOCAL.objEventVenue= CreateObject("component", "SFTrainingEventVenue") />
		<cfset LOCAL.retvarVenue=objEventVenue.SaveVenue(trnevent_code,company_code,venue_code,hdn_venue_code,trnevent_address,room_code,hdn_room_code,hdn_provider_code)>
	
		<cftry>
    		<cfif listfindnocase(tabrowhide,"vistab_3",",") OR listfindnocase(tabrowhide,"vistab_4",",")>
    		    <cfset LOCAL.objEventAgenda= CreateObject("component", "SFTrainingEventAgenda") />
    		    <cfset LOCAL.retvarAgenda=objEventAgenda.SaveAgenda(trnevent_code,company_code,SDrowtot,hdn_type,hdn_idx,hdn_idx2,hdn_idx3,listempselect)>
    		</cfif>
    	<cfcatch>
    	    <cfdump var="#cfcatch#">
    	</cfcatch>
		</cftry>
		
		<!---<cfset LOCAL.objEventESS= CreateObject("component", "SFTrainingEventESS") />
		<cfset LOCAL.retvarESS=objEventESS.SaveESS(trnevent_code,company_code,trnevent_enablereq,trnevent_lastregdate,trnevent_enablecontent,trnevent_contentstartdate,trnevent_contentenddate,trnevent_enabletest,trnevent_enablefeedback,trnevent_feedbackduedate,trnevent_enableeval,trnevent_evalduedate)>--->
	
        
		<cfset LOCAL.objEventOther= CreateObject("component", "SFTrainingEventOther") />
		<cfset LOCAL.retvarOther=objEventOther.SaveOther(trnevent_code,company_code,trnevent_enablecertified,trnevent_validcertified,trnevent_agreement,trnevent_validagreement)>
        
        <cfif listfindnocase(tabrowhide,"vistab_7",",")>
		    <cfset LOCAL.objEventCost= CreateObject("component", "SFTrainingEventCost") />
		    <cfset LOCAL.retvarCost=objEventCost.SaveCost(trnevent_code,company_code,hdn_row_item,currency_list,costcenter_list)>
		</cfif>
		<!---<cfif  val(trnevent_sts) eq 4> --->
			<!---<cfquery name="local.qSelectStage" datasource="#REQUEST.SDSN#">
				SELECT EVTESSSTAGE.trnevent_code,EVTESSSTAGE.trncourse_code, EVTESSSTAGE.trnstage_code,
				TRAINSTAGE.trnstage_pic FROM TTRRTRAINEVENTESSSTAGE EVTESSSTAGE JOIN TTRRTRAINSTAGE TRAINSTAGE
				ON EVTESSSTAGE.trnstage_code = TRAINSTAGE.trnstage_code
				where EVTESSSTAGE.trncourse_code = <cfqueryparam value="#hdn_trncourse_code#" cfsqltype="CF_SQL_VARCHAR">
				and EVTESSSTAGE.company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">

			</cfquery>
			
			<cfquery name="local.qCleanupPICStage" datasource="#REQUEST.SDSN#">
				delete from TTRRMEMBERPICSTAGE where trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>
			<cfloop query="qSelectStage">
				<cfset local.idxemp = "">

				<cfloop list="#listempselect#" index="idxemp">
					<cfset local.listAllPIC = getTrainingEvalPIC(emp_id=idxemp,trnstage_code=qSelectStage.trnstage_code,trncourse_code=qSelectStage.trncourse_code,trnevent_code=qSelectStage.trnevent_code)>

					<cfif listAllPIC neq "">
							
							<cfquery name="local.qInsEmpPIC" datasource="#REQUEST.SDSN#">
								INSERT INTO TTRRMEMBERPICSTAGE (trnevent_code, trnstage_code, trncourse_code, emp_id, pictype, list_pic)
								VALUES (
								<cfqueryparam value="#qSelectStage.trnevent_code#" cfsqltype="CF_SQL_VARCHAR">,
								<cfqueryparam value="#qSelectStage.trnstage_code#" cfsqltype="CF_SQL_VARCHAR">,
								<cfqueryparam value="#qSelectStage.trncourse_code#" cfsqltype="CF_SQL_VARCHAR">,
								<cfqueryparam value="#idxemp#" cfsqltype="CF_SQL_VARCHAR">,
								<cfqueryparam value="#qSelectStage.trnstage_pic#" cfsqltype="CF_SQL_VARCHAR">,
								<cfqueryparam value="#listAllPIC#" cfsqltype="CF_SQL_VARCHAR">
								)
							</cfquery>
					</cfif>
					
				</cfloop>
			</cfloop>--->
		<!---</cfif> --->


		<!--- ENC50917-81140 --->
		<cfif LOCAL.retvarParticipant eq true>
			<cfquery name="local.qGetListParticipantexist" datasource="#REQUEST.SDSN#">
				SELECT TEOMEMPPERSONAL.* FROM TTRRTRAINWAITING
				LEFT JOIN TEOMEMPPERSONAL
					ON TTRRTRAINWAITING.emp_id = TEOMEMPPERSONAL.emp_id
				WHERE 
				<cfif listempselect neq "">
					TEOMEMPPERSONAL.emp_id IN (#listQualify(listempselect,"'")#)
				<cfelse>
					1 = 0
				</cfif>
				AND trncourse_code = <cfqueryparam value="#hdn_trncourse_code#" cfsqltype="cf_sql_varchar">
				AND company_id = <cfqueryparam value="#REQUEST.SCookie.COID#" cfsqltype="cf_sql_integer">
			</cfquery>
			
			<!---Get List Participant exist in training Plan PM--->
			<cfif listfindnocase(REQUEST.SFLICENSE.MODULES,'PM')><!--- Jika Punya license PM --->
    			<cfquery name="local.qGetListParticipantexistTRNPLAN" datasource="#REQUEST.SDSN#">
    				SELECT TEOMEMPPERSONAL.full_name,  TEOMEMPPERSONAL.emp_id, TEOMEMPPERSONAL.email, RECBY.full_name RECBY_FULLNAME
    				FROM TPMDTRAINPLAN
    				LEFT JOIN TEOMEMPPERSONAL
    					ON TPMDTRAINPLAN.emp_id = TEOMEMPPERSONAL.emp_id
    				LEFT JOIN TEOMEMPPERSONAL RECBY
    					ON TPMDTRAINPLAN.recommended_by = RECBY.emp_id
    				WHERE 
    				<cfif listempselect neq "">
    				    (#Application.SFUtil.CutList(ListQualify(listempselect,"'")," TEOMEMPPERSONAL.emp_id IN  ","OR",2)#)
    				<cfelse>
    					1 = 0
    				</cfif>
    				AND TPMDTRAINPLAN.trncourse_code = <cfqueryparam value="#hdn_trncourse_code#" cfsqltype="cf_sql_varchar">
    				AND TPMDTRAINPLAN.trnevent_code IS NULL
    			</cfquery>
			</cfif><!--- Jika Punya license PM --->

			<cfif qGetListParticipantexist.recordcount gt 0 OR ( listfindnocase(REQUEST.SFLICENSE.MODULES,'PM') AND isDefined('qGetListParticipantexistTRNPLAN') AND qGetListParticipantexistTRNPLAN.recordcount GT 0)>
				<cfquery name="local.qGetDetailTrainingEvent" datasource="#REQUEST.SDSN#">
					SELECT 
						TTRDTRAINEVENT.*,
						STARTTIME.starttime,
						TTRRTRAINEVENTVENUE.venue_code,
						TTRMVENUE.venue_name,
						TTRRTRAINEVENTVENUE.room_code,
						TTRMROOMTYPE.name AS room_name,
						TTRDTRAINCOURSE.trncourse_name_#request.scookie.lang# AS trncourse_name,
						TTRRTRAINEVENTVENUE.trnevent_address
					FROM TTRDTRAINEVENT
					<!--- get starttime --->
					LEFT JOIN (
							SELECT trnevent_code, MIN(trnevent_starttime) AS starttime FROM TTRRTRAINEVENTACTIVITYTIME
							WHERE trnevent_day = 1
							GROUP BY trnevent_code
						) STARTTIME
						ON STARTTIME.trnevent_code = TTRDTRAINEVENT.trnevent_code
					<!--- /get starttime --->
					<!--- get venue --->
					LEFT JOIN TTRRTRAINEVENTVENUE
						ON TTRRTRAINEVENTVENUE.trnevent_code = TTRDTRAINEVENT.trnevent_code
					LEFT JOIN TTRMVENUE
						ON TTRMVENUE.venue_code = TTRRTRAINEVENTVENUE.venue_code
					<!--- /get venue --->
					<!--- get room name --->
					LEFT JOIN TTRMROOMTYPE
						ON TTRMROOMTYPE.code = TTRRTRAINEVENTVENUE.room_code
					<!--- /get room name --->
					LEFT JOIN TTRDTRAINCOURSE
						ON TTRDTRAINCOURSE.trncourse_code = TTRDTRAINEVENT.trncourse_code
					WHERE TTRDTRAINEVENT.trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">
				</cfquery>

				<!--- Set Content for tblListEvent --->
				<cfset local.FORMMLANG="Notitik|FDTopic|FDDate|FDLocation|Time">
				<cfset REQUEST.SFMLANG=Application.SFParser.TransMLang(listAppend("Training Course",(isdefined("FORMMLANG")?FORMMLANG:""),"|"))>
				
				<cfset LOCAL.tblListEvent=''>
				<cfif qGetDetailTrainingEvent.recordcount gt 0>
					<cfloop query="qGetDetailTrainingEvent">
						<cfset local.tblListEvent = tblListEvent & "
							<table>
								<tbody>
									<tr>
										<td style=""width:20px;""> #HTMLEDITFORMAT(qGetDetailTrainingEvent.currentrow)#. </td>
										<td> #HTMLEDITFORMAT(REQUEST.SFMLANG['FDTopic'])#</td>
										<td>: #HTMLEDITFORMAT(qGetDetailTrainingEvent.trnevent_topic)# </td>
									</tr>
									<tr>
										<td></td>
										<td> #HTMLEDITFORMAT(REQUEST.SFMLANG['FDDate'])# </td>
										<td>: #DateFormat(qGetDetailTrainingEvent.trnevent_startdate,REQUEST.config.DATE_OUTPUT_FORMAT)# </td>
									</tr>
									<tr>
										<td></td>
										<td> #HTMLEDITFORMAT(REQUEST.SFMLANG['Time'])# </td>
										<td>: #timeFormat(qGetDetailTrainingEvent.starttime, "HH:mm:ss")# </td>
									</tr>
									<tr>
										<td></td>
										<td> #HTMLEDITFORMAT(REQUEST.SFMLANG['FDLocation'])# </td>
										<td> : #HTMLEDITFORMAT(qGetDetailTrainingEvent.venue_code)# (#HTMLEDITFORMAT(qGetDetailTrainingEvent.venue_name)#)"> 
                						<cfif qGetDetailTrainingEvent.room_code neq ''>
                							<cfset tblListEvent = tblListEvent & " - #HTMLEDITFORMAT(qGetDetailTrainingEvent.room_code)# (#HTMLEDITFORMAT(qGetDetailTrainingEvent.room_name)#) ">
                						</cfif>                						
                						<cfif qGetDetailTrainingEvent.trnevent_address neq ''> <!---BUG51117-86367--->
                							<cfset tblListEvent = tblListEvent & " - #HTMLEDITFORMAT(qGetDetailTrainingEvent.trnevent_address)# ">
                						</cfif>

						                <cfset tblListEvent = tblListEvent & "
										</td>
									</tr>
								</tbody>
							</table>
						" >
					</cfloop>
				</cfif>
				<!--- /Set Content for tblListEvent --->

				<!--- Get template email --->
				<cfquery name="local.qEmailTemplate" datasource="#REQUEST.SDSN#">
					SELECT subject_#request.scookie.lang# subject,body_#request.scookie.lang# body
					FROM TSFMMAILTemplate
					WHERE template_code = 'NotifConfirmedParticipant'
				</cfquery>
				
				<!--- kalau belum ada emailtemplatenya BUG51217-87083 --->
				<cfif qEmailTemplate.recordcount eq 0>
					<cfquery name="local.qCrEmailTemplate" datasource="#REQUEST.SDSN#">
						 <cfif request.dbdriver eq "MSSQL">
						
							INSERT INTO TSFMMAILTEMPLATE 
							(
								template_code,
								subject_en,
								subject_id,
								subject_my,
								subject_th,
								body_en,
								body_id,
								body_my,
								body_th,
								status,
								issystem,
								created_date,
								created_by,
								modified_date,
								modified_by
							)
							values (
								'NotifConfirmedParticipant',
								'Confirmed as Participant',
								'Confirmed as Participant',
								'Confirmed as Participant',
								'Confirmed as Participant',
								'Dear {EMPLOYEE_NAME} <br /><br /> You are no longer in the waiting list for Training Course {TRNCOURSE_NAME} <br /> You have been confirmed as participant for the following training event :<br /> {TRNEVENT_LIST}',
								'Dear {EMPLOYEE_NAME} <br /><br /> You are no longer in the waiting list for Training Course {TRNCOURSE_NAME} <br /> You have been confirmed as participant for the following training event :<br /> {TRNEVENT_LIST}',
								'Dear {EMPLOYEE_NAME} <br /><br /> You are no longer in the waiting list for Training Course {TRNCOURSE_NAME} <br /> You have been confirmed as participant for the following training event :<br /> {TRNEVENT_LIST}',
								'Dear {EMPLOYEE_NAME} <br /><br /> You are no longer in the waiting list for Training Course {TRNCOURSE_NAME} <br /> You have been confirmed as participant for the following training event :<br /> {TRNEVENT_LIST}',
								1,
								1,
								getDate(),
								'superadmin',
								getDate(),
								'superadmin'
							)
					
						<cfelse>
							INSERT INTO TSFMMAILTEMPLATE (
								seq_id,
								template_code,
								subject_en,
								subject_id,
								subject_my,
								subject_th,
								body_en,
								body_id,
								body_my,
								body_th,
								status,
								issystem,
								created_date,
								created_by,
								modified_date,
								modified_by
							)
							SELECT * FROM (
								SELECT 
								(select max(seq_id) from TSFMMAILTEMPLATE)+1 ,
								'NotifConfirmedParticipant' as template_code, 
								'Confirmed as Participant' AS subject_en,
								'Confirmed as Participant' AS subject_id,
								'Confirmed as Participant' AS subject_my,
								'Confirmed as Participant' AS subject_th,
								'Dear {EMPLOYEE_NAME} <br /><br /> You are no longer in the waiting list for Training Course {TRNCOURSE_NAME} <br /> You have been confirmed as participant for the following training event :<br /> {TRNEVENT_LIST}' AS body_en,
								'Dear {EMPLOYEE_NAME} <br /><br /> You are no longer in the waiting list for Training Course {TRNCOURSE_NAME} <br /> You have been confirmed as participant for the following training event :<br /> {TRNEVENT_LIST}' AS body_id,
								'Dear {EMPLOYEE_NAME} <br /><br /> You are no longer in the waiting list for Training Course {TRNCOURSE_NAME} <br /> You have been confirmed as participant for the following training event :<br /> {TRNEVENT_LIST}' AS body_my,
								'Dear {EMPLOYEE_NAME} <br /><br /> You are no longer in the waiting list for Training Course {TRNCOURSE_NAME} <br /> You have been confirmed as participant for the following training event :<br /> {TRNEVENT_LIST}' AS body_th,
								1 AS status,
								1 AS issystem,
								NOW() AS created_date,
								'superadmin' AS created_by,
								NOW() AS modified_date,
								'superadmin' AS modified_by
							) AS tmp
							WHERE NOT EXISTS (
								SELECT template_code 
								FROM TSFMMAILTEMPLATE 
								WHERE template_code = 'NotifConfirmedParticipant'
							) LIMIT 1;
						 </cfif>
					</cfquery>
				</cfif>
				<cfquery name="local.qEmailTemplate" datasource="#REQUEST.SDSN#">
					SELECT subject_#request.scookie.lang# subject,body_#request.scookie.lang# body
					FROM TSFMMAILTemplate
					WHERE template_code = 'NotifConfirmedParticipant'
				</cfquery>
				<!---<cfif qEmailTemplate.recordcount gt 0>
					 Sending Email --->
					 
				<cfif qGetListParticipantexist.recordcount NEQ 0> <!---Waiting List--->
					<cfloop query="qGetListParticipantexist">
						<cfset LOCAL.eSubject = qEmailTemplate.subject>
						<cfset LOCAL.eContent = qEmailTemplate.body>

						<cfif FindNoCase("{SYS_NAME}",eSubject,1)> <!--- jika subject ingin ditambahkan app_name --->
							<cfset eSubject = ReplaceNoCase(eSubject,"{SYS_NAME}",#REQUEST.CONFIG.APP_NAME#,"ALL")>
						</cfif>

						<cfif FindNoCase("{EMPLOYEE_NAME}",eContent,1)>
							<cfset eContent = ReplaceNoCase(eContent,"{EMPLOYEE_NAME}",#HTMLEDITFORMAT(qGetListParticipantexist.full_name)#,"ALL")>
						</cfif>
						<cfif FindNoCase("{TRNCOURSE_NAME}",eContent,1)>
							<cfset eContent = ReplaceNoCase(eContent,"{TRNCOURSE_NAME}",#HTMLEDITFORMAT(qGetDetailTrainingEvent.trncourse_name)# ,"ALL")>
						</cfif>
						<cfif FindNoCase("{TRNEVENT_LIST}",eContent,1)>
							<cfset eContent = ReplaceNoCase(eContent,"{TRNEVENT_LIST}",#tblListEvent#,"ALL")>
						</cfif>
						<cfif FindNoCase("{URL_LINK}",eContent,1)>
							<cfset eContent = ReplaceNoCase(eContent,"{URL_LINK}","#listfirst(lcase(CGI.SERVER_PROTOCOL),'/')#"&"://"&"#CGI.SERVER_NAME##SCRIPT_NAME#","ALL")>
						</cfif>
            			<cfif FindNoCase("{SYS_NAME}",eContent,1)> 
            				<cfset eContent = ReplaceNoCase(eContent,"{SYS_NAME}",#REQUEST.CONFIG.APP_NAME#,"ALL")>
            			</cfif>

						<cfif qGetListParticipantexist.email neq "">

							<cfmail from="#REQUEST.CONFIG.ADMIN_EMAIL#" to="#qGetListParticipantexist.email#" subject="#eSubject#" type="HTML" failto="#REQUEST.CONFIG.ADMIN_EMAIL#">

								#eContent#
							</cfmail>
						</cfif>
					</cfloop>
					<!--- /Sending Email --->
					<!--- Delete from waiting list --->
					<cfquery name="local.qDeleteWaitingListParticipant" datasource="#REQUEST.SDSN#">
						DELETE FROM TTRRTRAINWAITING 
						WHERE emp_id IN (<cfqueryparam value="#listempselect#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
						AND trncourse_code = <cfqueryparam value="#hdn_trncourse_code#" cfsqltype="cf_sql_varchar">
						AND company_id = <cfqueryparam value="#REQUEST.SCookie.COID#" cfsqltype="cf_sql_integer">
					</cfquery>
				</cfif>
				
				
				<cfif listfindnocase(REQUEST.SFLICENSE.MODULES,'PM') > <!--- Jika Punya license PM --->
    				<!---PM Training Plan--->
    				<cfquery name="local.qEmailTemplateTrPlan" datasource="#REQUEST.SDSN#">
    					SELECT 
    					    subject_#request.scookie.lang# subject,body_#request.scookie.lang# body
    					FROM TSFMMAILTemplate
    					WHERE template_code = 'NotifConfirmedParticipantFromTrPlan'
    				</cfquery>
    				<cfif qGetListParticipantexistTRNPLAN.recordcount NEQ 0 AND qEmailTemplateTrPlan.recordcount neq 0> <!---PM Training Plan--->
            			<cfquery name="LOCAL.qGetListParticipantexistTRNPLANDetail" dbtype="query">
            			    SELECT full_name, emp_id, email  FROM qGetListParticipantexistTRNPLAN
            			    GROUP BY full_name, emp_id, email
            			</cfquery>
    					<cfloop query="qGetListParticipantexistTRNPLANDetail">
    						<cfset LOCAL.eSubject = qEmailTemplateTrPlan.subject>
    						<cfset LOCAL.eContent = qEmailTemplateTrPlan.body>
    
    						<cfif FindNoCase("{SYS_NAME}",eSubject,1)> <!--- jika subject ingin ditambahkan app_name --->
    							<cfset eSubject = ReplaceNoCase(eSubject,"{SYS_NAME}",#REQUEST.CONFIG.APP_NAME#,"ALL")>
    						</cfif>
    
    						<cfif FindNoCase("{EMPLOYEE_NAME}",eContent,1)>
    							<cfset eContent = ReplaceNoCase(eContent,"{EMPLOYEE_NAME}",#HTMLEDITFORMAT(qGetListParticipantexistTRNPLANDetail.full_name)#,"ALL")>
    						</cfif>
    						<cfif FindNoCase("{TRNCOURSE_NAME}",eContent,1)>
    							<cfset eContent = ReplaceNoCase(eContent,"{TRNCOURSE_NAME}",#HTMLEDITFORMAT(qGetDetailTrainingEvent.trncourse_name)# ,"ALL")>
    						</cfif>
    						<cfif FindNoCase("{TRNEVENT_LIST}",eContent,1)>
    							<cfset eContent = ReplaceNoCase(eContent,"{TRNEVENT_LIST}",#tblListEvent#,"ALL")>
    						</cfif>
    						<cfif FindNoCase("{URL_LINK}",eContent,1)>
    							<cfset eContent = ReplaceNoCase(eContent,"{URL_LINK}","#listfirst(lcase(CGI.SERVER_PROTOCOL),'/')#"&"://"&"#CGI.SERVER_NAME##SCRIPT_NAME#","ALL")>
    						</cfif>
                			<cfif FindNoCase("{SYS_NAME}",eContent,1)> 
                				<cfset eContent = ReplaceNoCase(eContent,"{SYS_NAME}",#REQUEST.CONFIG.APP_NAME#,"ALL")>
                			</cfif>
                			
    						<cfif FindNoCase("{RECOMMEDED_BY}",eContent,1)>
    						    <cfquery name="LOCAL.qTempRecBy" dbtype="Query"> SELECT * FROM qGetListParticipantexistTRNPLAN WHERE emp_id = '#qGetListParticipantexistTRNPLANDetail.emp_id#' </cfquery>
    						    <cfif TRIM(ValueList(qTempRecBy.recby_fullname)) NEQ ''>
    							    <cfset eContent = ReplaceNoCase(eContent,"{RECOMMEDED_BY}",#HTMLEDITFORMAT(ValueList(qTempRecBy.recby_fullname))#,"ALL")>
    							 </cfif>
    						</cfif>
    
    						<cfif qGetListParticipantexistTRNPLANDetail.email neq "">
    
    							<cfmail from="#REQUEST.CONFIG.ADMIN_EMAIL#" to="#qGetListParticipantexistTRNPLANDetail.email#" subject="#eSubject#" type="HTML" failto="#REQUEST.CONFIG.ADMIN_EMAIL#">
    								#eContent#
    							</cfmail>
    						</cfif>
    					</cfloop>
    					<!--- /Sending Email --->
    					<!--- Update Training Plan --->
    					<cfquery name="local.qDeleteWaitingListParticipant" datasource="#REQUEST.SDSN#">
    						UPDATE TPMDTRAINPLAN
    						SET trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">
    						WHERE emp_id IN (<cfqueryparam value="#listempselect#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
    						AND trncourse_code = <cfqueryparam value="#hdn_trncourse_code#" cfsqltype="cf_sql_varchar">
    						AND trnevent_code IS NULL
    					</cfquery>
    				</cfif>
				</cfif><!--- Jika Punya license PM --->
				
				
			</cfif>
		</cfif>


		<!--- /ENC50917-81140 --->
		<cfset local.tempVarCheck = "">
		<cfif LOCAL.retVarInfo eq false>
			<cfif ListFindNoCase(tempVarCheck,"General Info") eq 0>
				<cfset tempVarCheck = ListAppend(tempVarCheck,"General Info")>
			</cfif>
		</cfif>
		<cfif LOCAL.retvarVenue eq false>
			<cfif ListFindNoCase(tempVarCheck,"Location") eq 0>
				<cfset tempVarCheck = ListAppend(tempVarCheck,"Location")>
			</cfif>
		</cfif>
		<cfif LOCAL.retvarAgenda eq false>
			<cfif ListFindNoCase(tempVarCheck,"Agenda") eq 0>
				<cfset tempVarCheck = ListAppend(tempVarCheck,"Agenda")>
			</cfif>
		</cfif>
		<cfif LOCAL.retvarParticipant eq false>
			<cfif ListFindNoCase(tempVarCheck,"Participant") eq 0>
				<cfset tempVarCheck = ListAppend(tempVarCheck,"Participant")>
			</cfif>
		</cfif>
		<cfif LOCAL.retVarESS eq false>
			<cfif ListFindNoCase(tempVarCheck,"ESS") eq 0>
				<cfset tempVarCheck = ListAppend(tempVarCheck,"ESS")>
			</cfif>
		</cfif>
		<cfif LOCAL.retVarEssStage eq false>
			<cfif ListFindNoCase(tempVarCheck,"ESS Stage") eq 0>
				<cfset tempVarCheck = ListAppend(tempVarCheck,"ESS Stage")>
			</cfif>
		</cfif>
		<cfif LOCAL.retvarOther eq false>
			<cfif ListFindNoCase(tempVarCheck,"Other") eq 0>
				<cfset tempVarCheck = ListAppend(tempVarCheck,"Other")>
			</cfif>
		</cfif>
		<cfif LOCAL.retvarCost eq false>
			<cfif ListFindNoCase(tempVarCheck,"Cost") eq 0>
				<cfset tempVarCheck = ListAppend(tempVarCheck,"Cost")>
			</cfif>
		</cfif>
    
		<cfif val(trnevent_sts) lt 4 AND (LOCAL.retVarESS eq false OR LOCAL.retVarEssStage eq false OR LOCAL.retVarInfo eq false OR LOCAL.retvarParticipant eq false OR LOCAL.retvarVenue eq false OR LOCAL.retvarAgenda eq false OR LOCAL.retvarOther eq false 
		OR LOCAL.retvarCost eq false)>
			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSThere is some exception while saving data, please check tab #tempVarCheck# and re-submit",true)>
			<cfoutput>
				<script>
						alert("#SFLANG#");
						parent.refreshPage();
						parent.innerClose();
				</script>
			</cfoutput>
		<cfelse>
			<cfif val(trnevent_sts) gte 4 AND (LOCAL.retVarESS eq false OR LOCAL.retVarEssStage eq false OR LOCAL.retVarInfo eq false OR LOCAL.retvarParticipant eq false OR LOCAL.retvarVenue eq false OR LOCAL.retvarAgenda eq false OR LOCAL.retvarOther eq false 
		OR LOCAL.retvarCost eq false)>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSThere is some exception while saving data, please delete all and re-create data",true)>
				<cfoutput>
					<script>
							alert("#SFLANG#");
							parent.refreshPage();
							parent.innerClose();
			
					</script>
				</cfoutput>
			<cfelse>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Update Training Event",true)>
				<cfoutput>
					<script>
						alert("#SFLANG#");
						parent.refreshPage();
						parent.popClose();
					</script>
				</cfoutput>
			</cfif>
			
		</cfif>
		
		
  	</cffunction>

	<!--- Muadz buat select box eval method --->
	<cffunction name="reference">
    	<cfquery name="qLookUp" datasource="#request.sdsn#">
			SELECT code as optvalue, name_#REQUEST.SCookie.LANG# as opttext
			FROM tctmevalmethod
			WHERE 1=1
        </cfquery>
        <cfreturn qLookUp>
    </cffunction>

	<cffunction name="ViewEvent" return="Query">
		<cfparam name="trncourse_code" default="">
		<cfparam name="trnevent_code" default="">
		
		<!--- TCK2008-0582823 UNTUK PRINT CERTIFICATE --->
    	<cfparam name='isprint_certificate' default=false>
    		
    		<cfif isprint_certificate>
        		<!--- ambil total agenda nya --->
        		<cfquery name='qTotalAgenda' datasource='#request.sdsn#'>
        		    select max(trnevent_day) total_agenda
                	from TTRRTRAINEVENTACTIVITY
                	where trnevent_code  = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">
                	and company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
        		</cfquery>
        		
        		<!--- AMBIL LIST COMPETENCE YANG DI SET PADA TRAINING COURSE --->
        		<CFQUERY NAME="qGetCompetence" datasource='#request.sdsn#'>
        		    SELECT B.competence_name_#request.scookie.lang# COMPT_NAME
                	FROM TTRRTRAINCOURSECOMPETENCE t
                	JOIN TPMMCOMPETENCE B ON T.company_code  = B.competence_code 
                	WHERE T.company_code  = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
                	AND T.trncourse_code = <cfqueryparam value="#trncourse_code#" cfsqltype="CF_SQL_VARCHAR">
        		</CFQUERY>
    		</cfif>
		
		<!--- END TCK2008-0582823  PRINT CERTIFICATE--->
		
		<cfset checckDBChangeEventESS()>
		<cfset checkDBAddEventContent()>
		
		<cfquery name="LOCAL.qSelectESS" datasource="#REQUEST.SDSN#">
			SELECT 
			<cfif request.dbdriver eq "MSSQL">
				*
			<cfelse>
				trnevent_code,
				company_code,
				
				trnevent_enablereq,
				CASE WHEN trnevent_lastregdate !='0000-00-00' THEN trnevent_lastregdate END trnevent_lastregdate,
				trnevent_enablecontent,
				CASE WHEN trnevent_contentstartdate !='0000-00-00' THEN trnevent_contentstartdate END trnevent_contentstartdate,
				CASE WHEN trnevent_contentenddate !='0000-00-00' THEN trnevent_contentenddate END trnevent_contentenddate,
				trnevent_enabletest,
				trnevent_enablefeedback,
				CASE WHEN trnevent_feedbackduedate !='0000-00-00' THEN trnevent_feedbackduedate END trnevent_feedbackduedate,
				trnevent_enableeval,
				CASE WHEN trnevent_evalduedate !='0000-00-00' THEN trnevent_evalduedate END trnevent_evalduedate
			</cfif>
			FROM TTRRTRAINEVENTESS WHERE TTRRTRAINEVENTESS.trnevent_code		= <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">
			   AND TTRRTRAINEVENTESS.company_code		= <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">

			<!---SELECT * FROM TTRRTRAINEVENTESS WHERE TTRRTRAINEVENTESS.trnevent_code		= <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">
			   AND TTRRTRAINEVENTESS.company_code		= <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">--->
		</cfquery>
		
		<cfquery name="local.qDataStage" datasource="#REQUEST.SDSN#">
			SELECT trnstage_code, trnstage_name, trnstage_start, trnstage_startDay,trnstage_startBeAf, trnstage_end, trnstage_endDay,trnstage_endBeAf 
			FROM TTRRTRAINSTAGE
			WHERE company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
			AND trncourse_code		= <cfqueryparam value="#trncourse_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		
		<!--- QUERY INI DIGUNAKAN UNTUK MENDAPATKAN RETRIVE EMPLOYEE MANA SAJA YANG SUDAH DI SET ATT TRAINING NYA --->
		<cfquery name="LOCAL.qParticipantIsAtt" datasource="#REQUEST.SDSN#">
		    select a.emp_id 
            from TTRDTRAINATTMEMBER a
            join TTRRTRAINEVENTACTIVITYTIME b on a.trneventactivity_code = b.trneventactivity_code
            where b.trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
            and a.company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
            and upper(a.flag_present) = 'Y'
            group by emp_id
		</cfquery>
		
		<!--- muadz nambahin empat column custom--->
		<cfquery name="LOCAL.qData" datasource="#REQUEST.SDSN#">
			SELECT 
				<cfif Len(getWaitingList(trncourse_code=trncourse_code)) gt 0>
					'#ListLen(getWaitingList(trncourse_code=trncourse_code))#' as headWait,
				<cfelse>
					0 as headWait,
				</cfif>
			TTRDTRAINEVENT.trnevent_code,
			       TTRDTRAINEVENT.trncourse_code,
			       (	SELECT trncourse_name_#request.scookie.lang# trncourse_name
  						  FROM TTRDTRAINCOURSE
						 WHERE trncourse_code = TTRDTRAINEVENT.trncourse_code
						  AND company_code    = TTRDTRAINEVENT.company_code
			       )trncourse_name,
			       (
			            SELECT CASE WHEN COUNT(a.jobtitle_code) = 0 THEN 0 ELSE 1 END  
			            FROM TTRDTRAINJOBTITLE a
			                LEFT JOIN TEOMJOBTITLE b ON a.jobtitle_code=b.jobtitle_code
			                LEFT JOIN TTRDTRAINCOURSE c ON a.company_code=c.company_code AND a.trncourse_code=c.trncourse_code
			            WHERE a.trncourse_code = TTRDTRAINEVENT.trncourse_code
						  AND a.company_code = TTRDTRAINEVENT.company_code
			       )chk_filter,
			       TTRDTRAINEVENT.trnevent_topic,
			       TTRDTRAINEVENT.company_code,
				   TTRDTRAINEVENT.trnevent_type,
			       TTRMEVENTTYPE.name_#request.scookie.lang# nametype,
			       TTRDTRAINEVENT.trnevent_startdate,
			       TTRDTRAINEVENT.trnevent_enddate,
			       TTRDTRAINEVENT.trnevent_sts,
			       TTRDTRAINEVENT.in_threport, 
			       <cfif request.dbdriver eq "MYSQL">
			       cast(TTRDTRAINEVENT.trnevent_capacity as int) trnevent_capacity,
			       <cfelse>
			       TTRDTRAINEVENT.trnevent_capacity,
			       </cfif>
			       TTRDTRAINEVENT.costcenter_type,
			       TTRRTRAINEVENTINFO.trnevent_bckground,
			       TTRRTRAINEVENTINFO.trnevent_obj,
			       TTRRTRAINEVENTINFO.trnevent_target,
			       TTRRTRAINEVENTINFO.trnevent_remark,
			       TTRRTRAINEVENTINFO.trnevent_attachment,
				   TTRRTRAINEVENTINFO.delivmethod,
				   TTRRTRAINEVENTINFO.evalmethod,
				   TTRRTRAINEVENTINFO.acceptcriteria,
				   TTRRTRAINEVENTINFO.material,
			       TTRRTRAINEVENTVENUE.provider_code,
				   TTRRTRAINEVENTVENUE.venue_code, 
				   TTRRTRAINEVENTVENUE.trnevent_address,
				   TTRRTRAINEVENTVENUE.room_code,
				   TTRRTRAINEVENTESS.trnevent_enablereq,
				   
				   <cfif qSelectESS.trnevent_lastregdate eq ''>
				        <cfif request.dbdriver eq "MYSQL">
				        date_add(TTRDTRAINEVENT.trnevent_startdate, INTERVAL 6 DAY) AS trnevent_lastregdate,
				        <cfelse>
						dateadd(d,6,TTRDTRAINEVENT.trnevent_startdate) AS trnevent_lastregdate,
						</cfif>
					</cfif>
				   <cfif qSelectESS.trnevent_lastregdate neq ''>
						TTRRTRAINEVENTESS.trnevent_lastregdate,
				   </cfif>
				   
				   TTRRTRAINEVENTESS.trnevent_enablecontent,
				   TTRRTRAINEVENTESS.trnevent_enableallcontent,
				   
				   <cfif qSelectESS.trnevent_contentstartdate eq ''>
				        <cfif request.dbdriver eq "MYSQL">
				        date_add(TTRDTRAINEVENT.trnevent_startdate, INTERVAL -6 DAY) AS trnevent_contentstartdate,
				        <cfelse>
						dateadd(d,-6,TTRDTRAINEVENT.trnevent_startdate) AS trnevent_contentstartdate,
						</cfif>
				   </cfif>
				   <cfif qSelectESS.trnevent_contentstartdate neq ''>
						TTRRTRAINEVENTESS.trnevent_contentstartdate,
				   </cfif>
				   <cfif qSelectESS.trnevent_contentenddate eq ''>
				        <cfif request.dbdriver eq "MYSQL">
						date_add(TTRDTRAINEVENT.trnevent_enddate, INTERVAL 6 DAY) AS trnevent_contentenddate,
				        <cfelse>
						dateadd(d,6,TTRDTRAINEVENT.trnevent_enddate) AS trnevent_contentenddate,
						</cfif>
				   </cfif>
				   <cfif qSelectESS.trnevent_contentenddate neq ''>
					   TTRRTRAINEVENTESS.trnevent_contentenddate,
				   </cfif>
				   
				   TTRRTRAINEVENTESS.trnevent_enabletest,
				   TTRRTRAINEVENTESS.trnevent_enablefeedback,
				   
				   <cfif qSelectESS.trnevent_feedbackduedate eq ''>
				        <cfif request.dbdriver eq "MYSQL">
					    date_add(TTRDTRAINEVENT.trnevent_enddate, INTERVAL 6 DAY) AS trnevent_feedbackduedate,
				        <cfelse>
					    dateadd(d,6,TTRDTRAINEVENT.trnevent_enddate) AS trnevent_feedbackduedate,
						</cfif>
				   </cfif>
				   <cfif qSelectESS.trnevent_feedbackduedate neq ''>
						TTRRTRAINEVENTESS.trnevent_feedbackduedate,
				   </cfif>
				   
				   <cfif qSelectESS.trnevent_evalduedate eq ''>
				        <cfif request.dbdriver eq "MYSQL">
				   		date_add(TTRDTRAINEVENT.trnevent_enddate, INTERVAL 6 DAY) AS trnevent_evalduedate,
				        <cfelse>
				   		dateadd(d,6,TTRDTRAINEVENT.trnevent_enddate) AS trnevent_evalduedate,
						</cfif>
				   </cfif>
				    <cfif qSelectESS.trnevent_evalduedate neq ''>
				   		TTRRTRAINEVENTESS.trnevent_evalduedate,
				   </cfif>

				   TTRRTRAINEVENTESS.trnevent_enableeval,
				   TTRRTRAINEVENTOTHER.trnevent_enablecertified,
				   TTRRTRAINEVENTOTHER.trnevent_validcertified,
				   TTRRTRAINEVENTOTHER.trnevent_agreement,
				   TTRRTRAINEVENTOTHER.trnevent_validagreement,
				   TTRRTRAINEVENTOTHER.trnevent_enableprintcertificate,
				   TTRRTRAINEVENTOTHER.Printcertificate_startdate,
				   TTRRTRAINEVENTOTHER.Printcertificate_enddate,
				   TTRRTRAINEVENTOTHER.Isonce_printcertificate,
				   '#VALUELIST(qParticipantIsAtt.EMP_ID)#' listatt_participant,
				   tblAtt.countAtt,
                   case 
                        when TTRRTRAINEVENTESS.trnevent_enablefeedback = 'Y' then 
                        tblFdbk.countFdbk
                    	else
                    	0
                   end countFdbk,
                   case 
                        when TTRRTRAINEVENTESS.trnevent_enableeval = 'Y' then 
                        tblEval.countEval
                        else
                        0
                   end countEval
                   
                   <!--- JIKA DARI SFTRAININGCERTIFICATIONTEMPLATE.CFC --->
                   <CFIF isprint_certificate>
                       ,TTRDTRAINEVENT.CREATED_BY,
                       '#qTotalAgenda.total_agenda#' TOTAL_AGENDA,
                       '#VALUELIST(qGetCompetence.COMPT_NAME)#' comp_name,
                       (select venue_name
                       from TTRMVENUE
                       where venue_code = TTRRTRAINEVENTVENUE.venue_code) venue_name
                   </CFIF>
                   , cc.certificate_code
			  FROM TTRDTRAINEVENT 
			  	   LEFT JOIN TTRMEVENTTYPE ON TTRDTRAINEVENT.trnevent_type = TTRMEVENTTYPE.code
			  	   LEFT JOIN TTRRTRAINEVENTINFO ON TTRDTRAINEVENT.trnevent_code  = TTRRTRAINEVENTINFO.trnevent_code
			  	   							   AND TTRDTRAINEVENT.company_code  = TTRRTRAINEVENTINFO.company_code 
			       LEFT JOIN TTRRTRAINEVENTVENUE ON TTRDTRAINEVENT.trnevent_code = TTRRTRAINEVENTVENUE.trnevent_code
			       							   AND TTRDTRAINEVENT.company_code	= TTRRTRAINEVENTVENUE.company_code 	  
			 	   LEFT JOIN TTRRTRAINEVENTESS ON TTRDTRAINEVENT.trnevent_code  = TTRRTRAINEVENTESS.trnevent_code
			 	   							   AND TTRDTRAINEVENT.company_code	= TTRRTRAINEVENTESS.company_code	
			 	   LEFT JOIN TTRRTRAINEVENTOTHER ON TTRDTRAINEVENT.trnevent_code  =	TTRRTRAINEVENTOTHER.trnevent_code
			 	   							   AND TTRDTRAINEVENT.company_code = TTRRTRAINEVENTOTHER.company_code
				   LEFT JOIN TTRRTRAINEVENTMEMBER ON TTRRTRAINEVENTMEMBER.trnevent_code = TTRDTRAINEVENT.trnevent_code
				   LEFT JOIN (
                        select count(a.trneventactivity_code) countAtt, b.trnevent_code, b.company_code from TTRDTRAINATTMEMBER a 
                        left join TTRRTRAINEVENTACTIVITYTIME b on b.trneventactivity_code = a.trneventactivity_code
                        where b.trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> and b.company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
                        group by b.trnevent_code, b.company_code
                   ) tblAtt on tblAtt.trnevent_code = TTRDTRAINEVENT.trnevent_code and tblAtt.company_code = TTRDTRAINEVENT.company_code
                   LEFT JOIN (
                        select count(a.trnevent_code) countFdbk, a.trnevent_code, a.company_code from TTRDMEMBERFEEDBACK a left join 
                        TTRDTRAINEVENT b on b.trnevent_code = a.trnevent_code where 
                        a.trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> and a.company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
                        group by a.trnevent_code, a.company_code
                   ) tblFdbk on tblFdbk.trnevent_code = TTRDTRAINEVENT.trnevent_code and tblFdbk.company_code = TTRDTRAINEVENT.company_code
                   LEFT JOIN (
                        select count(a.trnevent_code) countEval,  a.trnevent_code, a.company_code  from TTRDMEMBEREVALUATE a left join
                        TTRDTRAINEVENT b on b.trnevent_code = a.trnevent_code where 
                        a.trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> and a.company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
                        group by a.trnevent_code, a.company_code
                   ) tblEval on tblEval.trnevent_code = TTRDTRAINEVENT.trnevent_code and tblEval.company_code = TTRDTRAINEVENT.company_code
                   LEFT JOIN TTRRTRNCOURSECERTIFICATE cc on cc.trncourse_code = TTRDTRAINEVENT.trncourse_code AND cc.company_code = TTRDTRAINEVENT.company_code
                   
				   
			 WHERE TTRDTRAINEVENT.trnevent_code		= <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">
			   AND TTRDTRAINEVENT.company_code		= <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		
		<cfif qData.recordcount eq 0>
			<!--- muadz nambahin empat column custom --->
			<cfquery name="local.qData" datasource="#REQUEST.SDSN#">
			   SELECT 
				   <cfif Len(getWaitingList(trncourse_code=trncourse_code)) gt 0>
						'#ListLen(getWaitingList(trncourse_code=trncourse_code))#' as headWait,
					<cfelse>
						0 as headWait,
					</cfif>
			   '' trnevent_code,
			       	  '#trncourse_code#' trncourse_code,
			       	  '' trnevent_topic,
			          '' nametype,
			       	  '' trnevent_startdate,
			       	  '' trnevent_enddate,
			       	  '' trnevent_sts,
			       	  '' costcenter_type,
			       	  '' trnevent_capacity,
			       	  '' trnevent_bckground,
			       	  '' trnevent_obj,
			       	  '' trnevent_target,
			       	  '' trnevent_remark,
					  '' delivmethod,
					  '' evalmethod,
					  '' acceptcriteria,
					  '' material,
			       	  '' trnevent_attachment,
			       	  '' provider_code,
				      '' venue_code, 
				      '' trnevent_address,
				      '' room_code,
				      '' trnevent_enablereq,
				   	  '' trnevent_lastregdate,
				   	  '' TTRRTRAINEVENTESS,
				   	  '' trnevent_enablecontent,
				   	  '' trnevent_contentstartdate,
				   	  '' trnevent_contentenddate,
				   	  '' trnevent_enabletest,
				   	  '' trnevent_enablefeedback,
				   	  '' trnevent_feedbackduedate,
				   	  '' trnevent_enableeval,
				   	  '' trnevent_evalduedate,
				   	  '' listatt_participant,
				   	  '' trncourse_name,
				   	  '' trnevent_enablecertified,
				   '' trnevent_validcertified,
				   '' trnevent_agreement,
				   '' trnevent_validagreement,
				   '' trnevent_enableprintcertificate,
				    '' Printcertificate_startdate,
				   '' Printcertificate_enddate,
				   '' Isonce_printcertificate,
				   	  0 countAtt,
				   	  0 countFdbk,
				   	  0 countEval
			</cfquery>
		</cfif>

		<cfquery name="qGetDelivMethod" datasource="#REQUEST.SDSN#">
			SELECT delivmethod FROM ttrrtraineventinfo
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>

		<cfset delivmethod = qGetDelivMethod.delivmethod>

		<cfset REQUEST.KeyFields="trnevent_code=#qData.trnevent_code#|company_code=#REQUEST.SCookie.COCODE#">
		<cfreturn qData>
	</cffunction>

	<!---<cffunction  name="filterSelDelivMethod">
		<cfparam name="search" default="">
		<cfparam name="nrow" default="1000">
		<cfparam name="schedulegroup_code" default="">
		<cfparam name="group_emp" default="">
		<cfparam name="request_no" default="">
    	<cfif val(nrow) eq "0">
			<cfset local.nrow="50">
		</cfif>
	
		<!---	<cfquery name="LOCAL.qGetMember" datasource="#REQUEST.SDSN#">
    		SELECT emp_id FROM TTRDTRAINREQMEMBER 
    		 WHERE request_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
    		   AND company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR"> 
    	</cfquery>--->
    	<cfquery name="LOCAL.qGetMember" datasource="#REQUEST.SDSN#">
    		SELECT emp_id FROM TTRRTRAINEVENTMEMBER 
    		 WHERE trnevent_code = <cfqueryparam value="#group_emp#" cfsqltype="cf_sql_varchar">
    		   AND company_code = <cfqueryparam value="#REQUEST.SCookie.COCODE#" cfsqltype="CF_SQL_VARCHAR"> 
    	</cfquery>

		<cfset LOCAL.listempid = "">
		<cfif qGetMember.recordcount neq 0>
			<cfset listempid = valuelist(qGetMember.emp_id)/>
    	</cfif>

		
		<cfset LOCAL.searchText=trim(search)>
		<cfset LOCAL.empid=trim(listempid)>
		<cfoutput>
		<cf_sfqueryemp name="LOCAL.qdata" dsn="#REQUEST.SDSN#" maxrows="#nrow#" ACCESSCODE="hrm.employee">
			SELECT DISTINCT EC.emp_id emp_id,EC.emp_no
				,full_name emp_name 
			FROM TEOMEmpPersonal E 
				INNER JOIN TEODEMPCOMPANY EC ON EC.emp_id = E.emp_id 
			WHERE EC.company_id = <cf_sfqparamemp value="#request.scookie.coid#" type="CF_SQL_INTEGER"/> 
				<!--- AND EC.status = '1' --- BUG50218-89302 --->
				<!--- AND (EC.end_date > #createODBCDate(now())# OR EC.end_date is null) remarked by rahman BUG50315-39352 --->
				<cfif len(searchText)>
				AND (E.full_name LIKE <cf_sfqparamemp type="CF_SQL_VARCHAR" value="%#searchText#%"/>)
				</cfif>
				<cfif len(empid)>
					AND EC.emp_id IN (<cf_sfqparamemp value="#empid#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
				<cfelse>
					AND 1 = 0	
				</cfif>
			order by emp_name
		</cf_sfqueryemp>
		</cfoutput>
		
		<cfset local.lstemp = "">
		<cfif qData.recordcount neq 0>
			<cfset lstemp = valuelist(qData.emp_id)>
		</cfif>
		<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSEmployee",true,"+")>
		<cfset LOCAL.vResult="">
		<cfloop query="qData"><cfset vResult=vResult & "
			arrEntryList[#currentrow-1#]=""#JSStringFormat(emp_id & "=" & emp_name & " (#emp_no#)")#"";">
		</cfloop>
		<cfoutput>
		<script>
			<!---document.getElementById('lbl_inp_emp').innerHTML  = '#SFLANG# (#qData.recordcount#) <span class=\"required\">*</span>' ;
			document.getElementById('inp_listemp').value  = '#lstemp#' ;--->
			if($sf("inp_listempselect")) {
				$sf("inp_listempselect").value = "#listempid#";
			}
			arrEntryList=new Array();
			<cfif len(vResult)>
			#vResult#
			</cfif>
		</script>
		</cfoutput>
	</cffunction>--->

	<cffunction  name="filterSelDelivMethod">
		<cfquery name="LOCAL.qLookupRef" datasource="#REQUEST.SDSN#">
			SELECT code optvalue, name_#REQUEST.SCOOKIE.LANG# opttext 
			    FROM tctmdelivmethod
			WHERE 1=1 
			order by opttext
		</cfquery>
		
		<cfif structKeyExists(URL,"techdebug") AND URL.techdebug eq "qLookupRef" >
			<cfdump var="#qLookupRef#" label="qLookupRef-TechDev-Debug" expand='false'>
		</cfif>
		
		<cfreturn qLookupRef>
	</cffunction>

	<cffunction name="referenceAttStat">
		<cfquery name="LOCAL.qLookupRef" datasource="#REQUEST.SDSN#">
			SELECT word optvalue,
			<!---word + ' ' + description opttext FROM TSFMRESERVEWORD--->
			#Application.SFUtil.DBConcat(["word"," '  ' ","coalesce(description,'')"])#  opttext
			FROM TSFMRESERVEWORD
			WHERE word NOT LIKE '%_DAILY'
			AND category = 'ATTINTFDATA'
			AND word NOT IN (SELECT attend_code FROM TTAMATTSTATUS)
			UNION
			SELECT attend_code optvalue,
			<!---attend_code + ' ' + attend_name_#request.scookie.lang# opttext --->
			#Application.SFUtil.DBConcat(["attend_code"," '  ' ","attend_name_#request.scookie.lang# "])#  opttext
			FROM TTAMATTSTATUS

			ORDER BY 1
		</cfquery>
		
		<cfif structKeyExists(URL,"techdebug") AND URL.techdebug eq "qLookupRef" >
			<cfdump var="#qLookupRef#" label="qLookupRef-TechDev-Debug" expand='false'>
		</cfif>
		
		<cfreturn qLookupRef>
	</cffunction>

	<cffunction  name="filterEvalMethod">
		<cfquery name="qLookUp" datasource="#request.sdsn#">
			select code as optvalue, name_en as opttext
			from tctmevalmethod
			where 1=1
		</cfquery>
	</cffunction>

</cfcomponent>