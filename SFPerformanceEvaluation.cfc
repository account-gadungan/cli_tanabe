	<cfcomponent name="SFPerformanceEvaluation" hint="SunFish Performance Evaluation Object" extends="SFBP">
		<cfsetting showdebugoutput="yes">
	    <cfset strckArgument = {
								"Module" 			= "PM",
								"ObjectName" 		= "PerformanceEvaluation-",
								"ObjectTable" 		= "TPMDPERFORMANCE_EVALH",
								"ObjectTitle" 		= "Performance Evaluation",
								"KeyField" 			= "request_no",
								"TitleField" 		= "Request No",
								"GridColumn" 		= "", <!--- defined on Listing method --->
								"PKeyField" 		= "",
								"ObjectApproval" 	= "PERFORMANCE.Evaluation",
								"DocApproval" 		= "PERFORMANCEEVALUATION",
								"bIsTransaction" 	= true
							} />
		<cfset Init(argumentCollection = strckArgument) />
    		
    	<!---TCK2002-0548467--->
        <Cfset REQUEST.InitVarCountDeC = getDecimalCountFromParam()>
        <cffunction name="getDecimalCountFromParam">
            <cfset LOCAL.VarNumFormatConf = request.config.NUMERIC_FORMAT>
            <cfset LOCAL.VargetDecimalAfter = ListLast(VarNumFormatConf,'.')>
            <cfset LOCAL.InitVarCountDeC = LEN(VargetDecimalAfter)> 
            
            <cfreturn InitVarCountDeC>
        </cffunction>
        <!---TCK2002-0548467--->
		<cffunction name="getEmpListing">
				<cfif request.dbdriver eq "MSSQL">
					<cfset LOCAL.nowdate= DATEFORMAT(CreateDate(Datepart("yyyy",now()),Datepart("m",now()),Datepart("d",now())),"mm/dd/yyyy")>
				<cfelse>
					<cfset LOCAL.nowdate= DATEFORMAT(CreateDate(Datepart("yyyy",now()),Datepart("m",now()),Datepart("d",now())),"yyyy-mm-dd")>
				</cfif>
				<cfparam name="inp_startdt" default="#nowdate#">
				<cfparam name="inp_enddt" default="#nowdate#">
				<cfparam name="ReturnVarCheckCompParam" default="1">
				<cfquery name="local.qPeriodPerfEval" datasource="#request.sdsn#">
					select period_code from tpmmperiod where final_enddate >= '#inp_startdt#' AND final_startdate <= '#inp_enddt#'
				</cfquery>
			    
           
		    	<cfif ReturnVarCheckCompParam eq true>
					 <cfquery name="local.qGetEmp" datasource="#request.sdsn#">
						 SELECT reviewee_empid emp_id, 
						  period_code 
						FROM 
						  TPMDPERFORMANCE_EVALGEN EH 
						WHERE 
						  company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar"> 
						  AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
                            <cfif qPeriodPerfEval.recordcount gt 0 and qPeriodPerfEval.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriodPerfEval.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                            </cfif>
						GROUP BY reviewee_empid, period_code
						UNION 
						SELECT 
						   EC.emp_id, 
						  EH.period_code 
						FROM 
						  TCLTREQUEST REQ LEFT JOIN TEODEMPCOMPANY EC ON ( EC.emp_id = REQ.reqemp  AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar"> )
						 
						  LEFT JOIN TPMDPERFORMANCE_EVALH EH ON EH.reviewee_empid = REQ.reqemp 
						  AND EH.request_no = REQ.req_no 
						 
						WHERE 
						  UPPER(REQ.req_type) = 'PERFORMANCE.EVALUATION' 
						  AND REQ.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						  AND (
							REQ.approval_list LIKE <cfqueryparam value="#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list = <cfqueryparam value="#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
						)
                        <cfif qPeriodPerfEval.recordcount gt 0 and qPeriodPerfEval.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriodPerfEval.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                        </cfif>
						GROUP BY emp_id, period_code
					</cfquery>
					
				<cfelse>
					<cfquery name="local.qGetEmp" datasource="#request.sdsn#">
					SELECT DISTINCT EC.emp_id,
						EH.period_code
					FROM TCLTREQUEST REQ
					LEFT JOIN TPMDPERFORMANCE_EVALH EH
						ON  EH.reviewee_empid = REQ.reqemp 
						AND EH.request_no = REQ.req_no
					LEFT JOIN TEODEMPCOMPANY EC ON EC.emp_id = REQ.reqemp
						AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
					WHERE UPPER(REQ.req_type) = 'PERFORMANCE.EVALUATION'
						AND REQ.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						AND (
							REQ.approval_list LIKE <cfqueryparam value="#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list = <cfqueryparam value="#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
						)
                        <cfif qPeriodPerfEval.recordcount gt 0 and qPeriodPerfEval.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriodPerfEval.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                        </cfif>
					</cfquery>
				</cfif>
				<cfreturn qGetEmp>
		</cffunction>
		<cffunction name="isGeneratePrereviewer">
			<cfset local.retvarCompParam = false>
			<cfquery name="LOCAL.qGetCompParam" datasource="#REQUEST.SDSN#">
			select field_value from tclcappcompany where UPPER(module) = 'PERFORMANCE' and UPPER(field_code) = 'PREGENERATE_REVIEWER'
			and company_id = #REQUEST.SCOOKIE.COID#
			</cfquery>
			<cfif qGetCompParam.field_value neq "">
				<cfif UCASE(qGetCompParam.field_value) eq "Y">
					<cfset retvarCompParam = true>
				</cfif>
			</cfif>
			<cfreturn retvarCompParam>
		</cffunction>
		<cffunction name="checkDBChange">
			<cfquery name="local.qCheckTable" datasource="#request.sdsn#">
				<cfif request.dbdriver eq "MYSQL">
					select column_name from INFORMATION_SCHEMA.COLUMNS where UPPER(table_name) = 'TPMDPERIODCOMPONENT'
					and UPPER(column_name) = 'LOOKUP_TOTAL' LIMIT 1
				<cfelse>
					select TOP 1 column_name from INFORMATION_SCHEMA.COLUMNS where UPPER(table_name) = 'TPMDPERIODCOMPONENT'
					and UPPER(column_name) = 'LOOKUP_TOTAL' 
				</cfif>
			</cfquery>
			<cfif qCheckTable.recordcount eq 0>
				<cfquery name="local.qAlterTable1" datasource="#request.sdsn#">
				    Alter table TPMDPERIODCOMPONENT
					ADD lookup_total int;
				</cfquery>
			</cfif>
			<cfquery name="local.qCheckTable" datasource="#request.sdsn#">
				<cfif request.dbdriver eq "MYSQL">
					select column_name from INFORMATION_SCHEMA.COLUMNS where UPPER(table_name) = 'TPMDPERIODCOMPONENT'
					and UPPER(column_name) = 'LOOKUP_SCORETYPE' LIMIT 1
				<cfelse>
					select TOP 1 column_name from INFORMATION_SCHEMA.COLUMNS where UPPER(table_name) = 'TPMDPERIODCOMPONENT'
					and UPPER(column_name) = 'LOOKUP_SCORETYPE' 
				</cfif>
			</cfquery>
			<cfif qCheckTable.recordcount eq 0>
				<cfquery name="local.qAlterTable2" datasource="#request.sdsn#">
					 Alter table TPMDPERIODCOMPONENT
					 ADD lookup_scoretype varchar(50);
				</cfquery>
			</cfif>
		</cffunction>
		<!---<cfset callcheckDBChange = checkDBChange()>  ---->
		<cfset variables.objPerfEvalH = CreateObject("component","SMPerfEvalH")/>
		<cfset variables.objPerfEvalD = CreateObject("component","SMPerfEvalD")/>
		<cfset variables.objRequestApproval = CreateObject("component","SFRequestApproval").init(false) /><!---TCK1908-0518296 set ke false untuk skip approver ketika step workflow approval tidak ditemukan employeenya--->
		<cfset variables.company_code = CreateObject("component","SFCompany").getCompCode(request.scookie.coid)>
	
	
	<cffunction name="qGetListPlanFullyApproveAndClosed">
		<cfparam name="period_code" default="">
		<cfparam name="lst_emp_id" default="">
		<cfparam name="is_emp_defined" default="N">
		<cfparam name="by_form_no" default="N">
		<cfparam name="form_no" default="">
		<cfparam name="isfinal" default="1">
		
		<cfparam name="allstatus" default="false"><!--- TCK1018-81902 --->
		
		<!--- Get emp_id fully approved perf plan--->
		<cfquery name="local.qListEmpFullyApprClosed" datasource="#request.sdsn#">
            SELECT 
            	DISTINCT
            	TPMDPERFORMANCE_EVALH.form_no, 
          
            	TPMDPERFORMANCE_EVALH.period_code,
            	TPMDPERFORMANCE_EVALH.reviewee_empid,
            	TPMDPERFORMANCE_EVALH.reference_date
            	
            	,TCLTREQUEST.reqemp
            	,TEOMEMPPERSONAL.full_name
            	,TEODEMPCOMPANY.emp_no
            	
            	,TEOMPOSITION.pos_name_#request.scookie.lang# AS pos_name
				,ORG.position_id as orgunitid
            	,ORG.pos_name_#request.scookie.lang# AS orgunit
            	,TEOMJOBGRADE.grade_name
            	
            	,TPMMPERIOD.period_name_#request.scookie.lang# AS period_name
            	,TPMDPERFORMANCE_EVALH.request_no
            	,TPMDPERFORMANCE_EVALH.reviewer_empid
            FROM TPMDPERFORMANCE_EVALH
            
            LEFT JOIN TCLTREQUEST
            	ON TCLTREQUEST.req_no = TPMDPERFORMANCE_EVALH.request_no
            	AND TCLTREQUEST.req_no IS NOT NULL
            
            LEFT JOIN TEOMEMPPERSONAL
            	ON TEOMEMPPERSONAL.emp_id = TPMDPERFORMANCE_EVALH.reviewee_empid
            	
            LEFT JOIN TEODEMPCOMPANY 
                ON TEODEMPCOMPANY.emp_id = TPMDPERFORMANCE_EVALH.reviewee_empid
                
            LEFT JOIN TEOMPOSITION
                ON TEOMPOSITION.position_id = TEODEMPCOMPANY.position_id 

            LEFT JOIN TEOMPOSITION ORG 
                ON ORG.position_id = TEOMPOSITION.dept_id
                
            LEFT JOIN TPMMPERIOD 
                ON TPMMPERIOD.period_code = TPMDPERFORMANCE_EVALH.period_code 
                
                    
            LEFT JOIN TEOMJOBGRADE 
                ON TEODEMPCOMPANY.grade_code = TEOMJOBGRADE.grade_code 
                AND TEODEMPCOMPANY.company_id = TEOMJOBGRADE.company_id 
                    	
            WHERE TCLTREQUEST.req_no IS NOT NULL
                AND TPMDPERFORMANCE_EVALH.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
                AND TEODEMPCOMPANY.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
            
                <cfif allstatus EQ true>
            	  
                <cfelse>
	            	AND (TCLTREQUEST.status = 3 OR TCLTREQUEST.status = 9) <!--- 3=Fully Approved, 9=Closed --->
                </cfif>
            	
            	<cfif by_form_no EQ 'Y'>
            	    AND TPMDPERFORMANCE_EVALH.form_no = <cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar">
            	<cfelse>
            	    AND TPMDPERFORMANCE_EVALH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
            	</cfif>
            	
            	<cfif is_emp_defined eq 'Y' AND lst_emp_id neq ''>
            	    AND TPMDPERFORMANCE_EVALH.reviewee_empid IN (<cfqueryparam value="#lst_emp_id#" cfsqltype="cf_sql_varchar" list="yes">)
            	</cfif>
            	<cfif isfinal eq 1>
            	    AND TPMDPERFORMANCE_EVALH.isfinal = 1
            	</cfif>
            	
            ORDER BY TEOMEMPPERSONAL.full_name
		</cfquery>
	
		<cfreturn qListEmpFullyApprClosed>

	</cffunction>
	
	<cffunction name="DeletePlan">
	    <cfparam name="lstdelete" default="">
		<cfset LOCAL.ObjPlanning = createobject("component","SFPerformancePlanning")>
		
		<cfquery name="local.qListEmpFullyApprClosed" datasource="#request.sdsn#">
		    select form_no ,file_attachment from TPMDPERF_EVALATTACHMENT
		    where form_no = <cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar">
		    and company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
		    
		</cfquery>
		
	    <cfloop list="#lstdelete#" index="LOCAL.form_no">
	        <cfset LOCAL.retVarDeleteByFormNo = ObjPlanning.DeleteAllPerfPlanByFormNo(form_no=form_no)>
	    </cfloop>
	    
        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Delete Performance Evaluation Form",true)>
		<cfif retVarDeleteByFormNo eq false>
		    <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed Delete Performance Evaluation Form",true)>
		</cfif>
	    
		<cfoutput>
			<script>
				alert("#SFLANG#");
				top.popClose();
				if(top.opener){
					top.opener.reloadPage();
				}
			</script>
		</cfoutput>
	</cffunction>

		
	<cffunction name="Listing">
				<cfif structkeyexists(REQUEST,"SHOWCOLUMNGENERATEPERIOD")>
					<cfset local.ReturnVarCheckCompParam = REQUEST.SHOWCOLUMNGENERATEPERIOD>
				<cfelse>
					<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
				</cfif>

				<cfset local.sdate = DATEFORMAT(CreateDate(Datepart("yyyy",now()),Datepart("m",now()),1),"mm/dd/yyyy")>
				<cfset local.edate = DATEFORMAT(CreateDate(Datepart("yyyy",now()),12,31),"#REQUEST.CONFIG.DATE_INPUT_FORMAT#")>
				<cfif request.dbdriver eq "MSSQL">
					<cfset LOCAL.nowdate= DATEFORMAT(CreateDate(Datepart("yyyy",now()),Datepart("m",now()),Datepart("d",now())),"mm/dd/yyyy")>
				<cfelse>
					<cfset LOCAL.nowdate= DATEFORMAT(CreateDate(Datepart("yyyy",now()),Datepart("m",now()),Datepart("d",now())),"yyyy-mm-dd")>
				</cfif>
				<cfparam name="inp_startdt" default="#nowdate#">
				<cfparam name="inp_enddt" default="#nowdate#">
				
				<cfif request.dbdriver eq "MSSQL">
					<cfset inp_startdt= DATEFORMAT(CreateDate(Datepart("yyyy",inp_startdt),Datepart("m",inp_startdt),Datepart("d",inp_startdt)),"mm/dd/yyyy")>
					<cfset inp_enddt= DATEFORMAT(CreateDate(Datepart("yyyy",inp_enddt),Datepart("m",inp_enddt),Datepart("d",inp_enddt)),"mm/dd/yyyy")>
				<cfelse>
					<cfset inp_startdt= DATEFORMAT(CreateDate(Datepart("yyyy",inp_startdt),Datepart("m",inp_startdt),Datepart("d",inp_startdt)),"yyyy-mm-dd")>
					<cfset inp_enddt= DATEFORMAT(CreateDate(Datepart("yyyy",inp_enddt),Datepart("m",inp_enddt),Datepart("d",inp_enddt)),"yyyy-mm-dd")>
				</cfif>
				
				<cfset LOCAL.scParam=paramRequest()>
					<cfif request.scookie.cocode neq "issid">
						<cfset Local.StrckTemp = listingFilter(inp_startdt=inp_startdt,inp_enddt=inp_enddt)>
					</cfif>
			        <cfif ReturnVarCheckCompParam eq true>
					    <cfif request.dbdriver eq "MSSQL">
                             <cfset LOCAL.lsField="e.company_id, p.full_name AS emp_name, e.emp_id, e.emp_no, '-' AS reqapporder, pos.pos_name_#request.scookie.lang# AS emp_pos, dep.pos_name_#request.scookie.lang# dept, pos.position_id, e.employ_code, e.job_status_code, es.employmentstatus_name_#request.scookie.lang# AS status, per.period_code AS periodcode, CASE WHEN jfl.period_code IS NULL AND per.period_code = jfl.period_code OR jfl.emp_id IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p  INNER JOIN tpmrperiodfilterjflcode aa ON aa.period_code = p.period_code WHERE aa.company_code = '#request.scookie.cocode#') THEN '-' ELSE per.period_code END jfl_per , CASE WHEN jfl.emp_id IS NOT NULL AND jfl.emp_id = e.emp_id THEN jfl.emp_id ELSE '-' END jfl , CASE WHEN fec.period_code IS NULL AND per.period_code = fec.period_code OR fec.employmentstatus_code IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( p.period_code IN ( SELECT period_code FROM tpmrperiodfilteremploycode WHERE company_code = '#request.scookie.cocode#' group by period_code ) ) ) THEN '-' ELSE per.period_code END emcod_per , CASE WHEN fec.employmentstatus_code IS NOT NULL AND fec.employmentstatus_code = e.employ_code THEN fec.employmentstatus_code ELSE '-' END emcod , CASE WHEN fjs.period_code IS NULL AND per.period_code = fjs.period_code OR fjs.jobstatuscode IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( p.period_code IN ( SELECT  period_code FROM tpmrperiodfilterjobstatuscode WHERE company_code = '#request.scookie.cocode#' group by period_code ) ) ) THEN '-' ELSE per.period_code END fjs_per , CASE WHEN fjs.jobstatuscode IS NOT NULL AND fjs.jobstatuscode = e.job_status_code THEN fjs.jobstatuscode ELSE '-' END fjs , per.period_name_#request.scookie.lang# AS formname, per.reference_date AS formdate:date,CONVERT (VARCHAR(10),PER.reference_date,120) AS refdate, ( SELECT TOP 1 req.req_no FROM tcltrequest req LEFT JOIN tpmdperformance_evalgen eh ON eh.req_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' WHERE eh.period_code = per.period_code AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid and eh.period_code = per.period_code ORDER BY eh.modified_date DESC  ) AS reqno, CASE WHEN ( SELECT TOP 1 CASE WHEN req.req_no IS NOT NULL and eh.head_status = 1 THEN reqsts.name_#request.scookie.lang# ELSE CASE WHEN req.req_no IS NOT NULL and eh.head_status = 0 THEN 'Draft' ELSE 'Not Requested' END END reqstatus FROM tcltrequest req left JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC ) IS NULL THEN 'Unverified' ELSE ( SELECT TOP 1 CASE WHEN req.req_no IS NOT NULL and eh.head_status = 1 THEN reqsts.name_#request.scookie.lang# ELSE CASE WHEN req.req_no IS NOT NULL and eh.head_status = 0 THEN 'Draft' ELSE 'Not Requested' END END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC ) END AS reqstatus, ( SELECT TOP 1 eh.isfinal FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC  ) AS isfinal, ( SELECT TOP 1 eh.modified_date FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC ) AS modified_date, ( SELECT TOP 1 eh.form_no FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC  ) AS formno, ( SELECT TOP 1 eh.score FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC  ) AS score1, ( select TOP 1 p2.full_name from TCLTREQUEST REQ inner join tpmdperformance_evalh eh ON EH.request_no = REQ.req_no AND REQ.req_type = 'PERFORMANCE.EVALUATION' inner join TEOMEMPPERSONAL P2 on P2.emp_id = EH.lastreviewer_empid where eh.period_code = per.period_code and REQ.reqemp = E.emp_id AND eh.reviewee_empid = e.emp_id order by eh.MODIFIED_DATE desc  ) AS lastreviewer, 'Org Unit Objective' AS linkorg, ( SELECT TOP 1 ef.final_conclusion FROM tpmdperformance_final ef INNER JOIN tpmdperformance_evalh eh ON ef.form_no = eh.form_no AND ef.company_code = eh.company_code WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ) AS final_conclusion, ( SELECT TOP 1 CASE WHEN eh.isfinal = 1 THEN ef.final_conclusion ELSE '' END AS conclusion FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no INNER JOIN tpmdperformance_final ef ON ef.form_no = eh.form_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code ) AS conclusion, ( SELECT TOP 1 CASE WHEN eh.isfinal = 1 AND len(eh.conclusion) <> 0 THEN round(eh.score, 2) ELSE NULL END AS score FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC ) AS score, ( SELECT TOP 1 CASE WHEN ph.form_no is not null THEN ph.form_no ELSE NULL END AS planformno FROM tcltrequest plr INNER JOIN tpmdperformance_evalgen ph ON ph.req_no = plr.req_no AND plr.req_type = 'PERFORMANCE.EVALUATION'  AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC ) AS planformno, ( SELECT TOP 1 plr.req_no FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.period_code = per.period_code  ) AS planreqno, per.final_startdate, per.final_enddate, ( SELECT TOP 1 eh2.score AS score2 FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC  ) AS score2, ( SELECT TOP 1 eh2.reviewer_empid AS reviewer_empid FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC  ) AS reviewer_empid, ( SELECT TOP 1 round(eh2.score, 2) AS loginscore FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC ) AS loginscore, ( SELECT TOP 1 eh2.conclusion AS loginconclusion FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC ) AS loginconclusion, ( SELECT count(b.form_no) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id ) AS row_number, ( SELECT max(b.modified_date) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id ) AS max_modified_date">
                        <cfelse>
			                <cfset LOCAL.lsField="e.company_id, p.full_name AS emp_name, e.emp_id, e.emp_no, '-' AS reqapporder, pos.pos_name_#request.scookie.lang# AS emp_pos, dep.pos_name_#request.scookie.lang# dept, pos.position_id, e.employ_code, e.job_status_code, es.employmentstatus_name_#request.scookie.lang# AS status, per.period_code AS periodcode, CASE WHEN jfl.period_code IS NULL AND per.period_code = jfl.period_code OR jfl.emp_id IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( p.period_code IN ( SELECT DISTINCT period_code FROM tpmrperiodfilterjflcode ) ) ) THEN '-' ELSE per.period_code END jfl_per , CASE WHEN jfl.emp_id IS NOT NULL AND jfl.emp_id = e.emp_id THEN jfl.emp_id ELSE '-' END jfl , CASE WHEN fec.period_code IS NULL AND per.period_code = fec.period_code OR fec.employmentstatus_code IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( p.period_code IN ( SELECT period_code FROM tpmrperiodfilteremploycode group by period_code ) ) ) THEN '-' ELSE per.period_code END emcod_per , CASE WHEN fec.employmentstatus_code IS NOT NULL AND fec.employmentstatus_code = e.employ_code THEN fec.employmentstatus_code ELSE '-' END emcod , CASE WHEN fjs.period_code IS NULL AND per.period_code = fjs.period_code OR fjs.jobstatuscode IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( p.period_code IN ( SELECT  period_code FROM tpmrperiodfilterjobstatuscode group by period_code ) ) ) THEN '-' ELSE per.period_code END fjs_per , CASE WHEN fjs.jobstatuscode IS NOT NULL AND fjs.jobstatuscode = e.job_status_code THEN fjs.jobstatuscode ELSE '-' END fjs , per.period_name_#request.scookie.lang# AS formname, per.reference_date AS formdate:date, CONVERT ( per.reference_date, char(10) ) AS refdate, ( SELECT req.req_no FROM tcltrequest req LEFT JOIN tpmdperformance_evalgen eh ON eh.req_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' WHERE eh.period_code = per.period_code AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid and eh.period_code = per.period_code ORDER BY eh.modified_date DESC limit 1 ) AS reqno, CASE WHEN ( SELECT CASE WHEN req.req_no IS NOT NULL and eh.head_status = 1 THEN reqsts.name_#request.scookie.lang# ELSE CASE WHEN req.req_no IS NOT NULL and eh.head_status = 0 THEN 'Draft' ELSE 'Not Requested' END END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC limit 1 ) IS NULL THEN 'Unverified' ELSE ( SELECT CASE WHEN req.req_no IS NOT NULL and eh.head_status = 1 THEN reqsts.name_#request.scookie.lang# ELSE CASE WHEN req.req_no IS NOT NULL and eh.head_status = 0 THEN 'Draft' ELSE 'Not Requested' END END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC limit 1 ) END AS reqstatus, ( SELECT eh.isfinal FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS isfinal, ( SELECT eh.modified_date FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS modified_date, ( SELECT eh.form_no FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS formno, ( SELECT eh.score FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS score1, ( select p2.full_name from TCLTREQUEST REQ inner join tpmdperformance_evalh eh ON EH.request_no = REQ.req_no AND REQ.req_type = 'PERFORMANCE.EVALUATION' inner join TEOMEMPPERSONAL P2 on P2.emp_id = EH.lastreviewer_empid where eh.period_code = per.period_code and REQ.reqemp = E.emp_id AND eh.reviewee_empid = e.emp_id order by eh.MODIFIED_DATE desc limit 1 ) AS lastreviewer, 'Org Unit Objective' AS linkorg, ( SELECT ef.final_conclusion FROM tpmdperformance_final ef INNER JOIN tpmdperformance_evalh eh ON ef.form_no = eh.form_no AND ef.company_code = eh.company_code WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code limit 1 ) AS final_conclusion, ( SELECT CASE WHEN eh.isfinal = 1 THEN ef.final_conclusion ELSE '' END AS conclusion FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no INNER JOIN tpmdperformance_final ef ON ef.form_no = eh.form_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code limit 1 ) AS conclusion, ( SELECT CASE WHEN eh.isfinal = 1 AND length(eh.conclusion) <> 0 THEN round(eh.score, 2) ELSE NULL END AS score FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC limit 1 ) AS score, ( SELECT CASE WHEN ph.form_no is not null THEN ph.form_no ELSE NULL END AS planformno FROM tcltrequest plr INNER JOIN tpmdperformance_evalgen ph ON ph.req_no = plr.req_no AND plr.req_type = 'PERFORMANCE.EVALUATION'  AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC limit 1 ) AS planformno, ( SELECT plr.req_no FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC limit 1 ) AS planreqno, per.final_startdate, per.final_enddate, ( SELECT eh2.score AS score2 FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC limit 1 ) AS score2, ( SELECT eh2.reviewer_empid AS reviewer_empid FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC limit 1 ) AS reviewer_empid, ( SELECT round(eh2.score, 2) AS loginscore FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC limit 1 ) AS loginscore, ( SELECT eh2.conclusion AS loginconclusion FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC limit 1 ) AS loginconclusion, ( SELECT count(b.form_no) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id ) AS row_number, ( SELECT max(b.modified_date) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id ) AS max_modified_date">
			               
				        </cfif>
				    <cfelse>
                        <cfif request.dbdriver eq "MSSQL">
                              <cfset LOCAL.lsField="e.company_id, p.full_name AS emp_name, e.emp_id, e.emp_no, '-' AS reqapporder, pos.pos_name_#request.scookie.lang# AS emp_pos, dep.pos_name_#request.scookie.lang# dept, pos.position_id, e.employ_code, e.job_status_code, es.employmentstatus_name_#request.scookie.lang# AS status, per.period_code AS periodcode, CASE WHEN jfl.period_code IS NULL AND per.period_code = jfl.period_code OR jfl.emp_id IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p INNER JOIN tpmrperiodfilterjflcode aa ON aa.period_code = p.period_code WHERE aa.company_code = '#request.scookie.cocode#') THEN '-' ELSE per.period_code END jfl_per , CASE WHEN jfl.emp_id IS NOT NULL AND jfl.emp_id = e.emp_id THEN jfl.emp_id ELSE '-' END jfl , CASE WHEN fec.period_code IS NULL AND per.period_code = fec.period_code OR fec.employmentstatus_code IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( p.period_code IN ( SELECT period_code FROM tpmrperiodfilteremploycode WHERE company_code = '#request.scookie.cocode#' group by period_code ) ) ) THEN '-' ELSE per.period_code END emcod_per , CASE WHEN fec.employmentstatus_code IS NOT NULL AND fec.employmentstatus_code = e.employ_code THEN fec.employmentstatus_code ELSE '-' END emcod , CASE WHEN fjs.period_code IS NULL AND per.period_code = fjs.period_code OR fjs.jobstatuscode IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( p.period_code IN ( SELECT  period_code FROM tpmrperiodfilterjobstatuscode WHERE company_code = '#request.scookie.cocode#' group by period_code ) ) ) THEN '-' ELSE per.period_code END fjs_per , CASE WHEN fjs.jobstatuscode IS NOT NULL AND fjs.jobstatuscode = e.job_status_code THEN fjs.jobstatuscode ELSE '-' END fjs , per.period_name_#request.scookie.lang# AS formname, per.reference_date AS formdate:date,CONVERT (VARCHAR(10),PER.reference_date,120) AS refdate, ( SELECT TOP 1 req.req_no FROM tcltrequest req LEFT JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' WHERE eh.period_code = per.period_code AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid and eh.period_code = per.period_code ORDER BY eh.modified_date DESC  ) AS reqno, CASE  WHEN        (           SELECT              TOP 1               CASE                 WHEN                    req.req_no IS NOT NULL                  THEN                    reqsts.name_#request.scookie.lang#                  ELSE                    'Not Requested'               END              reqstatus            FROM              tcltrequest req               INNER JOIN                 tpmdperformance_evalh eh                  ON eh.request_no = req.req_no                  AND req.req_type = 'PERFORMANCE.EVALUATION'               INNER JOIN                 tgemreqstatus reqsts                  ON req.status = reqsts.code            WHERE              req.reqemp = e.emp_id               AND req.reqemp = e.emp_id               AND req.company_id = #REQUEST.SCOOKIE.COID#               AND req.reqemp = eh.reviewee_empid               AND eh.period_code = per.period_code               AND EH.head_status = 0              AND EH.lastreviewer_empid = '#request.scookie.user.empid#'           ORDER BY              eh.modified_date DESC         )        IS NOT NULL      THEN        'Draft'      ELSE CASE WHEN ( SELECT TOP 1 CASE WHEN req.req_no IS NOT NULL THEN reqsts.name_#request.scookie.lang# ELSE 'Not Requested' END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC ) IS NULL THEN 'Not Requested' ELSE ( SELECT TOP 1 CASE WHEN req.req_no IS NOT NULL THEN reqsts.name_#request.scookie.lang# ELSE 'Not Requested' END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC ) END END AS reqstatus, ( SELECT TOP 1 eh.isfinal FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC  ) AS isfinal, ( SELECT TOP 1 eh.modified_date FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC ) AS modified_date, ( SELECT TOP 1 eh.form_no FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC  ) AS formno, ( SELECT TOP 1 eh.score FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC  ) AS score1, ( select TOP 1 p2.full_name from TCLTREQUEST REQ inner join tpmdperformance_evalh eh ON EH.request_no = REQ.req_no AND REQ.req_type = 'PERFORMANCE.EVALUATION' inner join TEOMEMPPERSONAL P2 on P2.emp_id = EH.lastreviewer_empid where eh.period_code = per.period_code and REQ.reqemp = E.emp_id AND eh.reviewee_empid = e.emp_id order by eh.MODIFIED_DATE desc  ) AS lastreviewer, 'Org Unit Objective' AS linkorg, ( SELECT TOP 1 ef.final_conclusion FROM tpmdperformance_final ef INNER JOIN tpmdperformance_evalh eh ON ef.form_no = eh.form_no AND ef.company_code = eh.company_code WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ) AS final_conclusion, ( SELECT TOP 1 CASE WHEN eh.isfinal = 1 THEN ef.final_conclusion ELSE '' END AS conclusion FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no INNER JOIN tpmdperformance_final ef ON ef.form_no = eh.form_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code ) AS conclusion, ( SELECT TOP 1 CASE WHEN eh.isfinal = 1 AND len(eh.conclusion) <> 0 THEN round(eh.score, 2) ELSE NULL END AS score FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC ) AS score, ( SELECT TOP 1 CASE WHEN plr.status IN ( 3, 9 ) THEN ph.form_no ELSE NULL END AS planformno FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC ) AS planformno, ( SELECT TOP 1 plr.req_no FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.period_code = per.period_code  ) AS planreqno, per.final_startdate, per.final_enddate, ( SELECT TOP 1 eh2.score AS score2 FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC  ) AS score2, ( SELECT TOP 1 eh2.reviewer_empid AS reviewer_empid FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC  ) AS reviewer_empid, ( SELECT TOP 1 round(eh2.score, 2) AS loginscore FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC ) AS loginscore, ( SELECT TOP 1 eh2.conclusion AS loginconclusion FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC ) AS loginconclusion, ( SELECT count(b.form_no) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id ) AS row_number, ( SELECT max(b.modified_date) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id ) AS max_modified_date">
                        <cfelse>
			                <cfset LOCAL.lsField="e.company_id, p.full_name AS emp_name, e.emp_id, e.emp_no, '-' AS reqapporder, pos.pos_name_#request.scookie.lang# AS emp_pos, dep.pos_name_#request.scookie.lang# dept, pos.position_id, e.employ_code, e.job_status_code, es.employmentstatus_name_#request.scookie.lang# AS status, per.period_code AS periodcode, CASE WHEN jfl.period_code IS NULL AND per.period_code = jfl.period_code OR jfl.emp_id IS NULL AND per.period_code NOT IN (SELECT period_code FROM  tpmrperiodfilterjflcode aa WHERE aa.company_code = '#request.scookie.cocode#' )THEN '-' ELSE per.period_code END jfl_per , CASE WHEN jfl.emp_id IS NOT NULL AND jfl.emp_id = e.emp_id THEN jfl.emp_id ELSE '-' END jfl , CASE WHEN fec.period_code IS NULL AND per.period_code = fec.period_code OR fec.employmentstatus_code IS NULL AND per.period_code NOT IN (SELECT cc.period_code FROM tpmrperiodfilteremploycode cc WHERE cc.company_code='#request.scookie.cocode#' group by period_code) THEN '-' ELSE per.period_code END emcod_per , CASE WHEN fec.employmentstatus_code IS NOT NULL AND fec.employmentstatus_code = e.employ_code THEN fec.employmentstatus_code ELSE '-' END emcod , CASE WHEN fjs.period_code IS NULL AND per.period_code = fjs.period_code OR fjs.jobstatuscode IS NULL AND per.period_code NOT IN (SELECT bb.period_code FROM tpmrperiodfilterjobstatuscode bb where bb.company_code ='#request.scookie.cocode#' group by period_code) THEN '-' ELSE per.period_code END fjs_per , CASE WHEN fjs.jobstatuscode IS NOT NULL AND fjs.jobstatuscode = e.job_status_code THEN fjs.jobstatuscode ELSE '-' END fjs , per.period_name_#request.scookie.lang# AS formname, per.reference_date AS formdate:date, CONVERT ( per.reference_date, char(10) ) AS refdate, ( SELECT req.req_no FROM tcltrequest req LEFT JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' WHERE eh.period_code = per.period_code AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid and eh.period_code = per.period_code ORDER BY eh.modified_date DESC limit 1 ) AS reqno, CASE  WHEN        (           SELECT    CASE        WHEN       req.req_no IS NOT NULL       THEN              reqsts.name_#request.scookie.lang#   ELSE                    'Not Requested'        END    reqstatus   FROM   tcltrequest req               INNER JOIN                 tpmdperformance_evalh eh                  ON eh.request_no = req.req_no                  AND req.req_type = 'PERFORMANCE.EVALUATION'               INNER JOIN                 tgemreqstatus reqsts                  ON req.status = reqsts.code            WHERE              req.reqemp = e.emp_id               AND req.reqemp = e.emp_id               AND req.company_id = #REQUEST.SCOOKIE.COID#               AND req.reqemp = eh.reviewee_empid               AND eh.period_code = per.period_code               AND EH.head_status = 0              AND EH.lastreviewer_empid = '#request.scookie.user.empid#'           ORDER BY              eh.modified_date DESC     limit 1    )        IS NOT NULL      THEN        'Draft'      ELSE CASE WHEN ( SELECT CASE WHEN req.req_no IS NOT NULL THEN reqsts.name_#request.scookie.lang# ELSE 'Not Requested' END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC limit 1 ) IS NULL THEN 'Not Requested' ELSE ( SELECT CASE WHEN req.req_no IS NOT NULL THEN reqsts.name_#request.scookie.lang# ELSE 'Not Requested' END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC limit 1 ) END END AS reqstatus, ( SELECT eh.isfinal FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS isfinal, ( SELECT eh.modified_date FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS modified_date, ( SELECT eh.form_no FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS formno, ( SELECT eh.score FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS score1, ( select p2.full_name from TCLTREQUEST REQ inner join tpmdperformance_evalh eh ON EH.request_no = REQ.req_no AND REQ.req_type = 'PERFORMANCE.EVALUATION' inner join TEOMEMPPERSONAL P2 on P2.emp_id = EH.lastreviewer_empid where eh.period_code = per.period_code and REQ.reqemp = E.emp_id AND eh.reviewee_empid = e.emp_id order by eh.MODIFIED_DATE desc limit 1 ) AS lastreviewer, 'Org Unit Objective' AS linkorg, ( SELECT ef.final_conclusion FROM tpmdperformance_final ef INNER JOIN tpmdperformance_evalh eh ON ef.form_no = eh.form_no AND ef.company_code = eh.company_code WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code limit 1 ) AS final_conclusion, ( SELECT CASE WHEN eh.isfinal = 1 THEN ef.final_conclusion ELSE '' END AS conclusion FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no INNER JOIN tpmdperformance_final ef ON ef.form_no = eh.form_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code limit 1 ) AS conclusion, ( SELECT CASE WHEN eh.isfinal = 1 AND length(eh.conclusion) <> 0 THEN round(eh.score, 2) ELSE NULL END AS score FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC limit 1 ) AS score, ( SELECT CASE WHEN plr.status IN ( 3, 9 ) THEN ph.form_no ELSE NULL END AS planformno FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC limit 1 ) AS planformno, ( SELECT plr.req_no FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC limit 1 ) AS planreqno, per.final_startdate, per.final_enddate, ( SELECT eh2.score AS score2 FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC limit 1 ) AS score2, ( SELECT eh2.reviewer_empid AS reviewer_empid FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC limit 1 ) AS reviewer_empid, ( SELECT round(eh2.score, 2) AS loginscore FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC limit 1 ) AS loginscore, ( SELECT eh2.conclusion AS loginconclusion FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id ORDER BY eh2.modified_date DESC limit 1 ) AS loginconclusion, ( SELECT count(b.form_no) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id ) AS row_number, ( SELECT max(b.modified_date) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id ) AS max_modified_date">
			           
			            </cfif>
				    
				    </cfif>
			    
					<cfset LOCAL.lsTable="TEODEMPCOMPANY E INNER JOIN TEOMEMPPERSONAL P ON P.emp_id = E.emp_id  INNER JOIN TEOMPOSITION POS ON POS.position_id = E.position_id AND POS.company_id = E.company_id INNER JOIN TEOMPOSITION DEP ON DEP.position_id = POS.parent_id AND DEP.company_id = POS.company_id INNER JOIN TEOMEMPLOYMENTSTATUS ES ON ES.employmentstatus_code = E.employ_code INNER JOIN TPMMPERIOD PER ON PER.company_code = '#request.scookie.cocode#' LEFT JOIN view_jfl JFL ON JFL.period_code = PER.period_code and JFL.EMP_ID = E.EMP_ID and JFL.position_id = E.position_id LEFT JOIN TPMRPERIODFILTEREMPLOYCODE FEC ON PER.PERIOD_CODE = FEC.period_code AND FEC.employmentstatus_code = E.employ_code LEFT JOIN TPMRPERIODFILTERJOBSTATUSCODE FJS ON FJS.PERIOD_CODE = PER.period_code AND FJS.jobstatuscode = E.job_status_code">
					<cfset LOCAL.lsFilter="company_id={COID}  AND (final_startdate <= '#inp_enddt#' AND final_enddate >= '#inp_startdt#') AND (( JFL_PER <> '-' AND JFL = EMP_ID) OR (JFL_PER = '-')) AND ((EMCOD_PER <> '-' AND EMCOD = employ_code) OR (EMCOD_PER ='-')) AND ((FJS_PER <> '-' AND FJS = job_status_code) OR (FJS_PER ='-'))">
					
					<cfif request.scookie.cocode neq "issid">
						<cfif not structkeyexists(StrckTemp,"qLookup")>
						
						<cfelse>
							<cfset LOCAL.qTemp = StrckTemp.qLookup>
							<cfif qTemp.recordcount>
								<cfset lsFilter=lsFilter & " AND emp_id IN (#quotedvaluelist(qTemp.nval)#)">
							<cfelse>
								<cfset lsFilter=lsFilter & " AND emp_id IN ('')">
							</cfif>
						</cfif>
					<cfelse>
							<cfset LOCAL.qTemp = getEmpListing(inp_startdt=inp_startdt,inp_enddt=inp_enddt,ReturnVarCheckCompParam=ReturnVarCheckCompParam)>
							<cfif qTemp.recordcount>
								<cfset lsFilter=lsFilter & " AND emp_id IN (#quotedvaluelist(qTemp.emp_id)#)">
							<cfelse>
								<cfset lsFilter=lsFilter & " AND emp_id IN ('')">
							</cfif>
					</cfif>
					
				
				
				<cfset lsFilter=lsFilter & " and (isfinal=1 or isfinal is null or isfinal <> 1)">
				<cfif ReturnVarCheckCompParam eq true>
				    	<cfset lsFilter=lsFilter & " and ((max_modified_date IS null AND row_number = 0) OR (max_modified_date is not null AND row_number > 0)) and ((planformno <> '') OR (FORMNO <> ''))">
				<cfelse>
					<cfset lsFilter=lsFilter & " and ((max_modified_date IS null AND row_number = 0) OR (max_modified_date is not null AND row_number > 0)) ">
				</cfif>
			
				<cfif request.scookie.cocode neq "issid">
					<cfif len(StrckTemp.filterTambahan)>
						<cfset lsFilter=lsFilter & " #StrckTemp.filterTambahan#">
					</cfif>
				</cfif>
				
				<cfif structkeyexists(scParam,"emp_pos")>
					<cfset lsFilter=lsFilter & " AND emp_pos LIKE '%#scParam.emp_pos#%'">
					<cfset StructDelete(scParam,"emp_pos")>
				</cfif>
				<cfif structkeyexists(scParam,"conclusion")>
					<cfset lsFilter=lsFilter & " AND 1 = CASE WHEN isfinal = 1 AND final_conclusion LIKE '%#scParam.conclusion#%' THEN 1 ELSE 0 END">
					<cfset StructDelete(scParam,"conclusion")>
				</cfif>
				<cfif structkeyexists(scParam,"score")>
					<cfset lsFilter=lsFilter & " AND 1 = CASE WHEN isfinal = 1 AND LEN(final_conclusion) <> 0 AND Str(score1, 10, 3) LIKE '%#scParam.score#%' THEN 1 ELSE 0 END">
					<cfset StructDelete(scParam,"score")>
				</cfif>
				<cfif structkeyexists(scParam,"loginconclusion")>
					<cfset lsFilter=lsFilter & " AND 1 = CASE WHEN loginconclusion LIKE '%#scParam.loginconclusion#%' AND reviewer_empid = '#request.scookie.user.empid#' THEN 1 ELSE 0 END">
					<cfset StructDelete(scParam,"loginconclusion")>
				</cfif>
				<cfif structkeyexists(scParam,"loginscore")>
					<cfset lsFilter=lsFilter & " AND 1 = CASE WHEN Str(score2, 10, 2) LIKE '%#scParam.loginscore#%' AND reviewer_empid = '#request.scookie.user.empid#' THEN 1 ELSE 0 END">
					<cfset StructDelete(scParam,"loginscore")>
				</cfif>
				<cfset ListingData(scParam,{fsort='emp_name,emp_no, formdate ,formname',lsField=lsField,lsTable=lsTable,lsFilter=lsFilter,pid="E.emp_id"})>
				
			   
		</cffunction> 
		
		
		<cffunction name="listingFilter">	
		    <cfargument name="fromInbox" default="false">    
			<cfparam name="search" default="">
			<cfparam name="getval" default="id">
			<cfparam name="autopick" default="">
			<cfparam name="jsfunc" default="null">
            <cfparam name="inp_startdt" default="">
            <cfparam name="inp_enddt" default="">
            <cfif request.dbdriver eq "MYSQL">
                <cfset LOCAL.nowdate= DATEFORMAT(CreateDate(Datepart('yyyy',now()),Datepart('m',now()),Datepart('d',now())),'yyyy-mm-dd')>
            <cfelseif request.dbdriver eq "MSSQL">
                <cfset LOCAL.nowdate= DATEFORMAT(CreateDate(Datepart('yyyy',now()),Datepart('m',now()),Datepart('d',now())),'mm/dd/yyyy')>
            </cfif>
            <cfif inp_startdt eq "">
                <cfset inp_startdt= DATEFORMAT(CreateDate(Datepart("yyyy",inp_startdt),Datepart("m",inp_startdt),Datepart("d",inp_startdt)),"yyyy-mm-dd")>
            </cfif>
            <cfif inp_enddt eq "">
                <cfset inp_enddt= DATEFORMAT(CreateDate(Datepart("yyyy",inp_enddt),Datepart("m",inp_enddt),Datepart("d",inp_enddt)),"yyyy-mm-dd")>
            </cfif>
	
			<cfset LOCAL.searchText=trim(search)>
			<cfset LOCAL.ObjectApproval="PERFORMANCE.Evaluation">
			<cfset LOCAL.lsValidEmp_id = "">
			<cfset LOCAL.ReqAppOrder = "-">
			<cfset LOCAL.retType = "sql">
			<cfset LOCAL.retType = "lsempid">
			<cfset LOCAL.strFilterReqFor = "">
			<cfset LOCAL.arrSqlReqFor= ArrayNew(1) /> 
			<cfset LOCAL.arrsubsql = ArrayNew(1) />
			<cfset LOCAL.arrRevWrd = ArrayNew(1) />
			<cfset LOCAL.isFltEndDt=true />
			<cfset local.strckReturn = structnew()>
            <cfset strckReturn.filterTambahan = "">
			<cfif structkeyexists(REQUEST,"SHOWCOLUMNGENERATEPERIOD")>
				<cfset local.ReturnVarCheckCompParam = REQUEST.SHOWCOLUMNGENERATEPERIOD>
			<cfelse>
				<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
			</cfif>
			<cfif autopick eq "" OR autopick eq "yes"><!---Lookup onSearch or onBlur.--->
				<cfquery name="LOCAL.qReqUSelf" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
					SELECT field_name,field_value
					FROM TCLCAPPCOMPANY 
					WHERE module='Workflow' 
					AND (field_code = 'exrequself' AND ',' #REQUEST.DBSTRCONCAT# field_value #REQUEST.DBSTRCONCAT# ',' like '%,#LOCAL.ObjectApproval#,%')
					AND company_id = <cfqueryparam value="#REQUEST.scookie.COID#" cfsqltype="CF_SQL_INTEGER"/>
				</cfquery>
				<cfif ReturnVarCheckCompParam eq true>
					<cfset ReqAppOrder = "-">
					<cfquery name="local.qGetFromEvalGen" datasource="#request.sdsn#">
						select distinct reviewee_empid from tpmdperformance_evalgen where reviewer_empid = '#REQUEST.SCookie.User.empid#'
					</cfquery>
					<cfif qGetFromEvalGen.recordcount gt 0 >
						<cfset lsValidEmp_id = ValueList(qGetFromEvalGen.reviewee_empid)>
					</cfif>
				<cfelse> 
					<!-- if not pregenerate ---->
					<cfset LOCAL.Requester = Application.SFDB.RunQuery("SELECT * FROM VIEW_EMPLOYEE WHERE emp_id = ? AND company_id = ?", [[REQUEST.SCookie.User.EMPID, "CF_SQL_VARCHAR"],[REQUEST.scookie.COID, "CF_SQL_INTEGER"]]).QueryRecords/>
					<cfif APPLICATION.CFMLENGINE neq "Railo">
						<cfif not cacheRegionExists("inpRequestFor")>
							<cfset cacheRegionNew("inpRequestFor")>
						</cfif>
						<cfset LOCAL.scQAttr={cacheregion="inpRequestFor"}>
					<cfelse>
						<cfset LOCAL.scQAttr={}>
					</cfif>
					<cfset LOCAL.strUdrScr=(request.dbdriver eq "MYSQL"?"\_":"_")>
					<cfset LOCAL.filterFrmlSet="request_approval_formula like '%"&replacenocase("EMP_"&requester.emp_no,"_",strUdrScr,"ALL")& "%' ">
					<cfset filterFrmlSet &= " OR request_approval_formula like '%"&replacenocase("EMP_CUSTOMFIELD","_",strUdrScr,"ALL")& "%' ">
					<cfset filterFrmlSet &= " OR request_approval_formula like '%"&replacenocase("POS_CUSTOMFIELD","_",strUdrScr,"ALL")& "%' ">
					<cfif len(requester.pos_code)>
						<cfset filterFrmlSet &= "OR request_approval_formula like '%"&replacenocase("POS_"&requester.pos_code,"_",strUdrScr,"ALL")& "%' ">
					</cfif>
					<cftry> 
						<cfquery name="qnewassig" datasource="#request.sdsn#">
							SELECT emp_id, position_code FROM TCALNEWASSIGNMENT WHERE emp_id = '#requester.emp_id#'
						</cfquery>
						<cfif qnewassig.recordcount gt 0>
							<cfset filterFrmlSet &= "OR request_approval_formula like '%"&replacenocase("POS_"&qnewassig.position_code,"_",strUdrScr,"ALL")& "%' ">
						</cfif>
						<cfcatch></cfcatch>
					</cftry>
					<cfloop list="spv,mgr" index="LOCAL.idxspvmgr">
						<cfloop list="'',/,+" index="LOCAL.idxprefrm">
							<cfset filterFrmlSet &= " OR request_approval_formula like '%"&idxprefrm&idxspvmgr&"%'">
						</cfloop>
					</cfloop>
					<cfquery name="LOCAL.qReserveWordSet" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
						SELECT reserve_word_code FROM TSFMREQAPPRSRVWORD
					</cfquery>
					<cfloop query="qReserveWordSet">
						<cfset filterFrmlSet &= " OR request_approval_formula like '%"&replacenocase(qReserveWordSet.reserve_word_code,"_",strUdrScr,"ALL")&"%'">
					</cfloop>
						<cfloop condition="ListLen(LOCAL.ObjectApproval, '.') GT 0"><!---loop if LOCAL.ObjectApproval is len--->
							<cfquery name="LOCAL.qRequestApprovalOrder" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
								SELECT seq_id,
										req_order,
										request_approval_name,
										request_approval_formula,
										requester fltrequester,
										requestee fltrequestee
								FROM	TCLCReqAppSetting
								WHERE	company_id = <cfqueryparam value="#REQUEST.scookie.COID#" cfsqltype="CF_SQL_INTEGER"/>
									AND request_approval_code = <cfqueryparam value="#LOCAL.ObjectApproval#" cfsqltype="CF_SQL_VARCHAR">
									<cfif request.dbdriver eq "ORACLE">
										AND (requester IS not NULL OR requestee is not null)
									<cfelse>
										AND (requester <> '' OR requestee <> '')
									</cfif>
									AND (<cfif len(filterFrmlSet)>#PreserveSingleQuotes(filterFrmlSet)#</cfif>)
								ORDER BY request_approval_code DESC, req_order DESC, requester DESC, requestee DESC
							</cfquery>
							
							<cfloop query="qRequestApprovalOrder">
								<cftry>
								<cfset LOCAL.lstRequestee = "" />
								<cfset LOCAL.sqlRequestee = "" />
								<cfset LOCAL.sqlRequester = "" />
								<cfset LOCAL.fltrRequesteeTemp = "" />
								<cfif qRequestApprovalOrder.fltrequestee neq "" AND qRequestApprovalOrder.fltrequestee neq "[GENERAL]">
									<!---this Custom Code based on generate function[need coheren process with request approval setting origin]--->
									<!---<cfset qRequestApprovalOrder.fltrequestee = REReplace(qRequestApprovalOrder.fltrequestee, "'male'",1, "ALL") />
									<cfset qRequestApprovalOrder.fltrequestee = REReplace(qRequestApprovalOrder.fltrequestee, "'female'",0, "ALL") />
									
									<cfquery name="LOCAL.qCekRequestee" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
										SELECT	emp_id
										FROM	VIEW_EMPLOYEE
										WHERE	#PreserveSingleQuotes(qRequestApprovalOrder.fltrequestee)#
									</cfquery>
									<cfset lstRequestee = ValueList(qCekRequestee.emp_id) />--->
									<cfset LOCAL.sqlRequestee = REReplace(REReplace(qRequestApprovalOrder.fltrequestee, "'male'",1, "ALL"), "'female'",0, "ALL") />
									<cftry>
										<cfset fltrRequesteeTemp = "SELECT VE.emp_id FROM VIEW_EMPLOYEE VE WHERE " & LOCAL.sqlRequestee />
										<cfset LOCAL.sqlRequestee = Evaluate(DE(LOCAL.sqlRequestee)) />
										<cfif retType eq "sql">
											<cfquery name="LOCAL.qCekRequestee" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#" attributeCollection=#scQAttr#>
												SELECT emp_id FROM VIEW_EMPLOYEE WHERE 1=0 AND (#PreserveSingleQuotes(LOCAL.sqlRequestee)#)
											</cfquery>
										<cfelse>
											<cfquery name="LOCAL.qCekRequestee" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#" attributeCollection=#scQAttr#>
												SELECT emp_id FROM VIEW_EMPLOYEE WHERE (#PreserveSingleQuotes(LOCAL.sqlRequestee)#)
											</cfquery>
											<cfset lstRequestee = ValueList(qCekRequestee.emp_id) />
										</cfif>
									<cfcatch>
										<cfset LOCAL.sqlRequestee = ""/>
										<cfset fltrRequesteeTemp = ""/>
										<cfif isdefined("URL.devdmp")>
											<cfdump var="#cfcatch#" label="cfcatch">
										</cfif>
										<cfcontinue>
									</cfcatch>
									</cftry>
								</cfif>
								<cfset LOCAL.procValidEmp_id=false />
								<cfif qRequestApprovalOrder.fltrequester neq "" AND qRequestApprovalOrder.fltrequester neq "[GENERAL]">
									<!---this Custom Code based on generate function[need coheren process with request approval setting origin]--->
									<!---<cfset qRequestApprovalOrder.fltrequester = REReplace(qRequestApprovalOrder.fltrequester, "'male'",1, "ALL") />
									<cfset qRequestApprovalOrder.fltrequester = REReplace(qRequestApprovalOrder.fltrequester, "'female'",0, "ALL") />
									<cfquery name="LOCAL.qCekRequester" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
										SELECT	emp_id 
										FROM	VIEW_EMPLOYEE
										WHERE	emp_id = <cfqueryparam value="#REQUEST.SCookie.User.EMPID#" cfsqltype="CF_SQL_VARCHAR"> AND
												#PreserveSingleQuotes(qRequestApprovalOrder.fltrequester)#
									</cfquery>

									<cfif qCekRequester.RecordCount>
										<cfset procValidEmp_id=true />
									</cfif>--->
									<cfset LOCAL.sqlRequester = REReplace(REReplace(qRequestApprovalOrder.fltrequester, "'male'",1, "ALL"), "'female'",0, "ALL") />
									<cftry>
										<!---<cfset LOCAL.sqlRequester = qRequestApprovalOrder.fltrequester />--->
										<cfset LOCAL.sqlRequester = Evaluate(DE(LOCAL.sqlRequester)) />
										<cfquery name="LOCAL.qCekRequester" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#" attributeCollection=#scQAttr#>
											SELECT emp_id FROM VIEW_EMPLOYEE 
											WHERE emp_id = <cfqueryparam value="#REQUEST.SCookie.User.EMPID#" cfsqltype="CF_SQL_VARCHAR">
												AND (#PreserveSingleQuotes(LOCAL.sqlRequester)#)
										</cfquery>
										<cfif qCekRequester.RecordCount>
											<cfset procValidEmp_id=true />
										<cfelse>
											<cfcontinue>
										</cfif>
										<cfcatch>
											<cfif isdefined("URL.devdmp")>
												<cfdump var="#cfcatch#" label="cfcatch">
											</cfif>
											<cfcontinue>
										</cfcatch>
									</cftry>
								<cfelse>
									<cfset procValidEmp_id=true />
								</cfif>
								<cfif procValidEmp_id>
									<!---<cfset LOCAL.arrEmployee = objRequestApproval.GetEmployeeFromFormula(strRequestApprovalFormula=qRequestApprovalOrder.request_approval_formula, strEmpId=REQUEST.SCookie.User.EMPID, iEmpType=1,retType="lsempid") />--->
									<cfif retType eq "sql">
										<cfset LOCAL.arrEmployee = objRequestApproval.GetEmployeeFromFormula(qRequestApprovalOrder.request_approval_formula, REQUEST.SCookie.User.EMPID, 1, isFltEndDt, -1, retType,requester, requester) />
									<cfelse>
										<cfset LOCAL.arrEmployee = objRequestApproval.GetEmployeeFromFormula(qRequestApprovalOrder.request_approval_formula, REQUEST.SCookie.User.EMPID, 1, true, -1, retType,requester, requester) />
									</cfif>
									<cfif arrayLen(arrEmployee)>
										<cfif isdefined("URL.devdmp")>
											<cfdump var="#qRequestApprovalOrder.request_approval_formula#" label="formula">
										</cfif>
										<cfif retType eq "sql">
											<cfset ArrayAppend(LOCAL.arrSqlReqFor, {sqlRequestee=LOCAL.sqlRequestee,arrRevWrd=arrEmployee})/> 
										<cfelse>
											<cfset LOCAL.idxEmployee = "">
											<cfloop array="#arrEmployee#" index="idxEmployee">
												<cfif ListFind(lstRequestee, idxEmployee['emp_id']) or (qRequestApprovalOrder.fltrequestee eq "" or qRequestApprovalOrder.fltrequestee eq "[GENERAL]")>
													<cfif ListFind(lsValidEmp_id, idxEmployee['emp_id']) lt 1>
														<cfset lsValidEmp_id = ListAppend(lsValidEmp_id, idxEmployee['emp_id']) />
													</cfif>
												</cfif>
											</cfloop>
										</cfif>
									</cfif>
								</cfif>
								<cfif Len(lsValidEmp_id)>
									<cfset ReqAppOrder = qRequestApprovalOrder.req_order[currentrow]>
								</cfif>
								<cfcatch></cfcatch>
								</cftry>
							</cfloop>
							<cfbreak>
						</cfloop>
					<!-- end if not pregenerate ---->
				</cfif>
				
				
				
			</cfif>
			

			<cfif arguments.fromInbox>
				<cfreturn ReqAppOrder>
			<cfelse>
			<cfif retType eq "sql">
				<cfloop array="#LOCAL.arrSqlReqFor#" index="LOCAL.idxSqlReqFor">
					<cfset LOCAL.strrevwrd="">
					<cfset LOCAL.isallempcom = false>
					<cfset LOCAL.strSqlRequesteeTmp="">
					<cfif len(trim(idxSqlReqFor.sqlRequestee))>
						<cfset LOCAL.strSqlRequesteeTmp=" AND (#idxSqlReqFor.sqlRequestee#) ">
					</cfif>
					<cfloop array="#idxSqlReqFor.arrRevWrd#" index="LOCAL.idxsqlclrequestee">
						<cfif len(idxsqlclrequestee.revwrdsql)>
							<cfset LOCAL.strrevwrd = ListAppend(strrevwrd, " OR ((#idxsqlclrequestee.revwrdsql#) #strSqlRequesteeTmp#)"," ") />
						</cfif>
						<cfif listFIndNoCase("POS_,EMP_",idxsqlclrequestee.revwrdtype) and idxSqlReqFor.sqlRequestee eq "">
							<cfset LOCAL.strFilterReqFor = " #idxsqlclrequestee.revwrdsql# " />
							<cfset isallempcom = true>
							<cfbreak>
						</cfif>
					</cfloop>
					<cfif isallempcom>
						<cfbreak>
					</cfif>
					<cfif len(strrevwrd)>
						<cfset LOCAL.strFilterReqFor = ListAppend(LOCAL.strFilterReqFor, " OR (1=0 #strrevwrd#)"," ") />
						<!---<cfif len(idxSqlReqFor.sqlRequestee)>
							<cfset LOCAL.strFilterReqFor = ListAppend(LOCAL.strFilterReqFor, " OR ((1=0 #strrevwrd#) AND #idxSqlReqFor.sqlRequestee#)"," ") />
						<cfelse>
							<cfset LOCAL.strFilterReqFor = ListAppend(LOCAL.strFilterReqFor, " OR (1=0 #strrevwrd#)"," ") />
						</cfif>--->
					</cfif>
				</cfloop>
				<cfif len(LOCAL.strFilterReqFor)>
					<cfset LOCAL.isfieldtemp1 = UCase(requester.columnlist)>
					<cfset LOCAL.isfieldtemp2 = "E." & ReplaceNoCase(LOCAL.isfieldtemp1,",",",E.")>
					<cfset LOCAL.strFilterReqFor = ReplaceList(UCase(LOCAL.strFilterReqFor), LOCAL.isfieldtemp1, LOCAL.isfieldtemp2)>
				</cfif>
				<cfif isdefined("URL.devdmp")>
					<cfdump var="#LOCAL.arrSqlReqFor#" label="LOCAL.arrSqlReqFor">
					<cfdump var="#LOCAL.strFilterReqFor#" label="LOCAL.strFilterReqFor">
				</cfif>
			</cfif>
			
    		<cfif ListFind(lsValidEmp_id, REQUEST.SCookie.User.empid) lt 1>
    			<cfset lsValidEmp_id = ListAppend(lsValidEmp_id, REQUEST.SCookie.User.empid)/>
    		</cfif>
    
			<!----<cf_sfwritelog dump="lsValidEmp_id" prefix="lsValidEmp_idkedua"> ---->

			<cfquery name="local.qPeriod" datasource="#request.sdsn#">
    			select period_code from tpmmperiod where final_enddate >= '#inp_startdt#' AND final_startdate <= '#inp_enddt#'
    		</cfquery>
			    
           
		    	<cfif ReturnVarCheckCompParam eq true>
					 <cfquery name="local.qTempYan" datasource="#request.sdsn#">
						 SELECT reviewee_empid emp_id, 
						  period_code 
						FROM 
						  TPMDPERFORMANCE_EVALGEN EH 
						WHERE 
						  company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar"> 
						  AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
                            <cfif qPeriod.recordcount gt 0 and qPeriod.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriod.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                            </cfif>
						GROUP BY reviewee_empid, period_code
						UNION 
						SELECT 
						   EC.emp_id, 
						  EH.period_code 
						FROM 
						  TCLTREQUEST REQ LEFT JOIN TEODEMPCOMPANY EC ON ( EC.emp_id = REQ.reqemp  AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar"> )
						 
						  LEFT JOIN TPMDPERFORMANCE_EVALH EH ON EH.reviewee_empid = REQ.reqemp 
						  AND EH.request_no = REQ.req_no 
						 
						WHERE 
						  UPPER(REQ.req_type) = 'PERFORMANCE.EVALUATION' 
						  AND REQ.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						  AND (
							REQ.approval_list LIKE <cfqueryparam value="#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list = <cfqueryparam value="#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
						)
                        <cfif qPeriod.recordcount gt 0 and qPeriod.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriod.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                        </cfif>
						GROUP BY emp_id, period_code
					</cfquery>
					
				<cfelse>
					<cfquery name="local.qTempYan" datasource="#request.sdsn#">
					SELECT DISTINCT EC.emp_id,
						EH.period_code
					FROM TCLTREQUEST REQ
					LEFT JOIN TPMDPERFORMANCE_EVALH EH
						ON  EH.reviewee_empid = REQ.reqemp 
						AND EH.request_no = REQ.req_no
					LEFT JOIN TEODEMPCOMPANY EC ON EC.emp_id = REQ.reqemp
						AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
					WHERE UPPER(REQ.req_type) = 'PERFORMANCE.EVALUATION'
						AND REQ.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						AND (
							REQ.approval_list LIKE <cfqueryparam value="#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list = <cfqueryparam value="#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
						)
                        <cfif qPeriod.recordcount gt 0 and qPeriod.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriod.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                        </cfif>
					</cfquery>
			</cfif>
		
		   
    		<cfset local.caseDiffAppr = "">
            <cfset local.lstEmpDiffAppr = "">
           <!----<cf_sfwritelog dump="lsValidEmp_id" prefix="lsValidEmp_idketiga"> ---->
           <cfloop query="qTempYan">
            	<cfif ListFind(lsValidEmp_id, qTempYan.emp_id) lt 1>
    				<cfset lsValidEmp_id = ListAppend(lsValidEmp_id, qTempYan.emp_id)/>
                    <cfset lstEmpDiffAppr = ListAppend(lstEmpDiffAppr,qTempYan.emp_id)>
                    <cfquery name="LOCAL.getPeriodCodeEmpReq" dbtype="query"> <!---Tambahan replace approver--->
                        SELECT period_code FROM qTempYan 
                        WHERE EMP_ID = <cfqueryparam value="#qTempYan.emp_id#" cfsqltype="CF_SQL_VARCHAR"/>
					</cfquery>
					<cfif ReturnVarCheckCompParam eq true>
						<cfif qTempYan.emp_id neq "">
							<cfset caseDiffAppr = caseDiffAppr & "WHEN emp_id IN ('#qTempYan.emp_id#') AND periodcode IN (#getPeriodCodeEmpReq.recordcount neq 0 ? quotedvaluelist(getPeriodCodeEmpReq.period_code) : "'-'"#) THEN 1 ">
						</cfif>
						
					<cfelse>
					   <cfif qTempYan.emp_id neq "">
							<cfset caseDiffAppr = caseDiffAppr & "WHEN emp_id IN ('#qTempYan.emp_id#') OR periodcode IN (#getPeriodCodeEmpReq.recordcount neq 0 ? quotedvaluelist(getPeriodCodeEmpReq.period_code) : "'-'"#) THEN 1 ">
					   </cfif>
					</cfif>
    			</cfif>
            </cfloop>
            <cfif listlen(lstEmpDiffAppr)>
    	        <cfset lstEmpDiffAppr = ListQualify(lstEmpDiffAppr,"'",",")>
    	        <cfset caseDiffAppr = "AND 1 = CASE " & caseDiffAppr & " WHEN emp_id NOT IN (#lstEmpDiffAppr#) THEN 1 ELSE 0 END">
            </cfif>
            
            
            <cfset strckReturn.filterTambahan = caseDiffAppr>
         
    		<cfset LOCAL.arrValue = ArrayNew(1)/>
			<cfif isdefined("URL.devdmp")>
				<cfdump var="#LOCAL.lsValidEmp_id#" label="LOCAL.lsValidEmp_id">
			</cfif>
			<cfif retType eq "sql">
				<cfsavecontent variable="LOCAL.sqlQuery">
					<cfoutput>
					SELECT E.emp_id, E.emp_id nval
						,E.full_name#REQUEST.DBSTRCONCAT#' ('#REQUEST.DBSTRCONCAT#E.emp_no#REQUEST.DBSTRCONCAT#')' ntitle 
						<cfif REQUEST.SCOOKIE.MODE eq "SFGO">,E.full_name,E.emp_no,E.pos_name_en,E.photo</cfif>
					FROM VIEW_EMPLOYEE E
					WHERE 
						<cfif REQUEST.Scookie.User.UTYPE neq 9>
							E.company_id = ? <cfset ArrayAppend(arrValue, [REQUEST.SCookie.COID, "cf_sql_integer"])/> 
							AND (E.end_date >= ? <cfset ArrayAppend(arrValue, [CreateODBCDate(Now()), "CF_SQL_TIMESTAMP"])/> OR E.end_date IS NULL) 
							<cfif len(searchText) AND searchText neq "???">
								AND (
									E.full_name LIKE ? <cfset ArrayAppend(arrValue, ["%#searchText#%", "CF_SQL_VARCHAR"])/> 
									OR E.emp_no = ? <cfset ArrayAppend(arrValue, ["#searchText#", "CF_SQL_VARCHAR"])/>
								) 
							</cfif>
							<cfif retType eq "sql">
								AND (E.emp_id = ? <cfset ArrayAppend(arrValue, [REQUEST.SCookie.User.EMPID, "CF_SQL_VARCHAR"])/> 
									<cfif len(LOCAL.strFilterReqFor)>
										OR (1=0 #preservesinglequotes(LOCAL.strFilterReqFor)#)
									</cfif>
									<cfset LOCAL.arrValidEmp_id = listToArray(lsValidEmp_id,",") />
									<cfset LOCAL.lsLimit = 1000 />
									<cfloop index="LOCAL.idx" from="1" to="#arrayLen(arrValidEmp_id)#" step="#lsLimit#">
										OR E.emp_id IN (<cfloop index="LOCAL.sub" from="#idx#" to="#idx+(lsLimit-1)#" step="1"><cfif not arrayisdefined(arrValidEmp_id,sub)><cfbreak></cfif><cfif sub gt idx>,</cfif>'#arrValidEmp_id[sub]#'</cfloop>)
									</cfloop>
								)
							<cfelse>
								<cfif len(lsValidEmp_id)>
									AND ( <!---split the list into smaller list--->
										<cfset LOCAL.arrValidEmp_id = listToArray(lsValidEmp_id,",") />
										<cfset LOCAL.lsLimit = 1000 />
										<cfloop index="LOCAL.idx" from="1" to="#arrayLen(arrValidEmp_id)#" step="#lsLimit#">
											<cfif idx gt 1>OR</cfif> E.emp_id IN (<cfloop index="LOCAL.sub" from="#idx#" to="#idx+(lsLimit-1)#" step="1"><cfif not arrayisdefined(arrValidEmp_id,sub)><cfbreak></cfif><cfif sub gt idx>,</cfif>'#arrValidEmp_id[sub]#'</cfloop>)
										</cfloop>
									)
								</cfif>
							</cfif>
						<cfelse>
							1=0
						</cfif>
						<cfif qReqUSelf.recordcount>
							AND (E.emp_id != ? <cfset ArrayAppend(arrValue, [REQUEST.SCookie.User.EMPID, "CF_SQL_VARCHAR"])/>)
						</cfif>
					ORDER BY ntitle
					</cfoutput>
				</cfsavecontent>
			<cfelse>
				<cfsavecontent variable="LOCAL.sqlQuery">
					<cfoutput>
					SELECT DISTINCT E.emp_id nval, #Application.SFUtil.DBConcat(["E.full_name","' ['","EC.emp_no","']'"])# ntitle 
					FROM TEOMEmpPersonal E
						INNER JOIN TEODEmpCompany EC ON E.emp_id= EC.emp_id 
					WHERE 
						<cfif REQUEST.Scookie.User.UTYPE neq 9>
							EC.company_id = ? <cfset ArrayAppend(arrValue, [REQUEST.SCookie.COID, "cf_sql_integer"])/> 
							<!---active employee--->
							AND (EC.end_date >= ? <cfset ArrayAppend(arrValue, [CreateODBCDate(Now()), "CF_SQL_TIMESTAMP"])/> OR EC.end_date IS NULL) 
							<cfif len(searchText) AND searchText neq "???">
								AND (
									E.full_name LIKE ? <cfset ArrayAppend(arrValue, ["%#searchText#%", "CF_SQL_VARCHAR"])/> 
									OR EC.emp_no = ? <cfset ArrayAppend(arrValue, ["#searchText#", "CF_SQL_VARCHAR"])/>
								) 
							</cfif>
							<cfif len(lsValidEmp_id)>
								AND ( <!---split the list into smaller list--->
									<cfset LOCAL.arrValidEmp_id = listToArray(lsValidEmp_id,",") />
									<cfset LOCAL.lsLimit = 1000 />
									<cfloop index="LOCAL.idx" from="1" to="#arrayLen(arrValidEmp_id)#" step="#lsLimit#">
										<cfif idx gt 1>OR</cfif> E.emp_id IN (<cfloop index="LOCAL.sub" from="#idx#" to="#idx+(lsLimit-1)#" step="1"><cfif not arrayisdefined(arrValidEmp_id,sub)><cfbreak></cfif><cfif sub gt idx>,</cfif>'#arrValidEmp_id[sub]#'</cfloop>)
									</cfloop>
								)
							</cfif>
							<cfif qReqUSelf.recordcount>
								AND (E.emp_id != ? <cfset ArrayAppend(arrValue, [REQUEST.SCookie.User.EMPID, "CF_SQL_VARCHAR"])/>)
							</cfif>
						<cfelse>
							1=0
						</cfif>
					ORDER BY ntitle
					</cfoutput>
				</cfsavecontent>
			</cfif>
			<cfif isdefined("URL.devdmp")>
				<cfdump var="#LOCAL.sqlQuery#" label="LOCAL.sqlQuery">
			</cfif>
			<cfset LOCAL.qLookup = queryNew("nval,ntitle","Varchar,Varchar")>
	    		<cfset LOCAL.resultQuery = Application.SFDB.RunQuery(sqlQuery, arrValue)/>
	    		    
	    	
	    		<cfif resultQuery.QueryResult>
	    			<cfset qLookup = resultQuery.QueryRecords/>
	    			<cfset LOCAL.vSQL = resultQuery.QueryStruck/>
					
	                <cfset strckReturn.qLookup = qLookup>
	                <cfset strckReturn.ReqAppOrder = ReqAppOrder>
	    			<cfreturn strckReturn>
	            <cfelse>
	    			<cfreturn 0>
	    		</cfif>
			
			</cfif>
			
		</cffunction>
		
		
		<cffunction name="getApprovalOrder">
		    <cfargument name="reviewee" default="">
		    <cfargument name="reviewer" default="">
		    
			<cfset LOCAL.ObjectApproval="PERFORMANCE.Evaluation">
		    <cfset Local.reqorder = "-">
		    
			<cfquery name="LOCAL.qRequestApprovalOrder" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
				SELECT seq_id,
						req_order,
						request_approval_name,
						request_approval_formula,
						requester,
						requestee
				FROM	TCLCReqAppSetting
				WHERE	company_id = <cfqueryparam value="#REQUEST.scookie.COID#" cfsqltype="CF_SQL_INTEGER"/>
					AND request_approval_code = <cfqueryparam value="#LOCAL.ObjectApproval#" cfsqltype="CF_SQL_VARCHAR">
					AND (requester <> '' OR requestee <> '')
				ORDER BY request_approval_code DESC, req_order DESC, requester DESC, requestee DESC
			</cfquery>
			
			<cfloop query="qRequestApprovalOrder">
			    <cfset local.isValidReviewee = false>
			    <cfset local.isValidReviewer = false>

				<!--- ambil list requestee --->
				<cfset local.lstRequestee = "" />
				<cfif qRequestApprovalOrder.requestee neq "" AND qRequestApprovalOrder.requestee neq "[GENERAL]">
					<!---this Custom Code based on generate function[need coheren process with request approval setting origin]--->
					<cfset qRequestApprovalOrder.requestee = REReplace(qRequestApprovalOrder.requestee, "'male'",1, "ALL") />
					<cfset qRequestApprovalOrder.requestee = REReplace(qRequestApprovalOrder.requestee, "'female'",0, "ALL") />
					
					<cfquery name="LOCAL.qCekRequestee" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
						SELECT	distinct emp_id
						FROM	VIEW_EMPLOYEE
						WHERE	#PreserveSingleQuotes(qRequestApprovalOrder.requestee)#
					</cfquery>
					<cfset lstRequestee = ValueList(qCekRequestee.emp_id) />
				<cfelse>
					<cfset local.arrEmployee = objRequestApproval.GetEmployeeFromFormula(strRequestApprovalFormula=qRequestApprovalOrder.request_approval_formula, strEmpId=arguments.reviewer, iEmpType=1,retType="Isempid") />
					<cfloop array="#arrEmployee#" index="local.idxEmployee">
						<cfif not ListFindNoCase(lstRequestee, idxEmployee['emp_id'])>
							<cfset lstRequestee = ListAppend(lstRequestee, idxEmployee['emp_id']) />
						</cfif>
					</cfloop>
				</cfif>
				
    			<!--- TCK0918-196855 Cek apakah requester ada--->
                <cfset LOCAL.procValidEmp_id=false />
    			<cfif qRequestApprovalOrder.requester neq "" AND qRequestApprovalOrder.requester neq "[GENERAL]">
    				<!---this Custom Code based on generate function[need coheren process with request approval setting origin]--->
    				<cfset qRequestApprovalOrder.requester = REReplace(qRequestApprovalOrder.requester, "'male'",1, "ALL") />
    				<cfset qRequestApprovalOrder.requester = REReplace(qRequestApprovalOrder.requester, "'female'",0, "ALL") />
    				
    				<cfquery name="LOCAL.qCekRequester" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
    					SELECT	emp_id 
    					FROM	VIEW_EMPLOYEE
    					WHERE	emp_id = <cfqueryparam value="#REQUEST.SCookie.User.EMPID#" cfsqltype="CF_SQL_VARCHAR"> AND
    							#PreserveSingleQuotes(qRequestApprovalOrder.requester)#
    				</cfquery>
    				<cfif qCekRequester.RecordCount>
    					<cfset procValidEmp_id=true />
    				</cfif>
    			<cfelse>
    				<cfset procValidEmp_id=true />
    			</cfif>
                <cfset LOCAL.IsValidRequester=false />
    			<cfif procValidEmp_id>
    			    <cfset LOCAL.arrEmployee = objRequestApproval.GetEmployeeFromFormula(strRequestApprovalFormula=qRequestApprovalOrder.request_approval_formula, strEmpId=REQUEST.SCookie.User.EMPID, iEmpType=1,retType="lsempid") />
    			    <cfif ArrayLen(arrEmployee)>
                        <cfset IsValidRequester=true />
    			    </cfif>
    			</cfif>
    			<!--- TCK0918-196855 Cek apakah requester ada--->
				
				<cfif listfindnocase(lstRequestee,arguments.reviewee) AND (IsValidRequester OR arguments.reviewee EQ arguments.reviewer)> <!--- TCK0918-196855 Cek apakah requester ada | IsValidRequester (TCK1018-197363 - Jika requester sebagai requestee maka ambil workflow terakhir)  --->
				    <cfset reqorder = qRequestApprovalOrder.req_order>
				    <cfbreak>
				</cfif>
			</cfloop>
			
		    <cfreturn reqorder>
		</cffunction>
	    
	    <cffunction name="View">
	        <cfparam name="empid" default="">
	        <cfparam name="reqno" default="">
	        <cfparam name="periodcode" default="">
			<cfparam name="varcoid" default="#request.scookie.coid#">
	        <cfset local.nowdate= DATEFORMAT(CreateDate(Datepart("yyyy",now()),Datepart("m",now()),Datepart("d",now())),"mm/dd/yyyy")>
	        
	        <cfquery name="local.qGetReqStatus" datasource="#REQUEST.SDSN#">
	          	SELECT status, requester
				FROM	TCLTRequest
	            WHERE	req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
					AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
					and UPPER(req_type)='PERFORMANCE.EVALUATION'
					and req_no <> ''
	        </cfquery>
	        <!--- Untuk cari cari tau apakah form masih dalam finaldate atau tidak --->
	        <cfquery name="local.qFinalDate" datasource="#REQUEST.SDSN#">
	            SELECT  final_startdate, final_enddate 
	            FROM TPMMPERIOD 
	            WHERE period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfif request.dbdriver eq "MSSQL">
	    	   <cfset local.evalsd = DATEFORMAT(#qFinalDate.final_startdate#,"mm/dd/yyyy")>
				<cfset local.evaled = DATEFORMAT(#qFinalDate.final_enddate#,"mm/dd/yyyy")>
	    	<cfelse>
				<cfset local.evalsd = DATEFORMAT(#qFinalDate.final_startdate#,"yyyy-mm-dd")>
				<cfset local.evaled = DATEFORMAT(#qFinalDate.final_enddate#,"yyyy-mm-dd")>
	    	</cfif>
	        <cfif evaled lt nowdate>
	            <cfset local.evaldatevalid= 0 >
	        <cfelse>
	            <cfset local.evaldatevalid=1>
	        </cfif>
	        
	        
	        <cfquery name="local.qGetFormDetail" datasource="#request.sdsn#">
	        	SELECT distinct EP.full_name AS empname, EC.emp_no AS empno, EC.position_id AS emppos, EP.photo AS empphoto,
	            	EC.emp_id AS empid, '0' status, '#request.scookie.user.uid#' requester, '#evaldatevalid#' AS evaldatevalid
				FROM TEODEMPCOMPANY EC
					INNER JOIN TEOMEMPPERSONAL EP ON EP.emp_id = EC.emp_id
				WHERE EC.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
		            AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
	        </cfquery>
			<cfset REQUEST.KeyFields="reviewee_empid=#empid#">
	    	<cfreturn qGetFormDetail>
	    </cffunction>
	    
	    <cffunction name="getEmpWorkLocation">
    	    <cfargument name="empid" default="">
    	    <cfargument name="varcoid" default="#request.scookie.coid#" required="No">
    	    <cfargument name="periodcode" default="">
    	    <cfquery name="LOCAL.qGetWorkLocation" datasource="#request.sdsn#">
    	        select EH.emp_id,EH.worklocation_code,EH.effectivedt,WL.worklocation_name,EH.enddt
                from TEODEMPLOYMENTHISTORY EH
                LEFT JOIN  TEOMWORKLOCATION WL ON WL.worklocation_code = EH.worklocation_code 
                WHERE  emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                and effectivedt <= (select plan_startdate from TPMMPERIOD where period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
                and EH.company_id =  <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
                order by EH.effectivedt desc 
    	    </cfquery> 
    	<Cfreturn qGetWorkLocation>
    </cffunction>	
	    
	    <!--- Evaluation Form --->
	  <cffunction name="getEmpDetail">
	    	<cfargument name="empid" default="">
			<cfargument name="varcoid" default="#request.scookie.coid#" required="No">
	        <cf_sfqueryemp name="qGetEmpDetail" datasource="#REQUEST.SDSN#" maxrows="1" ACCESSCODE="hrm.employee" DAFIELD="empid">
	        	<cfoutput>
	        	SELECT distinct EP.full_name AS empname, EC.emp_no AS empno, POS.pos_name_#request.scookie.lang# AS emppos
	            	, ORG.pos_name_#request.scookie.lang# AS orgunit, EP.photo AS empphoto, EP.gender AS empgender
	                , GRD.grade_name AS empgrade, EC.start_date AS empjoindate
	                , EC.emp_id AS empid,EC.employ_code
	            	, POS.position_id AS posid
	            	, POS.dept_id,ES.employmentstatus_name_#request.scookie.lang# emp_status, WL.worklocation_name
				FROM TEODEMPCOMPANY EC
					INNER JOIN TEOMEMPPERSONAL EP ON EP.emp_id = EC.emp_id
	                LEFT JOIN TEOMPOSITION POS ON POS.position_id = EC.position_id <!---AND POS.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">--->
	                LEFT JOIN TEOMPOSITION ORG ON ORG.position_id = POS.dept_id <!---AND ORG.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">--->
	                LEFT JOIN TEOMJOBGRADE GRD ON GRD.grade_code = EC.grade_code <!---AND GRD.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">--->
	                LEFT JOIN TEOMEMPLOYMENTSTATUS ES ON EC.employ_code = ES.employmentstatus_code
					 LEFT JOIN TEOMWORKLOCATION WL ON EC.work_location_code = WL.worklocation_code
					WHERE EC.emp_id = <cf_sfqparamemp value="#empid#" cfsqltype="cf_sql_varchar">
		            AND EC.company_id = <cf_sfqparamemp value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		       </cfoutput>
	        </cf_sfqueryemp>
				<!--- start : ENC51115-79853 --->
				<cfif qGetEmpDetail.recordcount eq 0>
					<cfquery name="qGetEmpDetail" datasource="#request.sdsn#">
					 SELECT distinct EP.full_name AS empname, EC.emp_no AS empno, POS.pos_name_#request.scookie.lang# AS emppos
					  , ORG.pos_name_#request.scookie.lang# AS orgunit, EP.photo AS empphoto, EP.gender AS empgender
					  , GRD.grade_name AS empgrade, EC.start_date AS empjoindate
					  , EC.emp_id AS empid, EC.employ_code, EC.position_id, EC.grade_code, POS.dept_id
					  , POS.position_id AS posid,ES.employmentstatus_name_#request.scookie.lang# emp_status, WL.worklocation_name,EC.created_date
					 FROM TEODEMPCOMPANY EC
					  INNER JOIN TEOMEMPPERSONAL EP ON EP.emp_id = EC.emp_id
					  LEFT JOIN TEOMPOSITION POS ON POS.position_id = EC.position_id 
					  LEFT JOIN TEOMPOSITION ORG ON ORG.position_id = POS.dept_id 
					  LEFT JOIN TEOMJOBGRADE GRD ON GRD.grade_code = EC.grade_code 
					  LEFT JOIN TEOMEMPLOYMENTSTATUS ES ON EC.employ_code = ES.employmentstatus_code
					   LEFT JOIN TEOMWORKLOCATION WL ON EC.work_location_code = WL.worklocation_code
					 WHERE EC.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					  and (EC.start_date <= <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp"> 
					  and (EC.end_Date is null OR EC.end_Date > <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp">))
					   order by EC.created_date desc
					</cfquery>
				</cfif>
				<!--- end : ENC51115-79853 --->
	    	<cfreturn qGetEmpDetail>
	    </cffunction>
		
		
	    
	    <!---
	    <cffunction name="getLibComparison">
	        <cfargument name="empid" default="">
	        <cfargument name="periodcode" default="">
	        <cfargument name="reviewer" default="">
	        <cfargument name="libtype" default="">
	        <cfargument name="libcode" default="">
	        
	        <cfquery name="Local.qData" datasource="#request.sdsn#">
	        	SELECT distinct C.full_name AS empname, D.pos_name_#request.scookie.lang# AS emppos, E.grade_name AS empgrade, A.achievement, H.reviewee_empid, B.emp_no AS empno
	           	<cfif ucase(libtype) eq "APPRAISAL">
	               	, LIB.appraisal_name AS lib_name
	           	<cfelseif ucase(libtype) eq "OBJECTIVE">
	               	, LIB.objective_name AS lib_name
	           	<cfelseif ucase(libtype) eq "COMPETENCE">
	               	, LIB.competency_name AS lib_name
	            </cfif>
				FROM TPMDCPMLIBDETAIL A
	           	<cfif ucase(libtype) eq "APPRAISAL">
	            LEFT JOIN TPMDPERIODAPPLIB LIB ON LIB.appraisal_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	           	<cfelseif ucase(libtype) eq "OBJECTIVE">
	            LEFT JOIN TPMDPERIODOBJLIB LIB ON LIB.objective_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	           	<cfelseif ucase(libtype) eq "COMPETENCE">
	            LEFT JOIN TPMDPERIODCOMPLIB LIB ON LIB.competence_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	            </cfif>
	            INNER JOIN TPMDCPMH 
	            	H ON H.request_no = A.request_no 
	                AND H.company_code = A.company_code
	                AND H.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	                
					<!--- nilainya ambil langsung dari form pake js--->
	                AND H.reviewee_empid <> <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	                
				LEFT JOIN TEODEMPCOMPANY B 
	            	ON B.emp_id = H.reviewee_empid AND B.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMEMPPERSONAL C 
	            	ON C.emp_id = B.emp_id
				LEFT JOIN TEOMPOSITION D 
	            	ON D.position_id = B.position_id 
	            	AND D.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMJOBGRADE E 
	            	ON E.grade_code = B.grade_code 
	                AND E.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				WHERE A.lib_type = <cfqueryparam value="#libtype#" cfsqltype="cf_sql_varchar">
					AND A.lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
	            ORDER BY A.achievement DESC
	        </cfquery>
	        <cfreturn qData>
	    </cffunction>
		--->
	    
	    <cffunction name="getAllReviewerData">
	    	<cfargument name="reqno" default="">
	        <cfargument name="empid" default="">
	        <cfargument name="periodcode" default="">
	        <cfargument name="reviewer" default="">
	        <cfargument name="step" default="">
	        <cfargument name="libtype" default="APPRAISAL">
	        <cfargument name="libcode" default="">
			<cfargument name="notes" default="">
			 <!---  start :  ENC51115-79853 --->
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">   
			<cfargument name="varcoid" default="#request.scookie.coid#" required="No">   
	         <!---  end :  ENC51115-79853 --->
			<cfif libtype eq 'APPRAISAL'>	
				<cfquery name="local.qGetParent" datasource="#request.sdsn#">
					SELECT  APLIB.parent_path, APP.apprlib_code, APP.position_id FROM TPMDPERIODAPPRAISAL APP, TEODEMPCOMPANY COMP, TPMDPERIODAPPRLIB APLIB
					WHERE COMP.position_id = APP.position_id
					AND APLIB.period_code = APP.period_code
					AND APLIB.apprlib_code = APP.apprlib_code
					AND APP.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND COMP.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					AND APP.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					ORDER BY APP.apprlib_code
				</cfquery>
				<cfquery name="local.qCheck" datasource="#request.sdsn#">
					SELECT  EVALH.form_no FROM TPMDPERFORMANCE_EVALH EVALH 
					WHERE EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset local.parentpath = ValueList(qGetParent.parent_path)>
				<cfset parentpath = ListAppend(parentpath,ValueList(qGetParent.apprlib_code))>
				<cfquery name="local.qComponentData" datasource="#request.sdsn#">
						SELECT  isnull(APPR.apprlib_code,APPLIB.apprlib_code) lib_code, APPLIB.appraisal_name_#request.scookie.lang# lib_name,
						    APPLIB.parent_code parent_code, APPLIB.iscategory iscategory, 
							APPLIB.parent_path parent_path, APPLIB.appraisal_depth lib_depth, 
							isnull(EVALD.weight,APPR.weight) weight, isnull(EVALD.target,APPR.target) target, isnull(EVALD.achievement,0) achievement, 
							isnull(EVALD.achievement,0) achievement
						FROM TPMDPERIODAPPRLIB APPLIB 
						LEFT JOIN TPMDPERIODAPPRAISAL APPR ON APPLIB.period_code = APPR.period_code AND APPLIB.company_code = APPR.company_code AND APPLIB.apprlib_code = APPR.apprlib_code AND APPLIB.reference_date = APPR.reference_date
						LEFT JOIN TPMDPERFORMANCE_EVALD EVALD ON APPLIB.apprlib_code = EVALD.lib_code AND APPLIB.company_code = EVALD.company_code and EVALD.lib_code = APPR.apprlib_code
						LEFT JOIN TPMDPERFORMANCE_EVALH EVALH ON EVALD.form_no = EVALH.form_no AND EVALD.company_code = EVALH.company_code AND EVALH.period_code = APPR.period_code
						WHERE (APPR.position_id = '#qGetParent.position_id#' or APPR.position_id IS NULL)
						<cfif parentpath neq "">
							AND APPLIB.apprlib_code IN (#ListQualify(parentpath,"'")#)
						<cfelse>
							AND 1 = 0
						</cfif>
						<cfif qCheck.recordcount>
							AND (EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
							OR (APPLIB.iscategory='Y' AND EVALH.request_no IS NULL AND APPLIB.period_code =<cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
						<cfelse>
							AND (EVALH.request_no IS NULL AND APPLIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
						</cfif>	
						order by lib_depth,lib_code asc 
				</cfquery>
			<cfelseif libtype eq 'OBJECTIVE'>
				<cfquery name="local.qGetParent" datasource="#request.sdsn#">
					SELECT  parent_path,kpilib_code,KPI.position_id FROM TPMDPERIODKPI KPI, TEODEMPCOMPANY COMP
					WHERE KPI.position_id = COMP.position_id
					AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND COMP.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					ORDER BY kpilib_code
				</cfquery>
				<cfset local.parentpath = ValueList(qGetParent.parent_path)>
				<cfset parentpath = ListAppend(parentpath,ValueList(qGetParent.kpilib_code))>
				<!---  <cfdump var="#parentpath#"> --->
				<cfquery name="local.qComponentData" datasource="#request.sdsn#">
					SELECT  isnull(KPI.kpilib_code,KPILIB.kpilib_code) lib_code, isnull(KPI.kpi_name_en,KPILIB.kpi_name_en) lib_name,
							isnull(KPI.parent_code,KPILIB.parent_code) parent_code, isnull(KPI.iscategory,KPILIB.iscategory) iscategory, 
							isnull(KPI.parent_path,KPILIB.parent_path) parent_path, isnull(KPI.kpi_depth,KPILIB.kpi_depth) lib_depth, 
							isnull(EVALD.weight,KPI.weight) weight, isnull(EVALD.target,KPI.target) target, isnull(EVALD.achievement,0) achievement, isnull(EVALD.achievement,0) achievement
						FROM TPMDPERIODKPILIB KPILIB 
						LEFT JOIN TPMDPERIODKPI KPI ON KPILIB.period_code = KPI.period_code AND KPILIB.company_code = KPI.company_code AND KPILIB.kpilib_code = KPI.kpilib_code AND KPILIB.reference_date = KPI.reference_date
						LEFT JOIN TPMDPERFORMANCE_EVALD EVALD ON KPILIB.kpilib_code = EVALD.lib_code AND KPILIB.company_code = EVALD.company_code
						LEFT JOIN TPMDPERFORMANCE_EVALH EVALH ON EVALD.form_no = EVALH.form_no AND EVALD.company_code = EVALH.company_code	
						WHERE (KPI.position_id = '#qGetParent.position_id#' or KPI.position_id IS NULL)
						<cfif parentpath neq "">
							AND KPILIB.kpilib_code IN (#ListQualify(parentpath,"'")#)
						<cfelse>
							AND 1 = 0
						</cfif>
							AND ((EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
							OR EVALH.request_no IS NULL AND KPILIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
						order by lib_depth,lib_code asc 
				</cfquery>		
			<cfelseif libtype eq 'OBJECTIVEORG'>
				<cfquery name="local.qGetParent" datasource="#request.sdsn#">
					SELECT  parent_path,kpilib_code,KPI.position_id FROM TPMDPERIODKPI KPI, TEODEMPCOMPANY COMP
					WHERE KPI.position_id = COMP.position_id
					AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND COMP.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					ORDER BY kpilib_code
				</cfquery>
				<cfquery name="local.qGetHeadDivKPI" datasource="#request.sdsn#">
					SELECT  DEPT.head_div 
					FROM TEOMPOSITION POS	  
						LEFT JOIN TEOMPOSITION DEPT ON POS.dept_id = DEPT.position_id AND POS.company_id = DEPT.company_id 	
						WHERE POS.position_id = <cfqueryparam value="#qGetParent.position_id#" cfsqltype="cf_sql_varchar">
						AND POS.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfquery name="local.qGetPosLogin" datasource="#request.sdsn#">
					SELECT distinct POS.position_id FROM TEODEMPCOMPANY COMPA
						INNER JOIN TEOMPOSITION POS ON COMPA.position_id = pos.position_id AND COMPA.company_id = pos.company_id
						WHERE COMPA.emp_id = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
						AND COMPA.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset local.parentpath = ValueList(qGetParent.parent_path)>
				<cfset parentpath = ListAppend(parentpath,ValueList(qGetParent.kpilib_code))>
				<cfif qGetHeadDivKPI.head_div eq qGetPosLogin.position_id>
					<cfset local.editable = 1>
				<cfelse>
					<cfset local.editable = 0>
				</cfif>
				<cfquery name="local.qComponentData" datasource="#request.sdsn#">
					SELECT  isnull(KPI.kpilib_code,KPILIB.kpilib_code) lib_code, isnull(KPI.kpi_name_en,KPILIB.kpi_name_en) lib_name,
							isnull(KPI.parent_code,KPILIB.parent_code) parent_code, isnull(KPI.iscategory,KPILIB.iscategory) iscategory, 
							isnull(KPI.parent_path,KPILIB.parent_path) parent_path, isnull(KPI.kpi_depth,KPILIB.kpi_depth) lib_depth, 
							isnull(EVALD.weight,KPI.weight) weight, isnull(EVALD.target,KPI.target) target, isnull(EVALD.achievement,0) achievement, isnull(EVALD.achievement,0) achievement,
							'#editable#' editable
						FROM TPMDPERIODKPILIB KPILIB 
						LEFT JOIN TPMDPERIODKPI KPI ON KPILIB.period_code = KPI.period_code AND KPILIB.company_code = KPI.company_code AND KPILIB.kpilib_code = KPI.kpilib_code AND KPILIB.reference_date = KPI.reference_date
						LEFT JOIN TPMDPERFORMANCE_EVALD EVALD ON KPILIB.kpilib_code = EVALD.lib_code AND KPILIB.company_code = EVALD.company_code
						LEFT JOIN TPMDPERFORMANCE_EVALH EVALH ON EVALD.form_no = EVALH.form_no AND EVALD.company_code = EVALH.company_code	
						WHERE (KPI.position_id = '#qGetParent.position_id#' or KPI.position_id IS NULL)
						<cfif parentpath neq "">
							AND KPILIB.kpilib_code IN (#ListQualify(parentpath,"'")#)
						<cfelse>
							AND 1 = 0
						</cfif>
							AND ((EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
							OR EVALH.request_no IS NULL AND KPILIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
						order by lib_depth,lib_code asc 
				</cfquery>
			<cfelseif libtype eq 'COMPETENCY'>
				<cfquery name="local.qGetParent" datasource="#request.sdsn#">
					SELECT distinct COM.parent_path,JT.competence_code
					FROM TEODEMPCOMPANY COMPA
						INNER JOIN TEOMPOSITION POS ON COMPA.position_id = pos.position_id AND COMPA.company_id = pos.company_id
						INNER JOIN TPMRCOMPETENCEJT JT ON POS.jobtitle_code = JT.jobtitle_code
						INNER JOIN TPMMCOMPETENCE COM ON JT.competence_code = COM.competence_code
						WHERE COMPA.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
						AND COMPA.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfquery name="local.qCheck" datasource="#request.sdsn#">
					SELECT distinct EVALH.form_no FROM TPMDPERFORMANCE_EVALH EVALH 
					WHERE EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset local.parentpath = ValueList(qGetParent.parent_path)>
				<cfset parentpath = ListAppend(parentpath,ValueList(qGetParent.competence_code))>
				<cfquery name="local.qComponentData" datasource="#request.sdsn#">
					SELECT distinct competence_code lib_code, COMPLIB.competence_name_en lib_name,order_no,
							COMPLIB.parent_code, COMPLIB.iscategory, 
							COMPLIB.parent_path,COMPLIB.competence_depth lib_depth, 
							isnull(EVALD.weight,0) weight, isnull(EVALD.target,0) target, isnull(EVALD.achievement,0) achievement, isnull(EVALD.achievement,0) achievement,isnull(EVALD.score,0) score, EVALD.notes,
							EVALD.reviewer_empid
						FROM TPMMCOMPETENCE COMPLIB 
						LEFT JOIN TPMDPERFORMANCE_EVALD EVALD ON COMPLIB.competence_code = EVALD.lib_code	
						LEFT JOIN TPMDPERFORMANCE_EVALH EVALH ON EVALD.form_no = EVALH.form_no AND EVALD.company_code = EVALH.company_code	AND EVALD.reviewer_empid = EVALH.reviewer_empid		
						<cfif parentpath neq "">
							WHERE COMPLIB.competence_code IN (#ListQualify(parentpath,"'")#)
						<cfelse>
							WHERE 1 = 0
						</cfif>
							AND ((EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							<!--- AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar"> --->
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
							OR EVALH.request_no IS NULL)
						order by lib_depth,order_no asc 
				</cfquery>	
			<cfelseif libtype eq "COMPONENT">
				<cfquery name="local.qComponentData" datasource="#request.sdsn#">
					SELECT  distinct EVALD.score
					FROM TPMDPERFORMANCE_EVALD EVALD, TPMDPERFORMANCE_EVALH EVALH 
					WHERE EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
					AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					AND EVALD.reviewer_empid  = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
					AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND EVALD.lib_type = <cfqueryparam value="#libtype#" cfsqltype="cf_sql_varchar">
					AND EVALD.lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">	
					AND EVALH.reviewer_empid = EVALD.reviewer_empid
					AND EVALH.form_no = EVALD.form_no
				</cfquery>	
			<cfelse>
				<cfset local.qComponentData = 0>
			</cfif>
			<!--- <cf_sfwritelog dump="qComponentData" prefix="RanggaSFPer"> --->
	        <cfreturn qComponentData>
	    </cffunction>
	    
	    <!--- Task Function --->
	    <cffunction name="TaskListing">
	    	<cfargument name="asigneeId" default="">
			<cfargument name="periodcode" default="">
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">    <!---  added by :  ENC51115-79853 --->
	        <cfquery name="local.qGetTaskListing" datasource="#request.sdsn#">
	        	SELECT  TK.task_code, EP.full_name AS asignee_name, TK.task_desc, TK.priority, TK.status, TK.startdate, TK.duedate, GBY.full_name AS givenby, TK.status_task, TK.completion_date, created_task
				FROM TPMMPERIOD PR, TPMDTASK TK
				INNER JOIN TEOMEMPPERSONAL GBY
					ON GBY.emp_id = TK.created_task
				INNER JOIN TEOMEMPPERSONAL EP 
					ON EP.emp_id = TK.assignee 
					AND TK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND TK.assignee = <cfqueryparam value="#asigneeId#" cfsqltype="cf_sql_varchar">
				WHERE TK.duedate >= PR.period_startdate
				AND TK.duedate <= PR.period_enddate
				AND TK.company_code = PR.company_code
				AND PR.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
			<!--- <cf_sfwritelog dump="qGetTaskListing" prefix="qGetTaskListing_">--->
	        <cfreturn qGetTaskListing>
	    </cffunction>

	    <!--- Feedback Function --->
	    <cffunction name="FeedbackListing">
	    	<cfargument name="asigneeId" default="">
			<cfargument name="periodcode" default="">
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">    <!---  added by :  ENC51115-79853 --->
	        <cfquery name="local.qGetFBListing" datasource="#request.sdsn#">
			    SELECT  FB.feedback_code, EP.full_name AS feedbackby, FB.feedback_type, FB.feedback_desc, FB.severity_level, FB.created_date, created_feedback
				FROM TPMMPERIOD PR, TPMDFEEDBACK FB
				INNER JOIN TEOMEMPPERSONAL EP
					ON EP.emp_id = FB.created_feedback
					AND FB.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND FB.feedback_for = <cfqueryparam value="#asigneeId#" cfsqltype="cf_sql_varchar">
				WHERE FB.created_date >= PR.period_startdate
				AND FB.created_date <= PR.period_enddate
				AND FB.company_code = PR.company_code
				AND PR.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfreturn qGetFBListing>
	    </cffunction>

	    <!--- Evaluation History Tab Function --->
	    <cffunction name="EvaluationHistListing">
	    	<cfargument name="asigneeId" default="">
			<cfargument name="periodcode" default="">		
			 <!---  start :  ENC51115-79853 --->
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">   
			<cfargument name="varcoid" default="#request.scookie.coid#" required="No">  
			
            <cfset LOCAL.InitVarCountDeC = 2><!---override di hardcode 2 decimal seperti di overallscore, tadinya dr REQUEST.InitVarCountDeC--->
			 <!---  end :  ENC51115-79853 --->
	        <cfquery name="local.qGetEvHistListing" datasource="#request.sdsn#">
	        	SELECT  PER.period_name_#request.scookie.lang# AS formname, PER.period_startdate, PER.period_enddate
					, POS.pos_name_#request.scookie.lang# AS emppos, GRD.grade_name AS empgrade, STS.employmentstatus_name_#request.scookie.lang# AS empstatus
					, ROUND(PMH.final_score,#InitVarCountDeC#) AS empscore <!---BUG50415-42293--->
					, PMH.final_conclusion AS empconclusion, PMH.reference_date startdate
				FROM TPMDPERFORMANCE_FINAL PMH
					LEFT JOIN TPMMPERIOD PER ON PER.period_code = PMH.period_code AND PER.company_code = PMH.company_code
	                LEFT JOIN TEOMPOSITION POS ON POS.position_id = PMH.reviewee_posid AND POS.company_id = #request.scookie.coid#
					LEFT JOIN TEOMJOBGRADE GRD ON GRD.grade_code = PMH.reviewee_grade AND GRD.company_id = #request.scookie.coid#
					LEFT JOIN TEOMEMPLOYMENTSTATUS STS ON STS.employmentstatus_code = PMH.reviewee_employcode
				WHERE PMH.reviewee_empid = <cfqueryparam value="#asigneeId#" cfsqltype="cf_sql_varchar">
					AND PMH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					<!--- untuk semua period --->
	                <!---
					AND PMH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					--->
	        </cfquery>
	        <cfreturn qGetEvHistListing>
	    </cffunction>
	    
	    <cffunction name="AwardsHistListing">
	    	<cfargument name="asigneeId" default="">
			<cfargument name="periodcode" default="">
			 <!---  start :  ENC51115-79853 --->
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">   
			<cfargument name="varcoid" default="#request.scookie.coid#" required="No">   
			 <!---  end :  ENC51115-79853 --->
	        <cfquery name="local.qGetAwdHistListing" datasource="#request.sdsn#">
	        	SELECT  POS.pos_name_#request.scookie.lang# AS emppos
	            	, MA.achievement_name_#request.scookie.lang# AS awardname
	            	, EA.refno AS awardno
	                , EA.refdt AS awarddate
	                , EA.achievement_letter AS letterno
	                , EA.achievement_certificate AS certificateno
				FROM TPMMPERIOD PR, TCATEMPACHIEVEMENTHISTORY EA
					LEFT JOIN TCAMAWARD MA ON MA.achievement_code =  EA.achievement_code 
	                LEFT JOIN TEOMPOSITION POS ON POS.position_id = EA.position_id AND POS.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				WHERE EA.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
					AND EA.emp_id = <cfqueryparam value="#asigneeId#" cfsqltype="cf_sql_varchar">
					AND EA.refdt >= PR.period_startdate
					AND EA.refdt <= PR.period_enddate
					AND PR.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND PR.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfreturn qGetAwdHistListing>
	    </cffunction>

	    <cffunction name="DiscHistListing">
	    	<cfargument name="asigneeId" default="">
			<cfargument name="periodcode" default="">
			<!---  start :  ENC51115-79853 --->
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">   
			<cfargument name="varcoid" default="#request.scookie.coid#" required="No">   
			 <!---  end :  ENC51115-79853 --->
	        <cfquery name="local.qGetDiscHistListing" datasource="#request.sdsn#">
	        	SELECT  POS.pos_name_#request.scookie.lang# AS emppos
	            	, ED.refno AS discno
	                , ED.refdt AS discdate
	                , MD.disciplines_name_#request.scookie.lang# AS discname
	                , ED.startdt AS startdate
	                , ED.enddt AS enddate
	                , '' AS status
	                <cfif request.dbdriver eq "MSSQL">
					,  CASE WHEN datediff(day,ED.startdt,getdate())<0 THEN 'Inactive' WHEN datediff(day,ED.startdt,getdate())>=0 THEN CASE WHEN datediff(day,getdate(),ED.enddt) <0 THEN 'Expired' WHEN datediff(day,getdate(),ED.enddt) >=0 THEN 'Active ['+convert(varchar,datediff(day,getdate(),ED.enddt))+']' END END expired
					<cfelse>
					,  CASE WHEN TIMESTAMPDIFF(day,ED.startdt,now())<0 THEN 'Inactive' WHEN TIMESTAMPDIFF(day,ED.startdt,now())>=0 THEN CASE WHEN TIMESTAMPDIFF(day,now(),ED.enddt) <0 THEN 'Expired' WHEN TIMESTAMPDIFF(day,now(),ED.enddt) >=0 THEN 'Active ['||convert(TIMESTAMPDIFF(day,now(),ED.enddt),char)||']' END END expired
					</cfif>
	                , ED.letter_no AS letterno
				FROM TPMMPERIOD PR, TCATDISCIPLINESHISTORY ED
					LEFT JOIN TCAMDISCIPLINE MD ON MD.disciplines_code = ED.disciplines_code
					LEFT JOIN TEOMPOSITION POS ON POS.position_id = ED.position_id AND POS.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				WHERE ED.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
					AND ED.emp_id = <cfqueryparam value="#asigneeId#" cfsqltype="cf_sql_varchar">
					AND ED.startdt <= PR.period_enddate
					AND ED.enddt >= PR.period_startdate
					AND PR.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND PR.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfreturn qGetDiscHistListing>
	    </cffunction>
		
		<!--- Return Score Range --->
	    <cffunction name="ScoreRange">
	    	<cfargument name="periodcode" default="">
			<cfargument name="type" default="task">
			
	        <cfquery name="local.qGetScore" datasource="#request.sdsn#">
	        	SELECT distinct scoredet_value, scoredet_order 
				FROM TGEDSCOREDET
				WHERE score_code = (SELECT score_type FROM TPMMPERIOD 
					WHERE period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
				ORDER BY scoredet_order
	        </cfquery>
			
			<cfset local.score = "">
			<cfset score = listappend(score,listfirst(valuelist(qGetScore.scoredet_value)))>
			<cfset score = listappend(score,listlast(valuelist(qGetScore.scoredet_value)))>
	        <cfreturn score>
	    </cffunction>
		
		<!--- Return Final Score --->
	    <cffunction name="FinalScore">
	    	<cfargument name="periodcode" default="">
			<cfargument name="type" default="task">
			<cfargument name="fscore" default="">
			<cfargument name="refdate" default="">
			
			<cfquery name="local.qCekLookUp" datasource="#request.sdsn#">
				SELECT  lookup_code FROM TPMDPERIODCOMPONENT 
				WHERE component_code = <cfqueryparam value="#type#" cfsqltype="cf_sql_varchar">
				AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
				AND reference_date = <cfqueryparam value="#refdate#" cfsqltype="cf_sql_timestamp">
			</cfquery>
			
			<cfif qCekLookUp.recordcount>
		        <cfquery name="local.qGetSymbol" datasource="#request.sdsn#">
		        	SELECT symbol, lookup_code FROM TPMMLOOKUP
					WHERE lookup_code = <cfqueryparam value="#qCekLookUp.lookup_code#" cfsqltype="cf_sql_varchar">
		        </cfquery>

				<cfset local.finalscore = fscore>
				<cfif qGetSymbol.recordcount>
					<cfquery name="local.qScore" datasource="#request.sdsn#">
			        	SELECT lookup_score, lookup_value FROM TPMDLOOKUP
						WHERE lookup_code = <cfqueryparam value="#qGetSymbol.lookup_code#" cfsqltype="cf_sql_varchar">
						order by lookup_value
			        </cfquery>
					
					<cfset local.ctr = 0>
					<cfloop query="qScore">
						<cfset ctr = ctr + 1>
						<cfif qGetSymbol.symbol eq 'LT'>
							<cfif fscore lt lookup_value>
								<cfset finalscore = lookup_score>
								<cfbreak>
							<cfelseif ctr eq qScore.recordcount>
								<cfset finalscore = lookup_score>
								<cfbreak>
							</cfif>
						<cfelseif qGetSymbol.symbol eq 'LTE'>
							<cfif fscore lte lookup_value>
								<cfset finalscore = lookup_score>
								<cfbreak>
							<cfelseif ctr eq qScore.recordcount>
								<cfset finalscore = lookup_score>
								<cfbreak>
							</cfif>
						<cfelseif qGetSymbol.symbol eq 'SYM'>
							<cfif fscore eq lookup_value>
								<cfset finalscore = lookup_score>
								<cfbreak>
							<cfelseif ctr eq qScore.recordcount>
								<cfset finalscore = lookup_score>
								<cfbreak>
							</cfif>
						<cfelseif qGetSymbol.symbol eq 'GT'>
							<cfif fscore gt lookup_value>
								<cfset finalscore = lookup_score>
								<cfbreak>
							<cfelseif ctr eq qScore.recordcount>
								<cfset finalscore = lookup_score>
								<cfbreak>
							</cfif>
						<cfelseif qGetSymbol.symbol eq 'GTE'>
							<cfif fscore gte lookup_value>
								<cfset finalscore = lookup_score>
								<cfbreak>
							<cfelseif ctr eq qScore.recordcount>
								<cfset finalscore = lookup_score>
								<cfbreak>
							</cfif>
						</cfif>
					</cfloop>
					<cfset VarScore.fscore = fscore>
					<cfset VarScore.taskscore = finalscore>
				<cfelse>
					<cfset VarScore.fscore = round(fscore)>
					<cfset VarScore.taskscore = round(finalscore)>
				</cfif>
			<cfelse>
				<cfset VarScore.fscore = round(fscore)>
				<cfset VarScore.taskscore = round(fscore)>
			</cfif>
			
	        <cfreturn VarScore>
	    </cffunction>
		
		<cffunction name="getScoring">
			<cfargument name="periodcode" default="">
			<cfquery name="local.qScoring" datasource="#request.sdsn#">
				SELECT distinct scoredet_value, scoredet_mask, scoredet_desc ,scoredet_order
				FROM TGEDSCOREDET
				WHERE score_code = (SELECT score_type FROM TPMMPERIOD 
					WHERE period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
				ORDER BY scoredet_order
			</cfquery>
			<cfreturn qScoring>
		</cffunction>
	    
	    <cffunction name="cekOrgPersKPI">
	    	<cfargument name="periodcode" default="">
	    	<cfargument name="refdate" default="">
	    	<cfargument name="empid" default="">
	    	<cfargument name="posid" default="">
	        <!---  start :  ENC51115-79853 --->
			<cfargument name="varcoid" default="#request.scookie.coid#">
	    	<cfargument name="varcocode" default="#request.scookie.cocode#">
			<!---  end :  ENC51115-79853 --->
	        <cfset Local.listOrgUnit = "">
	        
	        <cfquery name="local.qCekIfPlanned" datasource="#request.sdsn#">
	        	SELECT CASE WHEN plan_startdate IS NULL THEN 0 ELSE 1 END useplan 
	            FROM TPMMPERIOD
				WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfif qCekIfPlanned.useplan>
		        <cfquery name="local.qCekIfUsed" datasource="#request.sdsn#">
		        	SELECT component_code FROM TPMDPERIODCOMPONENT
					WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
		        </cfquery>
		        <cfset local.lstUsed = valuelist(qCekIfUsed.component_code)>

		        <cfset local.strckRet = structnew()>
		       	<cfset strckRet["perskpi"] = false>
	    	   	<cfset strckRet["orgkpi"] = true>
	        
		        <!--- cek PERSKPI --->
	    	    <cfquery name="Local.qCheckPersKPI" datasource="#request.sdsn#">
					SELECT  PH.request_no, PH.reviewee_unitpath FROM TPMDPERFORMANCE_PLANH PH
					INNER JOIN TPMDPERFORMANCE_PLAND PD
						ON PD.form_no = PH.form_no
						AND PD.company_code = PH.company_code
					WHERE PH.isfinal = 1
						AND PH.reviewee_empid = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
						AND PH.reviewee_posid = <cfqueryparam value="#arguments.posid#" cfsqltype="cf_sql_varchar">
						AND PH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					order by PH.created_date desc 
		        </cfquery>
		   
		        <cfquery name="local.qCekPersReq" datasource="#request.sdsn#">
					SELECT status FROM TCLTREQUEST 
	        	    WHERE req_type = 'PERFORMANCE.PLAN'
	            		AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		                AND req_no = <cfqueryparam value="#qCheckPersKPI.request_no#" cfsqltype="cf_sql_varchar">
	    	    </cfquery>
			
		        <cfif listfindnocase("3,9",qCekPersReq.status)>
	    	    	<cfset strckRet["perskpi"] = true>
	            
					<!---<cfset listOrgUnit = qCheckPersKPI.reviewee_unitpath>--->
		            <cfquery name="local.qGetDeptId" datasource="#request.sdsn#">
		            	SELECT DISTINCT dept_id FROM TEOMPOSITION
						WHERE position_id = <cfqueryparam value="#arguments.posid#" cfsqltype="cf_sql_integer">
						AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		            </cfquery>
	    	        <cfset listOrgUnit = qGetDeptId.dept_id>
		        </cfif>

		        <!--- cek ORGKPI --->
		        <cfset local.listValidOrgUnit = "">
	    	    <cfloop list="#listOrgUnit#" index="local.orgunitidx">
	        	<cfif orgunitidx neq 0>
	        	
					<cfset local.listValidOrgUnit = listappend(listValidOrgUnit,orgunitidx)>
		   	    	<cfset strckRet["#orgunitidx#"] = false>
	            
			        <cfquery name="local.qCheckOrgKpi" datasource="#request.sdsn#">
			        	SELECT DISTINCT request_no FROM TPMDPERFORMANCE_PLANKPI
	    		        WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	        		    	AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
							AND orgunit_id = <cfqueryparam value="#orgunitidx#" cfsqltype="cf_sql_integer">
			        </cfquery>
					<cfquery name="local.qCekOrgReq" datasource="#request.sdsn#">
						SELECT DISTINCT status FROM TCLTREQUEST 
			            WHERE req_type = 'PERFORMANCE.PLAN'
	   			        	AND company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer">
	       			        AND req_no = <cfqueryparam value="#qCheckOrgKpi.request_no#" cfsqltype="cf_sql_varchar">
			        </cfquery>
					
			        <cfif listfindnocase("3,9",qCekOrgReq.status)>
						<cfquery name="local.qCheckOrgKpi" datasource="#request.sdsn#">
			    	    	SELECT DISTINCT evalkpi_status FROM TPMDPERFORMANCE_EVALKPI
			        	    WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
		    	        		AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
								AND orgunit_id = <cfqueryparam value="#orgunitidx#" cfsqltype="cf_sql_integer">
			        	</cfquery>
						
		    	        <cfif qCheckOrgKpi.evalkpi_status eq 3>
		   	    	    	<cfset strckRet["#orgunitidx#"] = true>
		        	    </cfif>
			        </cfif>
	            
		            <cfif not strckRet["#orgunitidx#"]>
			            <cfset strckRet["orgkpi"] = false>
		            </cfif>
		        </cfif>
		        </cfloop>
	        
		        <cfset strckRet["listorgunit"] = listValidOrgUnit>
		        <!--- VALIDATE NEW UI --->
		        <cfset flagnewui = "#REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE#">
				<!---  <cf_sfwritelog dump="strckRet,lstUsed" prefix="lstUsed">   --->
	    	    <cfif not strckRet["perskpi"] and listfindnocase(lstUsed,"persKPI")>
		    	    <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSPersonal Objective is not yet set in planning",true)>
		    	    <cfif flagnewui eq 0>
    		    		<cfoutput>
    			        	<script>
    							alert("#LOCAL.SFLANG#");
    							//console.log('yan #strckRet["perskpi"]#')
    							maskButton(false);
    						</script>
    			        </cfoutput>
			        <cfelse>
			            <cfset data = {msg="#SFLANG#", success="0"}>
                        <cfset serializedStr = serializeJSON(data)>
            		    <cfoutput>
            		        #serializedStr#
            		    </cfoutput>
            		    <CF_SFABORT>
		            </cfif>
				    <cfreturn false>
	    	    <cfelseif not strckRet["orgkpi"] and listfindnocase(lstUsed,"orgKPI")>
			        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSOrg Unit Objective must be set before",true)>
			        <cfif flagnewui eq 0>
    			    	<cfoutput>
    	    		    	<script>
    							alert("#LOCAL.SFLANG#");
    							//console.log('yan #strckRet["orgkpi"]#')
    							maskButton(false);
    						</script>
    			        </cfoutput>
			        <cfelse>
			            <cfset data = {msg="#SFLANG#", "success"="0"}>
                        <cfset serializedStr = serializeJSON(data)>
            		    <cfoutput>
            		        #serializedStr#
            		    </cfoutput>
            		    <CF_SFABORT>
			        </cfif>
		            <cfreturn false> 
				
		        <cfelse>
		            <cfreturn true>
		        </cfif>
	        <cfelse>
	            <cfreturn true>
			</cfif>
	    </cffunction>
	    <cffunction name="cekOrgPersKPIBeforeSubmit">
	    	<cfargument name="periodcode" default="">
	    	<cfargument name="refdate" default="">
	    	<cfargument name="empid" default="">
	    	<cfargument name="posid" default="">
	        <!---  start :  ENC51115-79853 --->
			<cfargument name="varcoid" default="#request.scookie.coid#">
	    	<cfargument name="varcocode" default="#request.scookie.cocode#">
			<!---  end :  ENC51115-79853 --->
	        <cfset Local.listOrgUnit = "">
	        
	        <cfquery name="local.qCekIfPlanned" datasource="#request.sdsn#">
	        	SELECT CASE WHEN plan_startdate IS NULL THEN 0 ELSE 1 END useplan 
	            FROM TPMMPERIOD
				WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfif qCekIfPlanned.useplan>
		        <cfquery name="local.qCekIfUsed" datasource="#request.sdsn#">
		        	SELECT component_code FROM TPMDPERIODCOMPONENT
					WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
		        </cfquery>
		        <cfset local.lstUsed = valuelist(qCekIfUsed.component_code)>

		        <cfset local.strckRet = structnew()>
		       	<cfset strckRet["perskpi"] = false>
	    	   	<cfset strckRet["orgkpi"] = true>
	        
		        <!--- cek PERSKPI --->
	    	    <cfquery name="Local.qCheckPersKPI" datasource="#request.sdsn#">
					SELECT  PH.request_no, PH.reviewee_unitpath FROM TPMDPERFORMANCE_PLANH PH
					INNER JOIN TPMDPERFORMANCE_PLAND PD
						ON PD.form_no = PH.form_no
						AND PD.company_code = PH.company_code
					WHERE PH.isfinal = 1
						AND PH.reviewee_empid = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
						AND PH.reviewee_posid = <cfqueryparam value="#arguments.posid#" cfsqltype="cf_sql_varchar">
						AND PH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
                     order by PH.created_date desc
		        </cfquery>
			
		        <cfquery name="local.qCekPersReq" datasource="#request.sdsn#">
					SELECT status FROM TCLTREQUEST 
	        	    WHERE req_type = 'PERFORMANCE.PLAN'
	            		AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		                AND req_no = <cfqueryparam value="#qCheckPersKPI.request_no#" cfsqltype="cf_sql_varchar">
	    	    </cfquery>
				
		        <cfif listfindnocase("3,9",qCekPersReq.status)>
	    	    	<cfset strckRet["perskpi"] = true>
	            
					<!---<cfset listOrgUnit = qCheckPersKPI.reviewee_unitpath>--->
		            <cfquery name="local.qGetDeptId" datasource="#request.sdsn#">
		            	SELECT DISTINCT dept_id FROM TEOMPOSITION
						WHERE position_id = <cfqueryparam value="#arguments.posid#" cfsqltype="cf_sql_integer">
						AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		            </cfquery>
	    	        <cfset listOrgUnit = qGetDeptId.dept_id>
		        </cfif>

		        <!--- cek ORGKPI --->
		        <cfset local.listValidOrgUnit = "">
	    	   <cfif len(listOrgUnit) neq 0 >
		             <cfloop list="#listOrgUnit#" index="local.orgunitidx">
	        	    <cfif orgunitidx neq 0>
	        	
					<cfset local.listValidOrgUnit = listappend(listValidOrgUnit,orgunitidx)>
		   	    	<cfset strckRet["#orgunitidx#"] = false>
	            
			        <cfquery name="local.qCheckOrgKpi" datasource="#request.sdsn#">
			        	SELECT DISTINCT request_no FROM TPMDPERFORMANCE_PLANKPI
	    		        WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	        		    	AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
							AND orgunit_id = <cfqueryparam value="#orgunitidx#" cfsqltype="cf_sql_integer">
			        </cfquery>
					<cfquery name="local.qCekOrgReq" datasource="#request.sdsn#">
						SELECT DISTINCT status FROM TCLTREQUEST 
			            WHERE req_type = 'PERFORMANCE.PLAN'
	   			        	AND company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer">
	       			        AND req_no = <cfqueryparam value="#qCheckOrgKpi.request_no#" cfsqltype="cf_sql_varchar">
			        </cfquery>
					
			        <cfif listfindnocase("3,9",qCekOrgReq.status)>
						<cfquery name="local.qCheckOrgKpi" datasource="#request.sdsn#">
			    	    	SELECT DISTINCT evalkpi_status FROM TPMDPERFORMANCE_EVALKPI
			        	    WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
		    	        		AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
								AND orgunit_id = <cfqueryparam value="#orgunitidx#" cfsqltype="cf_sql_integer">
			        	</cfquery>
						
		    	        <cfif qCheckOrgKpi.evalkpi_status eq 3>
		   	    	    	<cfset strckRet["#orgunitidx#"] = true>
		        	    </cfif>
			        </cfif>
	            
		            <cfif not strckRet["#orgunitidx#"]>
			            <cfset strckRet["orgkpi"] = false>
		            </cfif>
		        </cfif>
		        </cfloop>
	            <cfelse>
	                <cfset strckRet["orgkpi"] = false>
		        </cfif>
	        
		        <cfset strckRet["listorgunit"] = listValidOrgUnit>
		        <!--- VALIDATE NEW UI --->
		        <cfset flagnewui = "#REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE#">
				<!--- <cf_sfwritelog dump="strckRet,lstUsed,qCekPersReq,qCheckPersKPI" prefix="lstUsedkedua">  --->
                <cfif not strckRet["perskpi"] and listfindnocase(lstUsed,"persKPI")>
		    	    <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSPersonal Objective is not yet set in planning",true)>
    		    	<cfoutput>
    			        <script>
    						alert("#LOCAL.SFLANG#");
    				
    					</script>
    			      </cfoutput>
			     
				  
			        </cfif>
			         <cfif not strckRet["orgkpi"] and listfindnocase(lstUsed,"orgKPI")>
	    	    
			        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSOrg Unit Objective must be set before",true)>
			        
    			    	<cfoutput>
    	    		    	<script>
    							alert("#LOCAL.SFLANG#");
    					
    						</script>
    			        </cfoutput>
			      
		        </cfif>
		            <cfreturn false> 
				

	        <cfelse>
	            <cfreturn true>
			</cfif>
	    </cffunction>
	   	    


	    <cffunction name="ValidateForm" access="public" returntype="boolean">
			<cfargument name="iAction" type="numeric" required="yes">
			<cfargument name="strckFormData" type="struct" required="yes">
	    	<cfparam name="action" default="0">
	    	<cfparam name="sendtype" default="0">
	        
	       	<cfset local.headstatus = 0>
	        <cfif sendtype eq 'directfinal'>
	        	<cfset headstatus = 1/>
	        <cfelseif action eq 'sendtoapprover' or sendtype eq 'next'>
	        	<cfset headstatus = 1/>
			<cfelseif action eq 'draft'>
	        	<cfset headstatus = 1/>
	        </cfif>

			<cfquery name="local.qDetailReviewee" datasource="#request.sdsn#">
				SELECT  grade_code, employ_code, position_id 
				FROM TEODEMPCOMPANY 
				WHERE emp_id = <cfqueryparam value="#strckFormData.requestfor#" cfsqltype="cf_sql_varchar">
				and status = 1
			</cfquery>
	        
	        <cfset local.retvar = true>
			
	        <cfif (listfindnocase(ucase(listPeriodComponentUsed),"ORGKPI") or listfindnocase(ucase(listPeriodComponentUsed),"PERSKPI")) and headstatus eq 1>
	            <cfset retvar = cekOrgPersKPI(FORM.period_code,strckFormData.reference_date,strckFormData.requestfor,qDetailReviewee.position_id,REQUEST.SCOOKIE.COID,REQUEST.SCOOKIE.COCODE)> 
	        </cfif>
	        
    		<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()> 
    		
			<cfreturn retvar>
		</cffunction>
		 <cffunction name="qDataUploadAtt">
        
		    <cfargument name="formno" default="">
            <cfargument name="kpitype" default="">
            <cfargument name="performance_period" default="">
            <cfargument name="empid" default="">
            <cfargument name="reviewee_empid" default="">
            
            <cfquery name="LOCAL.qDataUpload" datasource="#request.sdsn#">
            SELECT TV.form_no,TV.file_attachment,a.full_name,a.emp_id
            FROM TPMDPERF_EVALATTACHMENT TV
            INNER JOIN teomemppersonal a ON A.emp_id = TV.reviewer_empid
            WHERE 
            TV.period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
                AND TV.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
                AND TV.lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
                AND TV.reviewer_empid <> <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                AND TV.reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
				order by TV.created_date desc
            </cfquery>
            
            <cfreturn qDataUpload>
        </cffunction>
		  <cffunction name="checkUploadAtt">
        
		    <cfargument name="formno" default="">
            <cfargument name="kpitype" default="">
            <cfargument name="performance_period" default="">
            <cfargument name="empid" default="">
            <cfargument name="reviewee_empid" default="">
            
            <cfquery name="LOCAL.qGetExistingEvalTech" datasource="#request.sdsn#">
            SELECT form_no,file_attachment
            FROM TPMDPERF_EVALATTACHMENT 
            WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
                AND period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
                AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
                AND lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
                AND reviewer_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                AND reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
            </cfquery>
            
            <cfreturn qGetExistingEvalTech>
        </cffunction>
        
        <cffunction name="deleteAttachment">
            <cfparam name="formno" default="">
            <cfparam name="kpitype" default="">
            <cfparam name="idxattachment" default="">        
            <cfparam name="performance_period" default="">     
            <cfparam name="empid" default = "#request.scookie.user.empid#" >
            <cfparam name="reviewee_empid" default="">
            <cfparam name="FileName" default="">
			<cfquery name="LOCAL.qUpdateEvalAttch" datasource="#request.sdsn#" result="LOCAL.vresult">
				DELETE FROM  TPMDPERF_EVALATTACHMENT 
				WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
				AND period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
				AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
				AND lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
				AND file_attachment = <cfqueryparam value="#FileName#" cfsqltype="cf_sql_varchar">
				AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
				AND reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
			</cfquery>
     
        <CF_SFUPLOAD ACTION="DELETE" CODE="evalattachment" FILENAME="#FileName#" output="xlsuploadedDelete">
            <cfoutput>
               <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSAttachment Deleted",true)>
                <script>
                    alert("#SFLANG#");
                 var retContentAtt = `
                     <input id="inp_fileupload_#idxattachment#" name="inp_fileupload_#idxattachment#" type="File" value="" onfocus="" size="30" maxlength="50" style="width: 200px;float: left;" onchange="" title="">
	                    <a id="btn_fileupload_attachment_#idxattachment#" href="##" class="button" style="font-size: smaller;box-shadow: 0px 0px 5px ##919191 !important;" onclick="startUploadAttach#kpitype#('inp_fileupload_#idxattachment#','#idxattachment#')" >
                            <span>Upload</span>
                        </a>`;
                
                parent.$("[id=upload_attach_#kpitype#]").html(retContentAtt);
                </script>
            </cfoutput>
        </cffunction>
          <!--- <cffunction name="deleteAttachment">
        <cfparam name="formno" default="">
        <cfparam name="kpitype" default="">
        <cfparam name="idxattachment" default="">        
        <cfparam name="performance_period" default="">     
        <cfparam name="empid" default = "#request.scookie.user.empid#" >
        <cfparam name="FileName" default="">
        
     <cfquery name="LOCAL.qUpdateEvalAttch" datasource="#request.sdsn#" result="LOCAL.vresult">
            UPDATE  TPMDPERF_EVALATTACHMENT 
            SET file_attachment = NULL
             WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
                AND period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
                AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
                AND lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
                AND file_attachment = <cfqueryparam value="#FileName#" cfsqltype="cf_sql_varchar">
        </cfquery>
     
        <CF_SFUPLOAD ACTION="DELETE" CODE="evalattachment" FILENAME="#FileName#" output="xlsuploadedDelete">
 
       <cfoutput>
            <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSAttachment Deleted",true)>
            <script>
                  alert('Attachment Deleted');
              
            </script>
           <script>
                alert('#SFLANG#');
                var retContentAtt = '
                     <input id="inp_fileupload_#idxattachment#" name="inp_fileupload_#idxattachment#" type="File" value="" onfocus="" size="30" maxlength="50" style="width: 200px;float: left;" onchange="" title="">
	                    <a id="btn_fileupload_attachment_#idxattachment#" href="##" class="button" style="font-size: smaller;box-shadow: 0px 0px 5px ##919191 !important;" onclick="startUploadAttach('inp_fileupload_#idxattachment#','#idxattachment#')" >
                            <span>Upload</span>
                        </a>';
                
                parent.$("[id=upload_attach_#kpitype#]").html(retContentAtt);
            </script>
        </cfoutput>
    </cffunction>--->
        <cffunction name="uploadAttachment">
        
		<cfparam name="formno" default="">
        <cfparam name="kpitype" default="">
        <cfparam name="inp_uploadfield" default="">
        <cfparam name="idxattachment" default="">
        <cfparam name="performance_period" default="">
        <cfparam name="empid" default="request.scookie.user.empid">
        <cfparam name="reviewee_empid" default="">
        
       <!--- <cfdump var="#formno#">
        <cfdump var="#kpitype#">
        <cfdump var="#inp_uploadfield#">
        <cfdump var="#idxattachment#">
        <cfdump var="#performance_period#">
        <cfdump var="#empid#">--->
        

        <cfparam name="evaldateattachment_#idxattachment#" default="">
        <cfset LOCAL.currmondateattachment = Evaluate('evaldateattachment_#idxattachment#') >

        <cfset LOCAL.renameFile="#formno#_#idxattachment#_#empid#">
        <cfset LOCAL.subfolderpath = dateformat(now(),'YYYY#APPLICATION.OSSPT#MM') >
        <cfset LOCAL.SFLANG1=Application.SFParser.TransMLang("JSExtension of the uploaded file was not accepted",true)>
        <CF_SFUPLOAD ACTION="UPLOAD" CODE="evalattachment" FILEFIELD="fileupload_#idxattachment#" REWRITE="YES"  SUBFOLDER="#subfolderpath#" output="xlsuploaded">
   
      		<cfset  LOCAL.file_name_save = xlsuploaded.serverfile />
      	
         <cfset filetemp = replace(file_name_save,"/",",","All")>
       
        <cfset namefile =ListLast(filetemp)>
       
        <cfquery name="LOCAL.qGetExistingEvalTech" datasource="#request.sdsn#">
            SELECT form_no
            FROM TPMDPERF_EVALATTACHMENT 
            WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
                AND period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
                AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
                AND lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
                AND reviewer_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                AND reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
                
        </cfquery>
     
        	
        <cfif qGetExistingEvalTech.recordcount eq 0 AND file_name_save neq "">
		  <cfquery name="local.insertevalattachment" datasource="#request.sdsn#" result="local.req">
                INSERT INTO TPMDPERF_EVALATTACHMENT  
                (form_no,company_id,lib_type,reviewer_empid,period_code,file_attachment,created_by,created_date,modified_by,modified_date,reviewee_empid)
                VALUES (
                <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#file_name_save#" cfsqltype="cf_sql_varchar">
                ,<cfqueryparam value="#REQUEST.SCookie.User.uname#" cfsqltype="CF_SQL_VARCHAR">
                ,#CreateODBCDateTime(Now())#
                ,<cfqueryparam value="#REQUEST.SCookie.User.uname#" cfsqltype="CF_SQL_VARCHAR">
                ,#CreateODBCDateTime(Now())#,
                <cfqueryparam value="#reviewee_empid#" cfsqltype="CF_SQL_VARCHAR">
                )
            </cfquery>
		<cfelse>
		<cfif file_name_save neq "">
			<cfquery name="LOCAL.qUpdateEvalAttch" datasource="#request.sdsn#" result="LOCAL.vresult">
				UPDATE  TPMDPERF_EVALATTACHMENT 
				SET file_attachment = <cfqueryparam value="#file_name_save#" cfsqltype="cf_sql_varchar"> 
				 WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
					AND period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
					AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
					AND lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
					AND reviewer_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					AND reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
		   
			</cfquery>
		</cfif>
      
		</cfif>
		
        <cfoutput>
            <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSAttachment uploaded",true)>
			<cfset LOCAL.tempFileUrl = URLEncodedFormat(file_name_save)><!---pakai url encoded karena ada bugs double whitespace di cf--->
            <script>
                alert('#SFLANG#');
                 
                var retContentAtt = `
                    <a target="_blank" href="?sfid=sys.util.getfile&amp;download=true&amp;code=evalattachment&amp;fname=#tempFileUrl#">#HTMLEDITFORMAT(namefile)#</a>
        	        <img src="/sf6lib/images/icons/delete.png" class="delfilebtn" title="Delete File" alt="" onclick="deleteAttachmentEval#kpitype#('inp_fileupload_#idxattachment#','#idxattachment#','#file_name_save#')" style="cursor: pointer;" height="15px">`;
                
                parent.$("[id=upload_attach_#idxattachment#]").html(retContentAtt);
            </script>
        </cfoutput>

	</cffunction>

        
        	<cffunction name="Upload">

		    <cfparam name="del_prev" default="0">
			<cfparam name="detail" default="">
			<cfset LOCAL.qFailedData = QueryNew("ROW,COLUMN,REASON")>
			<cfset LOCAL.lstHeaderColumn = "EMPNO,EMP_NAME,PERIOD_CODE,FINAL_SCORE">
			<cfset LOCAL.nColumn = ListLen(lstHeaderColumn,",")> 
			<cfset LOCAL.tempRow = 0>
			<cfset errDetail = "">
			            <cfset LOCAL.SFLANGTEMPLATE=Application.SFParser.TransMLang("JSPlease Check Your Template KPI Library",true)>
			<cfif not isdefined("process")>
				<CF_SFUPLOAD ACTION="UPLOAD" CODE="planningupload" FILEFIELD="fileupload" onerror="parent.refreshPage();" output="xlsuploaded">
			
				<cfif xlsuploaded.ClientFileExt eq "xls">
				    <cfset  LOCAL.strFileExcel = xlsuploaded.SERVERDIRECTORY & "/" & xlsuploaded.SERVERFILE />
					<cfspreadsheet action="read" src="#strFileExcel#" columns = "1-#val(nColumn)#"  query="Local.qdata" headerrow="1" excludeHeaderRow="true" >
							<!---validasi header excel template--->
			<cfloop list="#lstHeaderColumn#" index="LOCAL.idxhead">
                <cfif NOT structKeyExists(qData, idxhead)>
                    <cfoutput>
                       
                	    <script>
                		    alert("#SFLANGTEMPLATE#");	
                            parent.maskButton(false);
                            parent.reloadPage();
                		</script>
                		<cf_sfabort>
                	</cfoutput>
                </cfif>
			</cfloop>
			<!---validasi header excel template--->
					<!--- TCK1018-81928 - Validasi Enterprise User --->
					<cfif qData.recordcount neq 0 >
                    	<cfset LOCAL.listSelectedParticipant = ValueList(qData.empno)>
                    	<cfset LOCAL.objEnterpriseUser= CreateObject("component", "SFEnterpriseUser") />
                    	<cfset LOCAL.retValidateEntSum=objEnterpriseUser.isEntExceedWithDefinedEmp(lstEmp_no=listSelectedParticipant)>
                        <cfif retValidateEntSum.retVal EQ false>
                            <cfset LOCAL.SFLANG=retValidateEntSum.message>
                    		<cfif REQUEST.SCOOKIE.MODE EQ "SFGO">
                                <cfset LOCAL.scValid={isvalid=false,result=""}>
                                <cfset scValid.result=SFLANG>
                                <cfreturn scValid/>
                    		<cfelse>
                        		<cfoutput>
                        			<script>
                        				alert("#SFLANG#");
            							parent.refreshPage();
        							</script>
                        		</cfoutput>
                        	</cfif>
        					<cf_sfabort/>
                    			<cfreturn false>
                        </cfif>
					</cfif>
						<!--- /TCK1018-81928 - Validasi Enterprise User --->
					<cfif ListLen(qdata.columnlist) neq ListLen(lstHeaderColumn)>
						<cfset LOCAL.SFLANG4=Application.SFParser.TransMLang("JSPlease check your file",true)>
						<cfoutput>
							<script>
								alert("#SFLANG4#");
								parent.refreshPage();	
							</script>
							<CF_SFABORT>
						</cfoutput>
					</cfif>
					<cfset LOCAL.TRANS_ID = "EVALUATION_UPLOAD#REQUEST.SCookie.User.empid##DateFormat(now(),'yyyymmdd')##TimeFormat(now(),'hhmmss')#">
					<cfif request.dbdriver eq "MYSQL">
						<cfquery name="LOCAL.qGetLastId" datasource="#REQUEST.SDSN#">
							SELECT MAX(id) AS maxid FROM TPMDWDDXTEMP
						</cfquery>
						
							 
							<cfif qGetLastId.maxid eq "">
								<cfset LOCAL.tempid = 1>
							<cfelse>
								<cfset LOCAL.tempid = val(qGetLastId.maxid)+1>
							</cfif>
					</cfif>
					<cfwddx action = "cfml2wddx" input = "#qData#" output = "LOCAL.query_wddx">
					<cfquery name="LOCAL.qInsPlanningWDDX" datasource="#REQUEST.SDSN#">
					<cfif request.dbdriver eq "MYSQL">
						INSERT INTO TPMDWDDXTEMP (id,trans_code,wddx,status,created_by,created_date,modified_by,modified_date,current_row,total) 
					    VALUES(<cfqueryparam value="#tempid#" cfsqltype="CF_SQL_INTEGER">
					    ,<cfqueryparam value="#TRANS_ID#" cfsqltype="CF_SQL_VARCHAR">
						,<cfqueryparam value="#query_wddx#" cfsqltype="CF_SQL_VARCHAR">
						,1
						,'#request.scookie.user.uname#'
						,#CreateODBCDateTime(Now())#
						,'#request.scookie.user.uname#'
						,#CreateODBCDateTime(Now())#
						,1
						,<cfqueryparam value="#qData.recordcount#" cfsqltype="cf_sql_integer">
						 )
					<cfelse>
						INSERT INTO TPMDWDDXTEMP (trans_code,wddx,status,created_by,created_date,modified_by,modified_date,current_row,total) 
						VALUES(
							<cfqueryparam value="#TRANS_ID#" cfsqltype="CF_SQL_VARCHAR">
							,<cfqueryparam value="#query_wddx#" cfsqltype="CF_SQL_VARCHAR">
							,1
							,'#request.scookie.user.uname#'
							,#CreateODBCDateTime(Now())#
							,'#request.scookie.user.uname#'
							,#CreateODBCDateTime(Now())#
							,1
							,<cfqueryparam value="#qData.recordcount#" cfsqltype="cf_sql_integer">
							)
					</cfif>
					</cfquery>
				    <cfif request.dbdriver eq "MYSQL">
						<cfset LOCAL.tempid = tempid + 1>
					</cfif>
					<cfoutput>
						<script>
							parent.showProgressBar(#qData.recordcount#,'#TRANS_ID#','#del_prev#');
						</script>
					</cfoutput>	
					<cfelse>
						<cfset LOCAL.SFLANG4=Application.SFParser.TransMLang("JSPlease upload xls format file",true)>
						<cfoutput>
							<script>
								alert("#SFLANG4#");
								maskButton(false);		
								parent.refreshPage();	
							</script>
							 <CF_SFABORT>
						</cfoutput>
					</cfif>
					<CF_SFUPLOAD ACTION="DELETE" CODE="planningupload" FILENAME="#xlsuploaded.SERVERFILE#" output="xlsuploadedDelete">
			    <cfelse>
					<cfset LOCAL.tempRow = tempRow + 1>
					<cfset request.doctype="xml">
					<cfquery name="LOCAL.qTransCode" datasource="#REQUEST.SDSN#">
						SELECT max(trans_code) as trans_code FROM TPMDWDDXTEMP
						WHERE  trans_code = '#trans_id#'
					</cfquery>
					<cfquery name="LOCAL.qGetWddx" datasource="#REQUEST.SDSN#">
						SELECT wddx,current_row,total 
						FROM TPMDWDDXTEMP WHERE trans_code =<cfqueryparam value="#qTransCode.trans_code#" cfsqltype="CF_SQL_VARCHAR">
					</cfquery>
					<cfwddx action = "wddx2cfml" input = "#qGetWddx.wddx#" output = "qData">
					<cfif qGetWddx.total lte 100 or qGetWddx.current_row eq 2>
						<cfset LOCAL.varMaxRows = 10>
					<cfelse>
						<cfset LOCAL.varMaxRows = 100>
					</cfif>
					<cfset LOCAL.CuPo = qGetWddx.current_row>
					<cfif (CuPo gt 1) and (CuPo+1 lte qGetWddx.total)>
						<cfset LOCAL.CuPo = CuPo+1>    
					</cfif>
					<cfset LOCAL.varEndPos = CuPo + varMaxRows - 1>
					<cfset local.isReadytoExecute = true>
					<cfset LOCAL.tempRow = 0>
					<cfset LOCAL.empnotemp = "">
				    <cfloop query="qData"  startrow="#CuPo#" endrow="#varEndPos#">
				        <cfquery name="LOCAL.qCheckPeriodCode" datasource="#REQUEST.SDSN#">
							SELECT period_code,score_type,conclusion_lookup,reference_date from TPMMPERIOD where 
							period_code =  <cfqueryparam value="#qData.period_code#" cfsqltype="CF_SQL_VARCHAR"> 
						</cfquery>
						<cfquery name="qCheckScore" datasource="#REQUEST.SDSN#">
							SELECT a.score_code, b.score_desc, b.score_type, a.scoredet_mask,
							a.scoredet_value, a.scoredet_desc
							FROM TGEDSCOREDET a inner join TGEMSCORE b on a.score_code=b.score_code
							WHERE 
							<cfif qCheckPeriodCode.recordcount gt 0>
							    a.score_code = '#qCheckPeriodCode.conclusion_lookup#'
							    <cfelse>
						        1=0
							</cfif>
						
							ORDER BY a.scoredet_value desc
						</cfquery>
						<cfif empnotemp neq qData.empno>
							<cfset LOCAL.form_no = Application.SFUtil.getCode("PERFEVALFORM",'no','true')>  <!---for generate form no ---->
							<cfset LOCAL.req_no = Application.SFUtil.getCode("PERFORMANCEPLAN",'no','true','false','true')> <!---for generate request no ---->
					    </cfif>
						<cfset LOCAL.empnotemp = qData.empno>
						<cfset LOCAL.local.isReadytoExecute = true>
						<cfset LOCAL.tempRow = qData.currentrow>
						<cfset local.strctPlanH = StructNew()>
						<cfquery name="LOCAL.qUpdCurRow" datasource="#REQUEST.SDSN#">
							UPDATE TPMDWDDXTEMP set current_row= <cfqueryparam value="#qData.currentrow#" cfsqltype="CF_SQL_INTEGER"> 
							WHERE trans_code=<cfqueryparam value="#qTransCode.trans_code#" cfsqltype="CF_SQL_VARCHAR">
						</cfquery>
						<cfset LOCAL.idx="">
						<cfloop list="#lstHeaderColumn#" index="idx">
						    
							<cfset LOCAL.tempQData = Evaluate("qData.#idx#")>
							<cfif Trim(tempQData) eq "">
							    <cfif idx neq "EMP_NAME">
							        <cfset LOCAL.temp = QueryAddRow(qFailedData)>    
								    <cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
								    <cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
								    <cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Data #idx# is required")>
								    <cfset local.isReadytoExecute = false>
							    </cfif>
							
							<cfelse>
								<cfif UCASE(idx) eq "EMPNO">
									<cfquery name="qCheckEmp" datasource="#REQUEST.SDSN#">
										SELECT EMP_ID, position_id, grade_code, employ_code FROM TEODEMPCOMPANY WHERE EMP_NO =  <cfqueryparam value="#qData.empno#" cfsqltype="CF_SQL_VARCHAR"> 
										AND company_id =   <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
										AND status = 1
								    </cfquery>
									<cfif qCheckEmp.recordcount eq 0 >
										<cfset LOCAL.temp = QueryAddRow(qFailedData)>   
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Employee No #qData.empno# is not registered in this company")>		
										<cfset local.isReadytoExecute = false>
									<cfelse>
										<cfset local.isReadytoExecute = true>
								    </cfif>
								</cfif>
								<cfif UCASE(idx) eq "PERIOD_CODE">
								
									<cfif qCheckPeriodCode.recordcount eq 0 >
										<cfset LOCAL.temp = QueryAddRow(qFailedData)>   
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Period Code #qData.period_code# is missing")>		
									<cfelse>
										<cfset local.isReadytoExecute = true>
									   
										<cfif qCheckScore.recordcount neq 0>
										    <cfset scoredet = valuelist(qCheckScore.scoredet_value)>
										</cfif>
								    </cfif>
								</cfif>
								<cfif UCASE(idx) eq "FINAL_SCORE">
									<cfif qData.final_score eq ''>
									    <cfset LOCAL.temp = QueryAddRow(qFailedData)>   
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
								        <cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Final Score is Empty")>		
									<cfelse> 
									    <cfif qCheckScore.recordcount eq 0>
											<cfset LOCAL.temp = QueryAddRow(qFailedData)>   
											<cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
											<cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
											<cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Final Conclusion is not found")>		
											<cfset local.isReadytoExecute = false>
									   <cfelse>
											<cfset tempscore= qData.final_score>
											<cfset tempMask = ''>
											
										    <cfloop query='qCheckScore'>
											    <cfif qData.final_score lte qCheckScore.scoredet_value>
											        <cfset tempMask = qCheckScore.scoredet_mask>
												<cfelse>
													 <cfbreak>
												</cfif>
											</cfloop>  
											<cfif tempMask eq ''>
												<cfset LOCAL.temp = QueryAddRow(qFailedData)>   
												<cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
											    <cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
											    <cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Final Conclusion is not found")>			
											    <cfset local.isReadytoExecute = false>
											<cfelse>
												<cfset local.isReadytoExecute = true>
											</cfif> 
											<cfset local.isReadytoExecute = true>
											<cfif isReadytoExecute eq true>
											   <cfset local.isReadytoExecute = true> 
                                                    <cfquery name="qCheckPerfFinal" datasource="#REQUEST.SDSN#">
													   select form_no , company_code from TPMDPERFORMANCE_FINAL where
													   period_code =  <cfqueryparam value="#qCheckPeriodCode.period_code#" cfsqltype="cf_sql_varchar">
													   and reviewee_empid =  <cfqueryparam value="#qCheckEmp.emp_id#" cfsqltype="cf_sql_varchar">
													</cfquery>
													<cfif qCheckPerfFinal.recordcount neq 0>
													   <cfquery name="Local.qUpdateFinalData" datasource="#request.sdsn#">
	    				                                   UPDATE TPMDPERFORMANCE_FINAL 
	    				                                   SET final_score = <cfqueryparam value="#qData.final_score#" cfsqltype="cf_sql_varchar">
	    				                                   ,final_conclusion = <cfqueryparam value="#tempMask#" cfsqltype="cf_sql_varchar">
	    				                                   ,modified_by = <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">
	    				                                   ,modified_date = <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>
	    				                                   ,ori_conclusion = <cfqueryparam value="#tempMask#" cfsqltype="cf_sql_varchar">
	    			                                        WHERE form_no = <cfqueryparam value="#qCheckPerfFinal.form_no#" cfsqltype="cf_sql_varchar">
	    	                                               AND company_code = <cfqueryparam value="#qCheckPerfFinal.company_code#" cfsqltype="cf_sql_varchar">
	    			                                    </cfquery>
												    <cfelse> 
													    <cfquery name="qInsertPerfFinal" datasource="#REQUEST.SDSN#">
													       INSERT INTO TPMDPERFORMANCE_FINAL (form_no,	company_code, period_code, reference_date, 
	                                                       reviewee_empid, reviewee_posid, reviewee_grade, reviewee_employcode, final_score, 
	                                                       final_conclusion, created_by, created_date, modified_by, modified_date, ori_conclusion,is_upload)
	                                                       values(
	                                                            <cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#qCheckPeriodCode.period_code#" cfsqltype="cf_sql_varchar">,     
	                                                            <cfqueryparam value="#qCheckPeriodCode.reference_date#" cfsqltype="cf_sql_timestamp">,
	                                                            <cfqueryparam value="#qCheckEmp.emp_id#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#qCheckEmp.position_id#" cfsqltype="cf_sql_integer">,
	                                                            <cfqueryparam value="#qCheckEmp.grade_code#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#qCheckEmp.employ_code#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#qData.final_score#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#tempMask#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
	                                                            <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
	                                                            <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
	                                                            <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
	                                                            <cfqueryparam value="#tempMask#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="Y" cfsqltype="cf_sql_varchar">
	                                                       )
	                                                   </cfquery>
	                                                                       
													</cfif>
													                   
											</cfif>
										</cfif>
								</cfif>
							</cfif>
						</cfif>
                    </cfloop>
                    <cfset LOCAL.detail = detail & "<DATA><ROWSEKARANG>#qData.currentrow#</ROWSEKARANG><DEL_PREV>#DEL_PREV#</DEL_PREV><NILAI>#qData.recordcount#</NILAI><HEADIDTEMP>#qTransCode.trans_code#</HEADIDTEMP></DATA>"> 

                </cfloop>                                
  			</cfif>		
  			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed Performance Planning Upload",true)>
			<cfset LOCAL.SFLANG2=Application.SFParser.TransMLang("JSThis Employee already has Performance Evaluation Form",true)>
		    <cfset LOCAL.LstFailed = "">
            <cfif qFailedData.recordcount gt 0>
			   <cfloop query="qFailedData" >
					<cfset LOCAL.LstFailed =ListAppend(LstFailed,"#ROW#~#REASON#","|")>
					<cfset LOCAL.tempString = "<DATA><ERROR><ROW>#ROW#</ROW><REASON>#reason#</REASON></ERROR></DATA>">
					<cfif FindNoCase(tempString,detail) eq 0>
						<cfset LOCAL.detail = detail & tempString>
					</cfif>
			   </cfloop>
            </cfif>
                 
            <cfoutput>
                <cfxml variable="LOCAL.MyDoc"> 
                    <MyDoc>
                        #detail#
                    </MyDoc>
                </cfxml>                
                #MyDoc#        
            </cfoutput>
	</cffunction>
    
		<cffunction name="SaveTransaction">
	    	<cfargument name="iAction" type="numeric" required="yes">
	    	<cfargument name="strckFormData" type="struct" required="yes">
	    	<cfparam name="action" default="0">
	    	<cfparam name="sendtype" default="0">
	    	<cfset local.existInPlan = false>
			<cfset local.nhead_status = 0>
			
	        <cfif sendtype eq 'directfinal'>
	        	<cfset strckFormData.isfinal = 1/>
	        	<cfset strckFormData.head_status = 1/>
				<cfset nhead_status = 1>
	        <cfelseif action eq 'sendtoapprover' or sendtype eq 'next'>
	        	<cfset strckFormData.head_status = 1/>
				<cfset nhead_status = 1>
			<cfelseif action eq 'draft'>
				<cfset nhead_status = 1>
				<cfset strckFormData.head_status = 0/>
	        </cfif>
		
			<cfquery name="local.qDetailReviewee" datasource="#request.sdsn#">
				SELECT  grade_code, employ_code, position_id 
				FROM TEODEMPCOMPANY 
				WHERE emp_id = <cfqueryparam value="#strckFormData.requestfor#" cfsqltype="cf_sql_varchar">
				and status = 1
			</cfquery>
			<cfquery name="local.qDetailReviewer" datasource="#request.sdsn#">
				SELECT  position_id 
				FROM TEODEMPCOMPANY 
				WHERE emp_id = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
			</cfquery>
	        
	        <cfset LOCAL.listPeriodComponentUsed = ListRemoveDuplicates(listPeriodComponentUsed) >
			<cfif (listfindnocase(ucase(listPeriodComponentUsed),"ORGKPI") or listfindnocase(ucase(listPeriodComponentUsed),"PERSKPI")) and nhead_status eq 1>
	            <cfset local.retvar = cekOrgPersKPI(FORM.period_code,strckFormData.reference_date,strckFormData.requestfor,qDetailReviewee.position_id,FORM.coid,FORM.cocode)> 
	        </cfif>
			
	        <!--- cek if exist in plan --->
	        <cfif len(strckFormData["planformno"])>
	        	<cfset existInPlan = true>
			<cfelseif len(strckFormData["formno"])>
				<cfset existInPlan = true>
	        </cfif>
	        
	        <!--- insert tabel header --->
			<cfset local.strckHeadData = StructNew()>
	        <cfif len(strckFormData["formno"])>
				<cfset strckHeadData["form_no"] = strckFormData.formno>
	        <cfelseif len(strckFormData["planformno"])>
				<cfset strckHeadData["form_no"] = strckFormData.planformno>
	        <cfelse>
				<cfset strckHeadData["form_no"] = trim(Application.SFUtil.getCode("PERFEVALFORM",'no','true'))>
	        </cfif>
	        
	        <!---
	        <cfif not len(strckFormData["formno"])>
				<cfset strckHeadData["form_no"] = trim(Application.SFUtil.getCode("PERFEVALFORM",'no','true'))>
	        <cfelse>
				<cfset strckHeadData["form_no"] = strckFormData.formno>
	        </cfif>
			--->
			
			<cfset strckHeadData["request_no"] = request_no><!--- ? --->
			<cfset strckHeadData["form_order"] = 1>
			<cfset strckHeadData["reference_date"] = strckFormData.reference_date>
			<cfset strckHeadData["period_code"] = FORM.period_code>
			<cfset strckHeadData["company_code"] = FORM.cocode> <!---modified by  ENC51115-79853 --->
			<cfset strckHeadData["coid"] = FORM.coid> <!---added by  ENC51115-79853 --->
			<cfset strckHeadData["reviewee_empid"] = strckFormData.requestfor>
			<cfset strckHeadData["reviewee_posid"] = qDetailReviewee.position_id>
			<cfset strckHeadData["reviewee_grade"] = qDetailReviewee.grade_code>
			<cfset strckHeadData["reviewee_employcode"] = qDetailReviewee.employ_code>
			<cfset strckHeadData["reviewer_empid"] = request.scookie.user.empid>
			<cfset strckHeadData["reviewer_posid"] = qDetailReviewer.position_id>
			<cfset strckHeadData["score"] = strckFormData.score>
			<cfset strckHeadData["conclusion"] = strckFormData.conclusion>
	    	<cfset strckHeadData["review_step"] = strckFormData.UserInReviewStep/>
	        <cfif structkeyexists(strckFormData,"isfinal")>
		    	<cfset strckHeadData["isfinal"] = strckFormData.isfinal/>
	        <cfelse>
		    	<cfset strckHeadData["isfinal"] = 0/>
	        </cfif>
	        <cfif structkeyexists(strckFormData,"head_status")>
		    	<cfset strckHeadData["head_status"] = strckFormData.head_status/>
	        <cfelse>
		    	<cfset strckHeadData["head_status"] = 0/>
	        </cfif>
			<cfset strckHeadData["lastreviewer_empid"] = request.scookie.user.empid>
	        
	        <cfset local.listlibtype="0">
	        <cfloop list="#listPeriodComponentUsed#" index="local.idxComp">
	            <cfif ucase(idxComp) neq "TASK" and ucase(idxComp) neq "FEEDBACK" and ucase(idxComp) neq "questionComp" and ucase(idxComp) neq "additionaldeductComp">
	                <cfset local.listexist = evaluate("#idxComp#_lib")>
	                <cfif listlen(trim(listexist))>
	                    <cfset listlibtype = listAppend(listLibType,idxComp)>
	                </cfif>
	            </cfif>
	        </cfloop>
	        
	        <!---Set use_point for additional dan deduction--->
			<cfquery name="local.qDDelOldCOMP" datasource="#request.sdsn#">
				DELETE FROM TPMDEVALD_COMPPOINT 
				WHERE form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
				    AND request_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
			</cfquery>
	        <cfif structkeyexists(strckFormData,"additionalpoint") OR structkeyexists(strckFormData,"deductpoint")>
		    	<cfset strckHeadData["use_point"] = 1/>
	        </cfif>
	        <cfif structkeyexists(strckFormData,"lstValCompCodeAdditional")>
		    	<cfloop list="#strckFormData['lstValCompCodeAdditional']#" index="local.idxcomcode">
    				<cfquery name="local.qInsertCOMP" datasource="#request.sdsn#">
    					INSERT INTO TPMDEVALD_COMPPOINT (form_no,request_no,comp_code,comp_type) 
    					VALUES(
    						<cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#idxcomcode#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="A" cfsqltype="cf_sql_varchar">
    					)				
    				</cfquery>
		    	</cfloop>
	        </cfif>
	        <cfif structkeyexists(strckFormData,"lstValCompCodeDeduction")>
		    	<cfloop list="#strckFormData['lstValCompCodeDeduction']#" index="local.idxcomcode">
    				<cfquery name="local.qInsertCOMP" datasource="#request.sdsn#">
    					INSERT INTO TPMDEVALD_COMPPOINT (form_no,request_no,comp_code,comp_type) 
    					VALUES(
    						<cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#idxcomcode#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="D" cfsqltype="cf_sql_varchar">
    					)				
    				</cfquery>
		    	</cfloop>
	        </cfif>
	        <!---Set use_point for additional dan deduction--->
			
	        <cftransaction>
			
	      	<cfquery name="local.qDelDataBefore" datasource="#request.sdsn#">
	           	DELETE FROM TPMDPERFORMANCE_EVALNOTE
	            WHERE form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
	                 AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
					 AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar">  <!----added by  ENC51115-79853 --->
	        </cfquery>
	        <cfquery name="local.qDelDataBefore" datasource="#request.sdsn#">
	           	DELETE FROM TPMDPERFORMANCE_EVALD
	            WHERE form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
	                AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
	                AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar">  <!----added by  ENC51115-79853 --->
	                AND (lib_type in (#ListQualify(listlibtype,"'",",","ALL")#)
					<cfif listPeriodComponentUsed neq "">
						 OR(lib_code in (#ListQualify(listPeriodComponentUsed,"'",",","ALL")#) and lib_type = 'COMPONENT')
					</cfif>
					)
	               
	        </cfquery>
	        <cfquery name="local.qDelDataBefore" datasource="#request.sdsn#">
	           	DELETE FROM TPMDPERFORMANCE_EVALH
	            WHERE request_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
	            	AND form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
	                AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar">  <!----added by  ENC51115-79853 --->
	                AND reviewee_empid = <cfqueryparam value="#strckHeadData.reviewee_empid#" cfsqltype="cf_sql_varchar">
	                AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
	                AND period_code = <cfqueryparam value="#strckHeadData.period_code#" cfsqltype="cf_sql_varchar">
	        </cfquery>
			<!---<cfquery name="qInsEvalH" datasource="#request.sdsn#">
	           	INSERT INTO TPMDPERFORMANCE_EVALH (form_no, request_no, form_order, reference_date, period_code, company_code, reviewee_empid, reviewee_posid, reviewee_grade, reviewee_employcode, reviewer_empid, reviewer_posid, score, conclusion, isfinal, review_step, head_status, lastreviewer_empid, created_by, created_date, modified_by, modified_date)
				VALUES ( <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.form_order#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.reference_date#" cfsqltype="cf_sql_timestamp">,
						<cfqueryparam value="#strckHeadData.period_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.company_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewee_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewee_posid#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.reviewee_grade#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewee_employcode#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewer_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewer_posid#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.score#" cfsqltype="cf_sql_float">,
						<cfqueryparam value="#strckHeadData.conclusion#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.isfinal#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.review_step#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.head_status#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.lastreviewer_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
				)
	        </cfquery>--->
			 <cfset local.retvar = variables.objPerfEvalH.Insert(strckHeadData)>
	       <!--- panggil fungsi untuk period component --->
	        <cfset Local.stringJSON = "">
	        <cfloop list="#listPeriodComponentUsed#" index="local.idxCompUsed">
	        	<cfif listfindnocase("APPRAISAL,ORGKPI,PERSKPI,COMPETENCY",ucase(idxCompUsed))>
			        <cfset local.listLib = "">
			        <cfif structkeyexists(FORM,"#idxCompUsed#_lib")>
				        <cfset local.listLib = FORM["#idxCompUsed#_lib"]>
			        </cfif>
	            	<cfif structkeyexists(FORM,"#idxCompUsed#Array")>
	                	<cfset stringJSON = FORM["#idxCompUsed#Array"]>
	                </cfif>
	                <cfif listlen(listLib)>
				       	<cfset saveEvalD(idxCompUsed,listlib,strckHeadData,stringJSON,existInPlan)>
	                </cfif>
	            </cfif>
	            
	            <!--- insert per komponen period yang dipakai --->
	            <cfset local.strckEvalD = structnew()>
		        <cfset strckEvalD["form_no"] = strckHeadData.form_no>
		        <cfset strckEvalD["company_code"] = FORM.cocode> <!----added by  ENC51115-79853 --->
				<cfset strckEvalD["coid"] = FORM.coid> <!----added by  ENC51115-79853 --->
		        <cfset strckEvalD["reviewer_empid"] = strckHeadData.reviewer_empid>
		        <cfset strckEvalD["reviewer_posid"] = strckHeadData.reviewer_posid>
		        <cfset strckEvalD["lib_type"] = "COMPONENT">
				<cfset strckEvalD["lib_code"] = ucase(idxCompUsed)>
				<!---<cfif ucase(idxCompUsed) neq "questionComp" AND ucase(idxCompUsed) neq "additionaldeductComp">--->
				<cfif ucase(idxCompUsed) neq "additionaldeductComp">
    	            <cfif ucase(idxCompUsed) eq "ORGKPI">
    			        <cfset strckEvalD["weight"] = strckFormData["objectiveorg_weight"]>
    			        <cfset strckEvalD["score"] = strckFormData["objectiveorg"]>
    			        <cfset strckEvalD["weightedscore"] = strckFormData["objectiveorg_weighted"]>
    	            <cfelseif ucase(idxCompUsed) eq "PERSKPI">
    			        <cfset strckEvalD["weight"] = strckFormData["objective_weight"]>
    			        <cfset strckEvalD["score"] = strckFormData["objective"]>
    			        <cfset strckEvalD["weightedscore"] = strckFormData["objective_weighted"]>
    	            <cfelse>
    			        <cfset strckEvalD["weight"] = strckFormData["#lcase(idxCompUsed)#_weight"]>
    			        <cfset strckEvalD["score"] = strckFormData["#lcase(idxCompUsed)#"]>
    			        <cfset strckEvalD["weightedscore"] = strckFormData["#lcase(idxCompUsed)#_weighted"]>
    	            </cfif>
    	            <cfset retvar = variables.objPerfEvalD.Insert(strckEvalD)> 
	            </cfif>
				
				<!---- <cfquery name="local.qInsertEvalD" datasource="#request.sdsn#">
					INSERT INTO TPMDPERFORMANCE_EVALD (form_no,reviewer_empid,reviewer_posid,lib_code,lib_type,company_code,weight,score,
	weightedscore,created_by,created_date,modified_by,modified_date) 
					VALUES(
						<cfqueryparam value="#strckEvalD.form_no#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.reviewer_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.reviewer_posid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_type#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.weight#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.score#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.weightedscore#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
					)				
				</cfquery> -----> <!--- remarked by maghdalenasp 2018-03-21 ---->
	            
	        </cfloop>
	        
			<!--- insert additional notes --->
	        <cfif structkeyexists(StrckFormData,"evalnoterecords")>
			<cfloop from="1" to="#StrckFormData.evalnoterecords#" index="local.idx">
				<cfset local.note_name = strckFormData["evalnotename_#idx#"]>
				<cfset local.note_answer = strckFormData["evalnote_#idx#"]>
				<cfquery name="local.qInsertAddNotes" datasource="#request.sdsn#">
					INSERT INTO TPMDPERFORMANCE_EVALNOTE (form_no,company_code,reviewer_empid,reviewer_posid,note_name,note_answer,note_order,created_by,created_date,modified_by,modified_date) 
					VALUES(
						<cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.company_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewer_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewer_posid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#note_name#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#note_answer#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#idx#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
					)				
				</cfquery>
			</cfloop>
	        </cfif>
	        
	        <!--- Insert ke Tabel Final --->
	        <cfif strckHeadData.isfinal eq 1>
		        <cfquery name="local.qCheckIfExistsInFinal" datasource="#request.sdsn#">
		             SELECT  EH.form_no,EH.company_code,EH.score,EH.conclusion FROM TPMDPERFORMANCE_FINAL F
		            LEFT JOIN TPMDPERFORMANCE_EVALH EH ON F.form_no = EH.form_no AND F.company_code = EH.company_code
		            WHERE EH.request_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar"> AND EH.isfinal = 1
		        </cfquery>
		        
		        <cfif not qCheckIfExistsInFinal.recordcount>
	    	        <cfquery name="Local.DelFinal" datasource="#request.sdsn#">
	    	            DELETE FROM TPMDPERFORMANCE_FINAL
	    	            WHERE form_no = <cfqueryparam value="#qCheckIfExistsInFinal.form_no#" cfsqltype="cf_sql_varchar">
	    	                AND company_code = <cfqueryparam value="#qCheckIfExistsInFinal.company_code#" cfsqltype="cf_sql_varchar">
	    			</cfquery>
	    	        <cfquery name="Local.qInsertFinalData" datasource="#request.sdsn#">
	    				INSERT INTO TPMDPERFORMANCE_FINAL (form_no,	company_code, period_code, reference_date, reviewee_empid, reviewee_posid, reviewee_grade, reviewee_employcode, final_score, final_conclusion, created_by, created_date, modified_by, modified_date, ori_conclusion)
	        	        SELECT EH.form_no, EH.company_code, EH.period_code, EH.reference_date, EH.reviewee_empid, EH.reviewee_posid, EH.reviewee_grade, EH.reviewee_employcode, EH.score AS final_score, EH.conclusion AS final_conclusion, '#request.scookie.user.uname#', <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>, '#request.scookie.user.uname#', <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>, EH.conclusion AS ori_conclusion
	    	            FROM TPMDPERFORMANCE_EVALH EH
	    			    WHERE request_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
	    	                AND isfinal = 1
	    			</cfquery>
	            <!---BUG50915-51098--->
	            <cfelse>
	                <cfquery name="Local.qUpdateFinalData" datasource="#request.sdsn#">
	    				UPDATE TPMDPERFORMANCE_FINAL 
	    				SET final_score = <cfqueryparam value="#qCheckIfExistsInFinal.score#" cfsqltype="cf_sql_varchar">
	    				,final_conclusion = <cfqueryparam value="#qCheckIfExistsInFinal.conclusion#" cfsqltype="cf_sql_varchar">
	    				,modified_by = <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">
	    				,modified_date = <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>
	    				,ori_conclusion = <cfqueryparam value="#qCheckIfExistsInFinal.conclusion#" cfsqltype="cf_sql_varchar">
	    			    WHERE form_no = <cfqueryparam value="#qCheckIfExistsInFinal.form_no#" cfsqltype="cf_sql_varchar">
	    	            AND company_code = <cfqueryparam value="#qCheckIfExistsInFinal.company_code#" cfsqltype="cf_sql_varchar">
	    			</cfquery>
	            </cfif>
	            <!---BUG50915-51098--->
	        </cfif>

	        <!--- Approved Data Request --->
	        <cfif strckHeadData.head_status eq 1 and (strckFormData.RevieweeAsApprover neq 1 or (strckFormData.RevieweeAsApprover eq 1 and strckFormData.requestfor neq request.scookie.user.empid))>
	            <cfquery name="local.qGetApprovedDataFromReq" datasource="#request.sdsn#">
	            	SELECT  approved_data FROM TCLTREQUEST
					WHERE req_type = 'PERFORMANCE.EVALUATION'
						AND req_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
						AND company_id = <cfqueryparam value="#FORM.coid#" cfsqltype="cf_sql_integer"> <!----added by  ENC51115-79853 --->
						AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar"> <!----added by  ENC51115-79853 --->
						and req_no <> ''
	            </cfquery>

	            <cfset LOCAL.strckApprovedData=SFReqFormat(qGetApprovedDataFromReq.approved_data,"R")>
	            <!---TW:<cfif IsJSON(qGetApprovedDataFromReq.approved_data)>
	                <cfset LOCAL.strckApprovedData=DeserializeJSON(qGetApprovedDataFromReq.approved_data)>
				<cfelseif IsWDDX(qGetApprovedDataFromReq.approved_data)>
					<cfwddx action="wddx2cfml" input="#qGetApprovedDataFromReq.approved_data#" output="LOCAL.strckApprovedData">
	            <cfelse>
					<cfset LOCAL.strckApprovedData = StructNew() />
	            </cfif>--->
				<cfset var strckFormInbox = StructNew() />
				<cfset strckFormInbox['DTIME'] = Now() />
				<cfset strckFormInbox['DECISION'] = 1 />
				<cfset strckFormInbox['NOTES'] = "" />
				<cfset LOCAL.apvdDataKey = request.scookie.user.uid >
				<cfif trim(qGetApprovedDataFromReq.approved_data) eq '' OR (isStruct(strckApprovedData) AND REFind('_', ListFirst(StructKeyList(strckApprovedData)) ) ) >
					<cfset LOCAL.cntStrckApprovedData = StructCount(strckApprovedData)+1 />
					<cfset apvdDataKey = NumberFormat(cntStrckApprovedData,'00')&'_'&apvdDataKey >
				</cfif>
				<cfset strckApprovedData[apvdDataKey] = strckFormInbox />
				<cfset LOCAL.wddxApprovedData=SFReqFormat(strckApprovedData,"W")>
				<!---TW:<cfwddx action="cfml2wddx" input="#strckApprovedData#" output="wddxApprovedData">--->
				
				
	   	       	<cfquery name="local.qUpdApprovedData" datasource="#request.sdsn#">
					UPDATE TCLTREQUEST
					SET approved_data = <cfqueryparam value="#wddxApprovedData#" cfsqltype="cf_sql_varchar">
					WHERE req_type = 'PERFORMANCE.EVALUATION'
						AND req_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
						AND company_id = <cfqueryparam value="#FORM.coid#" cfsqltype="cf_sql_integer"> <!----added by  ENC51115-79853 --->
						AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar"> <!----added by  ENC51115-79853 --->
				
				</cfquery>
	        </cfif>
	          	<cfquery name="local.qcheckEvalAttach" datasource="#request.sdsn#">
				  
                SELECT form_no,file_attachment
                FROM TPMDPERF_EVALATTACHMENT 
                WHERE period_code = <cfqueryparam value="#strckHeadData.period_code#" cfsqltype="cf_sql_varchar">
                AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
          
                AND reviewer_empid = <cfqueryparam value="#strckHeadData.reviewer_empid#" cfsqltype="cf_sql_varchar">
                AND reviewee_empid = <cfqueryparam value="#strckHeadData.reviewee_empid#" cfsqltype="cf_sql_varchar">
            </cfquery>
          
                	<cfquery name="local.updateformno" datasource="#request.sdsn#" result="qupdate" >
                	    update TPMDPERF_EVALATTACHMENT set form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
                	     WHERE period_code = <cfqueryparam value="#strckHeadData.period_code#" cfsqltype="cf_sql_varchar">
                AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
                AND reviewee_empid = <cfqueryparam value="#strckHeadData.reviewee_empid#" cfsqltype="cf_sql_varchar">
                	</cfquery>
                
	        </cftransaction>
	    </cffunction>
	    
	    
	    <cffunction name="saveEvalD">
	    	<cfargument name="libtype" default="">
	    	<cfargument name="listlib" default="">
	        <cfargument name="strckEval" default="">
	        <cfargument name="strJSON" default="">
	        <cfargument name="existInPlan" default="false">
	        <cfset local.strckEvalD = structnew()>
	        <cfset strckEvalD["form_no"] = strckEval.form_no>
	        <cfset strckEvalD["company_code"] = strckEval.company_code>
			<cfset strckEvalD["coid"] = strckEval.coid>
	        <cfset strckEvalD["reviewer_empid"] = strckEval.reviewer_empid>
	        <cfset strckEvalD["reviewer_posid"] = strckEval.reviewer_posid>
	        <cfset strckEvalD["lib_type"] = ucase(arguments.libtype)>
			<!--- anomali --->
			<cfif len(arguments.strJSON) and left(arguments.strJSON,1) eq " ">
	        	<cfset strJSON = Replace(strJSON, " ", "" ,"all")>
	        </cfif>
			<cfset local.objJSON = deserializeJSON(strJSON)>
	        <cfif len(arguments.listlib) and left(arguments.listlib,1) eq " ">
	        	<cfset listlib = Replace(listlib, " ", "" ,"all")>
	        </cfif>
	    
	        <cfset local.inputPrefix = "">
	        <cfif ucase(libtype) eq "APPRAISAL">
	        	<cfset inputPrefix = "appr">
	        <cfelseif ucase(libtype) eq "ORGKPI">
	        	<cfset inputPrefix = "org">
	        <cfelseif ucase(libtype) eq "PERSKPI">
	        	<cfset inputPrefix = "pers">
	        <cfelseif ucase(libtype) eq "COMPETENCY">
	        	<cfset inputPrefix = "comp">
	        </cfif>
			
			<cfquery name="local.qFromPlan" datasource="#request.sdsn#">
				SELECT  reviewer_empid,request_no FROM TPMDPERFORMANCE_PLANH
				WHERE form_no = <cfqueryparam value="#strckEvalD.form_no#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">
					AND reviewee_empid = <cfqueryparam value="#strckEval.reviewee_empid#" cfsqltype="cf_sql_varchar">
					AND isfinal = 1
			</cfquery>
			 
	        <!--- ambil library details baik dari plan jika ada/ dari period lib langsung --->
	        <cfif arguments.existInPlan and UCASE(libtype) eq "PERSKPI">
	            <cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
	                SELECT * FROM TPMDPERFORMANCE_PLAND
	                WHERE form_no = <cfqueryparam value="#strckEvalD.form_no#" cfsqltype="cf_sql_varchar">
	                    AND company_code = <cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">
	                    AND UPPER(lib_type) = 'PERSKPI'
						AND reviewer_empid = <cfqueryparam value="#qFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
						AND request_no = <cfqueryparam value="#qFromPlan.request_no#" cfsqltype="cf_sql_varchar">
	            </cfquery>
				<cfif qGetLibraryDetails.recordcount eq 0>
					<cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
					SELECT * FROM TPMDPERFORMANCE_PLAND
					WHERE form_no = <cfqueryparam value="#strckEvalD.form_no#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">
					AND UPPER(lib_type) = 'PERSKPI'

					AND request_no = <cfqueryparam value="#qFromPlan.request_no#" cfsqltype="cf_sql_varchar">
					</cfquery>
				</cfif>
		
	        <cfelseif arguments.existInPlan and UCASE(libtype) eq "ORGKPI">
	            <cfquery name="local.qGetOrgUnit" datasource="#request.sdsn#">
	                SELECT DISTINCT dept_id FROM TEOMPOSITION
	                WHERE position_id = <cfqueryparam value="#strckEval.reviewee_posid#" cfsqltype="cf_sql_integer">
	                    AND company_id = <cfqueryparam value="#strckEval.coid#" cfsqltype="cf_sql_integer">
	            </cfquery>
	            <cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
	                SELECT * FROM TPMDPERFORMANCE_PLANKPI
	                WHERE orgunit_id = <cfqueryparam value="#qGetOrgUnit.dept_id#" cfsqltype="cf_sql_integer">
	                    AND company_code = <cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">
	                    AND period_code = <cfqueryparam value="#strckEval.period_code#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	        <cfelseif listfindnocase("PERSKPI,ORGKPI",libtype)>
	            <cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
	                SELECT kpi_name_en AS lib_name_en,
	                    kpi_name_id AS lib_name_id,
	                    kpi_name_my AS lib_name_my,
	                    kpi_name_th AS lib_name_th,
	                    kpi_desc_en AS lib_desc_en,
	                    kpi_desc_id AS lib_desc_id,
	                    kpi_desc_my AS lib_desc_my,
	                    kpi_desc_th AS lib_desc_th,
	                    kpilib_code AS lib_code,
	                    iscategory,
	                    kpi_depth AS lib_depth,
	                    parent_code,
	                    parent_path
	                FROM TPMDPERIODKPILIB
	                WHERE company_code = <cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">
	                    AND period_code = <cfqueryparam value="#strckEval.period_code#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	        <cfelseif libtype eq "APPRAISAL">
	            <cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
	                SELECT appraisal_name_en AS lib_name_en,
	                    appraisal_name_id AS lib_name_id,
	                    appraisal_name_my AS lib_name_my,
	                    appraisal_name_th AS lib_name_th,
	                    appraisal_desc_en AS lib_desc_en,
	                    appraisal_desc_id AS lib_desc_id,
	                    appraisal_desc_my AS lib_desc_my,
	                    appraisal_desc_th AS lib_desc_th,
	                    apprlib_code AS lib_code,
	                    iscategory,
	                    appraisal_depth AS lib_depth,
	                    parent_code,
	                    parent_path
	                FROM TPMDPERIODAPPRLIB
	                WHERE company_code = <cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">
	                    AND period_code = <cfqueryparam value="#strckEval.period_code#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	        <cfelseif libtype eq "COMPETENCY">
	            <cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
	                SELECT competence_name_en AS lib_name_en,
	                    competence_name_id AS lib_name_id,
	                    competence_name_my AS lib_name_my,
	                    competence_name_th AS lib_name_th,
	                    competence_desc_en AS lib_desc_en,
	                    competence_desc_id AS lib_desc_id,
	                    competence_desc_my AS lib_desc_my,
	                    competence_desc_th AS lib_desc_th,
	                    competence_code AS lib_code,
	                    iscategory,
	                    competence_depth AS lib_depth,
	                    parent_code,
	                    parent_path
	                FROM TPMMCOMPETENCE
	            </cfquery>
	        </cfif>

	        <cfloop list="#arguments.listlib#" index="local.idxLib">
	            <cfif idxLib eq "questionComp" or  idxLib eq "QUESTIONCOMP" or  idxLib eq "additionaldeductComp">
	                <cfbreak>
	            </cfif>
	            <cfquery name="local.qGetLibDetail" dbtype="query">
	                SELECT *
	                FROM qGetLibraryDetails
	                WHERE lib_code = <cfqueryparam value="#idxLib#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            
				<cfset strckEvalD["lib_code"] = idxLib>

	            <cfif UCASE(qGetLibDetail.iscategory) eq "N" OR qGetLibDetail.iscategory eq "" >
					<cfif structkeyexists(objJSON,"#inputPrefix#_weight_#idxLib#")>
						<cfset strckEvalD["weight"]  = objJSON["#inputPrefix#_weight_#idxLib#"]>
					<cfelse>
						<cfset strckEvalD["weight"]  = 0>
					</cfif>
					<cfif structkeyexists(objJSON,"#inputPrefix#_achievement_#idxLib#")>
						<cfset strckEvalD["achievement"]  = objJSON["#inputPrefix#_achievement_#idxLib#"]>
					<cfelse>
						<cfset strckEvalD["achievement"]  = 0>
					</cfif>
					<cfif structkeyexists(objJSON,"#inputPrefix#_score_#idxLib#")>
						<cfset strckEvalD["score"] = objJSON["#inputPrefix#_score_#idxLib#"]>
					<cfelse>
						<cfset strckEvalD["score"] = 0>
					</cfif>
	    	       
	                
					<cfif structkeyexists(objJSON,"#inputPrefix#_weightedscore_#idxLib#")>
						<cfset strckEvalD["weightedscore"] = objJSON["#inputPrefix#_weightedscore_#idxLib#"]>
					<cfelse>
						<cfset strckEvalD["weightedscore"] = 0>
					</cfif>
	    	       <cfif structkeyexists(objJSON,"#inputPrefix#_target_#idxLib#")>
						<cfset strckEvalD["target"] = objJSON["#inputPrefix#_target_#idxLib#"]>
					<cfelse>
						<cfset strckEvalD["target"] = 0>
					</cfif>
	    	      
					<cfif structkeyexists(objJSON,"#inputPrefix#_note_#idxLib#")>
						 <cfset strckEvalD["notes"] = objJSON["#inputPrefix#_note_#idxLib#"]>
					<cfelse>
						 <cfset strckEvalD["notes"] = "">
					</cfif>
	                <cfif listfindnocase("APPRAISAL,ORGKPI,PERSKPI",libtype)>
						<cfif structkeyexists(objJSON,"#inputPrefix#_achtype_#idxLib#")>
							 <cfset strckEvalD["achievement_type"] = objJSON["#inputPrefix#_achtype_#idxLib#"]>
						<cfelse>
							 <cfset strckEvalD["achievement_type"] = "">
						</cfif>
						<cfif structkeyexists(objJSON,"#inputPrefix#_looktype_#idxLib#")>
							 <cfset strckEvalD["lookup_code"] = objJSON["#inputPrefix#_looktype_#idxLib#"]>
						<cfelse>
							 <cfset strckEvalD["lookup_code"] = "">
						</cfif>
	    	        </cfif>
				<cfelse>
					<cfset strckEvalD["weight"] = "">
	    	        <cfset strckEvalD["achievement"] = "">
	    	        <cfset strckEvalD["score"] = "">
	    	        <cfset strckEvalD["weightedscore"] = 0>
	    	        <cfset strckEvalD["target"] = "">
					<cfset strckEvalD["notes"] = "">
	                <cfif listfindnocase("APPRAISAL,ORGKPI,PERSKPI",libtype)>
						<cfset strckEvalD["achievement_type"] = "">
						<cfset strckEvalD["lookup_code"] = "">
					</cfif>
	            </cfif>
	                
		        <cfset strckEvalD["lib_name_en"] = qGetLibDetail.lib_name_en>
		        <cfset strckEvalD["lib_name_id"] = qGetLibDetail.lib_name_id>
		        <cfset strckEvalD["lib_name_my"] = qGetLibDetail.lib_name_my>
		        <cfset strckEvalD["lib_name_th"] = qGetLibDetail.lib_name_th>
		        <cfset strckEvalD["lib_desc_en"] = qGetLibDetail.lib_desc_en>
		        <cfset strckEvalD["lib_desc_id"] = qGetLibDetail.lib_desc_id>
		        <cfset strckEvalD["lib_desc_my"] = qGetLibDetail.lib_desc_my>
		        <cfset strckEvalD["lib_desc_th"] = qGetLibDetail.lib_desc_th>
		        <cfset strckEvalD["iscategory"] = qGetLibDetail.iscategory>
		        <cfset strckEvalD["lib_depth"] = qGetLibDetail.lib_depth>
		        <cfset strckEvalD["parent_code"] = qGetLibDetail.parent_code>
		        <cfset strckEvalD["parent_path"] = qGetLibDetail.parent_path>
				
				
			<!---	  <cfset local.retvar = variables.objPerfEvalD.Insert(strckEvalD)>   
				<cfif retvar>
					<cf_sfwritelog dump="strckEvalD" prefix="strckEvalD_kedua_">
				<cfelse> ---->
					<cf_sfwritelog dump="strckEvalD" prefix="strckEvalD_lagi_#strckEvalD['lib_code']#">
					<cfquery name="local.qInsertEvalD" datasource="#request.sdsn#">
					INSERT INTO TPMDPERFORMANCE_EVALD (form_no,reviewer_empid,reviewer_posid,lib_code,lib_type,company_code,weight,achievement,score,weightedscore,target,notes,created_by,created_date,modified_by,modified_date,lib_name_en,lib_desc_en,iscategory,lib_depth,parent_code,parent_path,achievement_type,lookup_code) 
					VALUES (
						<cfqueryparam value="#strckEvalD.form_no#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.reviewer_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.reviewer_posid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_type#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.weight#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.achievement#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.score#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.weightedscore#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.target#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.notes#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						#now()#,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						#now()#,
						<cfqueryparam value="#strckEvalD.lib_name_en#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_desc_en#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.iscategory#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_depth#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.parent_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.parent_path#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.achievement_type#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lookup_code#" cfsqltype="cf_sql_varchar">
						
						
					)				
				</cfquery>
				<!----</cfif> ---->
				<!----<cfquery name="local.qInsertEvalD" datasource="#request.sdsn#">
					INSERT INTO TPMDPERFORMANCE_EVALD (form_no,reviewer_empid,reviewer_posid,lib_code,lib_type,company_code,weight,achievement,score,weightedscore,target,notes,created_by,created_date,modified_by,modified_date,lib_name_en,lib_desc_en,iscategory,lib_depth,parent_code,parent_path,achievement_type,lookup_code) 
					VALUES (
						<cfqueryparam value="#strckEvalD.form_no#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.reviewer_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.reviewer_posid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_type#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.weight#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.achievement#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.score#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.weightedscore#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.target#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.notes#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						#now()#,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						#now()#,
						<cfqueryparam value="#strckEvalD.lib_name_en#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_desc_en#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.iscategory#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_depth#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.parent_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.parent_path#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.achievement_type#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lookup_code#" cfsqltype="cf_sql_varchar">
						
						
					)				
				</cfquery> remarked by maghdalenasp 2018-03-21 ------->

	            <!--- input ke TEOREMPCOMPETENCE--->
	            <cfif ucase(libtype) eq "COMPETENCY">
	            	<cfif len(strckEvalD.achievement)>
	            	<cfquery name="Local.qDelEmpCompt" datasource="#request.sdsn#">
	                	DELETE FROM TEOREMPCOMPETENCE
	                    WHERE emp_id = <cfqueryparam value="#strckEval.reviewee_empid#" cfsqltype="cf_sql_varchar">
	                    	AND competence_code = <cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="cf_sql_varchar">
	                </cfquery>
	            	<cfquery name="Local.qInsertEmpCompt" datasource="#request.sdsn#">
	                	INSERT INTO TEOREMPCOMPETENCE
						(emp_id, competence_code, point_value, created_by, created_date, modified_by, modified_date)
						VALUES 
						(
						<cfqueryparam value="#strckEval.reviewee_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.achievement#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
						<cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
						<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
						<cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>
						)
	                </cfquery>
	                </cfif>
	            </cfif>
	        </cfloop>
	    </cffunction>
	    
	    <cffunction name="Revise">
	        <cfset local.reqno = FORM.request_no/>
	        <cfset local.formno = FORM.formno/>
	        <cfset local.requestfor = FORM.requestfor/>
	        <cfset local.periodcode = FORM.period_code/>
	        <cfset local.refdate = FORM.reference_date/>

	        <cftransaction>
	        <cfquery name="local.qCheckRequest" datasource="#request.sdsn#">
	        	SELECT approval_data, approval_list, approved_list, outstanding_list, approved_data FROM TCLTREQUEST
	            WHERE company_id =<cfqueryparam value="#FORM.coid#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
	            AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
	            AND req_type = 'PERFORMANCE.EVALUATION'
	            AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	            AND reqemp = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
				
	        </cfquery>
	        
            <cfset LOCAL.strckData = FORM/>
            
        	<cfquery name="local.qSelStepHigher" datasource="#request.sdsn#">
            	SELECT reviewer_empid FROM TPMDPERFORMANCE_EVALH 
            	WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
            	AND request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
            	AND review_step > <cfqueryparam value="#strckData.USERINREVIEWSTEP#" cfsqltype="cf_sql_varchar">
            	AND company_code =  <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
            </cfquery>
            
            <cfloop query="qSelStepHigher">
        	    <cfquery name="local.qDelPlanD" datasource="#request.sdsn#">
            	    DELETE FROM  TPMDPERFORMANCE_EVALD 
            		WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
            		AND reviewer_empid = <cfqueryparam value="#qSelStepHigher.reviewer_empid#" cfsqltype="cf_sql_varchar">
            	    AND company_code =  <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
                </cfquery>
                
                <cfquery name="local.qDelPlanD" datasource="#request.sdsn#">
            	    DELETE FROM  TPMDPERFORMANCE_EVALH 
            		WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
            		AND request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
            		AND reviewer_empid = <cfqueryparam value="#qSelStepHigher.reviewer_empid#" cfsqltype="cf_sql_varchar">
            	    AND company_code = <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
                </cfquery>
            </cfloop>
          
	        <cfquery name="local.qGetSPMH" datasource="#request.sdsn#">
	        	SELECT reviewer_empid, review_step, request_no FROM TPMDPERFORMANCE_EVALH
	            WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	            AND reviewee_empid = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
	            AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
	            AND head_status = 1
	            ORDER BY review_step ASC
	        </cfquery>
	        
	        <cfset local.new_outstanding =  qCheckRequest.outstanding_list/>
	        <cfset local.new_approved =  qCheckRequest.approved_list/>

			<cfset LOCAL.arr_approvaldata=SFReqFormat(qCheckRequest.approval_data,"R",[])>
			<!---TW:<cfwddx action="wddx2cfml" input="#qCheckRequest.approval_data#" output="arr_approvaldata">--->
			<cfset local.strckAppr = ApprovalLoop(arr_approvaldata,request.scookie.user.empid)/>
	        <cfset local.userindbstep = strckAppr.empinstep>
			<cfif not listfindnocase(strckAppr.fullapproverlist,requestfor) and listfindnocase(valuelist(qGetSPMH.reviewer_empid),requestfor)>
				<cfset userindbstep++>
	        </cfif>
	        
	        <!--- di wddx, yang akan dihapus "approvedby"-nya adalah --->
			<cfset local.steptosetrevised = 0>
	        <cfif listfindnocase(valuelist(qGetSPMH.review_step),userindbstep) gt 1>
		        <cfset steptosetrevised = listgetat(valuelist(qGetSPMH.review_step),listfindnocase(valuelist(qGetSPMH.review_step),userindbstep)-1)>
	        <cfelseif listlen(valuelist(qGetSPMH.review_step)) gt 0>
	        	<cfset steptosetrevised = listlast(valuelist(qGetSPMH.review_step))>
	        </cfif>
	        <cfif userindbstep - strckAppr.empinstep eq 1 and steptosetrevised eq 1>
	        	<cfset steptosetrevised = 0>
	        <cfelseif userindbstep - strckAppr.empinstep eq 1>
		        <cfset --steptosetrevised>
	        </cfif>

	        <!--- update head status reviewer sebelumnya jadi 0 --->
	     <!---   <cfquery name="local.qUpdHeadStatus" datasource="#request.sdsn#">
	           	UPDATE TPMDPERFORMANCE_EVALH
	            SET head_status = 0
				WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
					AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#Form.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
					AND reviewee_empid = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
	                <cfif steptosetrevised neq 0>
						AND reviewer_empid IN (
		                	SELECT emp_id FROM TEOMEMPPERSONAL WHERE user_id = <cfqueryparam value="#arr_approvaldata[steptosetrevised].approvedby#" cfsqltype="cf_sql_varchar">
	                    )
	                <cfelse>
						AND reviewer_empid = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
	                </cfif>
	        </cfquery> ----->
            
            <!--- TCK0818-81809 --->
        	<cfset variables.sendtype = 'next'>
        	<cfset strckData.isfinal = 0/>
        	<cfset strckData.head_status = 0/>
        	<cfset strckData.isfinal_requestno = 1/>
        	
            <cfset SaveTransaction(50,strckData)/>
			<cfquery name="local.qGetLatestBeforeRevise" datasource="#request.sdsn#">
				SELECT <cfif request.dbdriver eq "MSSQL"> TOP 1 </cfif>
				reviewer_empid FROM TPMDPERFORMANCE_EVALH
				WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
				AND reviewee_empid = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
				AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar"> 
				AND head_status = 1
				AND reviewer_empid <> <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
				ORDER BY created_date desc
				<cfif request.dbdriver eq "MYSQL"> LIMIT 1 </cfif>
			</cfquery>
			<cfif qGetLatestBeforeRevise.reviewer_empid neq "">
				<cfquery name="local.qGetLatestBeforeRevise" datasource="#request.sdsn#">
					SELECT user_id from teomemppersonal where emp_id = '#qGetLatestBeforeRevise.reviewer_empid#'
				</cfquery>
				 <cfset new_outstanding = qGetLatestBeforeRevise.user_id &","&new_outstanding>
			</cfif>
            <!--- TCK0818-81809 --->
	        
	        <!---<cfoutput><script>alert("yan #steptosetrevised# -- #requestfor# -- #form_code# -- #reqno#");</script></cfoutput><CF_SFABORT>--->
	        
	        <cfif steptosetrevised neq 0>
	            <!--- update last reviewer, modified_date untuk revised jadi si user --->
	            <cfquery name="local.qUpdHeadStatus" datasource="#request.sdsn#">
	            	UPDATE TPMDPERFORMANCE_EVALH
	                SET modified_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
					WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
					AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#Form.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
					AND reviewee_empid = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
					AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
	            </cfquery>

	        	<cfset local.uidtorevised = arr_approvaldata[steptosetrevised].approvedby>
				<cfset arr_approvaldata[steptosetrevised].approvedby = ""/>
				<cfset LOCAL.new_approvaldata=SFReqFormat(arr_approvaldata,"W")>
	    		<!---TW:<cfwddx action="cfml2wddx" input="#arr_approvaldata#" output="new_approvaldata">
		        <cfset new_outstanding =  uidtorevised&","&new_outstanding/>--->
	            <cfif listlen(new_approved) and listfindnocase(new_approved,uidtorevised)>
	    	    	<cfset new_approved =  listdeleteat(new_approved,listfindnocase(new_approved,uidtorevised))/>
	            </cfif>
	            
	        <cfelse>
	            <cfquery name="local.qGetUserId" datasource="#request.sdsn#">
	            	SELECT DISTINCT user_id FROM TEOMEMPPERSONAL
					WHERE emp_id = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            
		      <!---  <cfset new_outstanding =  qGetUserId.user_id&","&new_outstanding/>--->
	        </cfif>
	        
			<!--- set approved_data --->
			<cfset LOCAL.strckApprovedData=SFReqFormat(qCheckRequest.approved_data,"R")>
			<cfset var strckFormInbox = StructNew() />
			<cfset strckFormInbox['DTIME'] = Now() />
			<cfset strckFormInbox['DECISION'] = 3 />
	        <cfif structkeyexists(FORM,"revisingNotes")>
				<cfset strckFormInbox['NOTES'] = Form.revisingNotes />
	        <cfelse>
				<cfset strckFormInbox['NOTES'] = "-" />
	        </cfif>
			<cfset LOCAL.apvdDataKey = request.scookie.user.uid >
			<cfif trim(qCheckRequest.approved_data) eq '' OR (isStruct(strckApprovedData) AND REFind('_', ListFirst(StructKeyList(strckApprovedData)) ) ) >
				<cfset LOCAL.cntStrckApprovedData = StructCount(strckApprovedData)+1 />
				<cfset apvdDataKey = NumberFormat(cntStrckApprovedData,'00')&'_'&apvdDataKey >
			</cfif>
			<cfset strckApprovedData[apvdDataKey] = strckFormInbox />
			<cfset LOCAL.wddxApprovedData=SFReqFormat(strckApprovedData,"W")>
	    	<!---TW:
			<cfif IsWDDX(qCheckRequest.approved_data)>
				<cfwddx action="wddx2cfml" input="#qCheckRequest.approved_data#" output="strckApprovedData">

				<cfset var strckFormInbox = StructNew() />
				<cfset strckFormInbox['DTIME'] = Now() />
				<cfset strckFormInbox['DECISION'] = 3 />
	            <cfif structkeyexists(FORM,"revisingNotes")>
					<cfset strckFormInbox['NOTES'] = Form.revisingNotes />
	            <cfelse>
					<cfset strckFormInbox['NOTES'] = "-" />
	            </cfif>
	            
				<cfset strckApprovedData[request.scookie.user.uid] = strckFormInbox />
				<cfwddx action="cfml2wddx" input="#strckApprovedData#" output="wddxApprovedData">
			<cfelse>
		       	<cfset strckApprovedData = structnew()>
				<cfset var strckFormInbox = StructNew() />
				<cfset strckFormInbox['DTIME'] = Now() />
				<cfset strckFormInbox['DECISION'] = 3 />
	            <cfif structkeyexists(FORM,"revisingNotes")>
					<cfset strckFormInbox['NOTES'] = Form.revisingNotes />
	            <cfelse>
					<cfset strckFormInbox['NOTES'] = "-" />
	            </cfif>
				<cfset strckApprovedData[request.scookie.user.uid] = strckFormInbox />
				<cfwddx action="cfml2wddx" input="#strckApprovedData#" output="wddxApprovedData">
			</cfif>--->

	        <cfquery name="local.qUpdRequest" datasource="#request.sdsn#">
	   	    	UPDATE TCLTREQUEST SET
	            <!---TW:<cfif isWDDX(wddxApprovedData)></cfif>--->
					approved_data = <cfqueryparam value="#wddxApprovedData#" cfsqltype="cf_sql_varchar">,
		        <cfif steptosetrevised neq 0>
	        	    approval_data = <cfqueryparam value="#new_approvaldata#" cfsqltype="cf_sql_varchar">,
	            	approved_list = <cfqueryparam value="#new_approved#" cfsqltype="cf_sql_varchar">,
	            <cfelse>
	               	approved_list = '',
	            </cfif>
	            outstanding_list = <cfqueryparam value="#new_outstanding#" cfsqltype="cf_sql_varchar">,
	   	        status = 4,
				modified_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
				modified_by = <cfqueryparam value="#REQUEST.SCOOKIE.USER.UNAME#" cfsqltype="cf_sql_varchar">
	       	    WHERE company_id = <cfqueryparam value="#Form.coid#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
	    	        AND company_code = <cfqueryparam value="#Form.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
	   		        AND req_type = 'PERFORMANCE.EVALUATION'
	       		    AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	           		AND reqemp = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
					
	   	    </cfquery>
	        
	        <!--- delete record final jika ada --->
	        <cfquery name="local.qDelFinalRec" datasource="#request.sdsn#">
	        	DELETE FROM TPMDPERFORMANCE_FINAL
	            WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
	        </cfquery>
            <cfquery name="LOCAL.qGetDataRequest" datasource="#request.sdsn#">
    			SELECT seq_id, req_no, status,outstanding_list, company_id, email_list, approval_list FROM TCLTREQUEST 
    			WHERE  req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
    		</cfquery> 
    		<!--- <cfset tempSendEmail = ReviseApprovedNotif({mailtmpltRqster="ReviseRequestNotificationTer",mailtmpltRqstee="ReviseRequestNotificationTee",mailtmpltAprvr="ReviseRequestNotification",notiftmpltRqster="7",notiftmpltRqstee="8",notiftmpltAprvr="9",strRequestNo=reqno,iStatusOld=qGetDataRequest.status,lstNextApprover=qGetDataRequest.outstanding_list,requestcoid=qGetDataRequest.company_id,requestId=qGetDataRequest.seq_id,lastOutstanding=ListLast(qGetDataRequest.outstanding_list)})> --->
    	    </cftransaction>
			
			
				<!---- start Condition : New Layout Performance Evaluation Form  ------>
				<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully revising request for previous reviewer",true)>
	        	<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
					<cfoutput>
						<script>
							alert("#strMessage#");
							popClose();
							refreshPage();
						</script>
					</cfoutput>
				<cfelse>
					<cfscript>
						data = {"success"="1","MSG"="#strMessage#"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
				<!---- End Condition : New Layout Performance Evaluation Form  ------>
				
				
				<!--- Notif goes here --->
                <cfif val(FORM.UserInReviewStep)-1 GTE 1 AND val(FORM.UserInReviewStep)-1 LTE Listlen(FORM.FullListAppr) > <!---Validasi ada next approver--->
    		        <cfset LOCAL.lstNextApprover = ListGetAt( FORM.FullListAppr , val(FORM.UserInReviewStep)-1 )><!---hanya get list next approver--->

                    <cfset LOCAL.additionalData = StructNew() >
                    <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                    
                    <cfif lstNextApprover NEQ ''>
                        <cfset lstSendEmail = replace(lstNextApprover,"|",",","all")>
                        <cfif lstSendEmail EQ FORM.REVIEWEE_EMPID> <!--- Send by approver to reviewee --->
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalReviseForReviewee', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        <cfelse><!--- Send by approver status not requested --->
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalReviseForApprover', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        </cfif>
                    </cfif>
                </cfif>
				<!--- Notif goes here --->
				
	    </cffunction>

	    <cffunction name="UnfinalPerfEvalForm">
	        <cfset Local.empid = FORM.requestfor>
	        <cfset Local.reqno = FORM.request_no>
	       	<cfset Local.error_found = 0>
	       	
	        <!---<cftry>--->
	        <cfquery name="local.qCheckRequest" datasource="#request.sdsn#">
	        	SELECT approval_data, approval_list, approved_list, outstanding_list, approved_data FROM TCLTREQUEST
	            WHERE company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
	            AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            AND UPPER(req_type) = 'PERFORMANCE.EVALUATION'
	            AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	            AND reqemp = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
		
	        </cfquery>
	        
	        <cfquery name="local.qGetSPMH" datasource="#request.sdsn#">
	        	SELECT <cfif request.dbdriver EQ "MSSQL">TOP 1</cfif> form_no, reviewer_empid, review_step FROM TPMDPERFORMANCE_EVALH
	            WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	            AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	            AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            AND head_status = 1
	            ORDER BY review_step DESC
	            <cfif request.dbdriver NEQ "MSSQL">LIMIT 1</cfif>
	        </cfquery>
	        
	        <cfquery name="local.qCheckIfEverAdjusted" datasource="#request.sdsn#">
	        	SELECT adjust_no FROM TPMDPERFORMANCE_FINAL
	            WHERE form_no = <cfqueryparam value="#qGetSPMH.form_no#" cfsqltype="cf_sql_varchar">
	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfif not len(qCheckIfEverAdjusted.adjust_no)>
	        
	            <!--- delete record final jika ada --->
	            <cfquery name="local.qDelFinalRec" datasource="#request.sdsn#">
	            	DELETE FROM TPMDPERFORMANCE_FINAL
	                WHERE form_no = <cfqueryparam value="#qGetSPMH.form_no#" cfsqltype="cf_sql_varchar">
	                    AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	    
	            <cfset local.new_outstanding =  qCheckRequest.outstanding_list/>
	            <cfset local.new_approved =  qCheckRequest.approved_list/>
	    		<cfset LOCAL.arr_approvaldata=SFReqFormat(qCheckRequest.approval_data,"R",[])>
			
	        	<!---TW:<cfwddx action="wddx2cfml" input="#qCheckRequest.approval_data#" output="arr_approvaldata">--->
	            	
	           
	            <cfquery name="local.qUpdHeadStatus" datasource="#request.sdsn#">
	               	UPDATE TPMDPERFORMANCE_EVALH
	                SET head_status = 1, isfinal = 0, 
	                	modified_by = <cfqueryparam value="#request.scookie.user.uname#|UNFINAL" cfsqltype="cf_sql_varchar">,
	                    modified_date = <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp">
	    			WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	    				AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    				AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	    				AND reviewer_empid = <cfqueryparam value="#qGetSPMH.reviewer_empid#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	    
	            <!--- update last reviewer, modified_date untuk revised jadi si user --->
	            <cfset local.uidtorevised = arr_approvaldata[arraylen(arr_approvaldata)].approvedby>
				<cfset arr_approvaldata[arraylen(arr_approvaldata)].approvedby = ""/>
	    		<cfset LOCAL.new_approvaldata=SFReqFormat(arr_approvaldata,"W")>
				
	        	<!---TW:<cfwddx action="cfml2wddx" input="#arr_approvaldata#" output="new_approvaldata">--->

				 <cfif listlen(new_outstanding)>
	    	        <cfset new_outstanding =  uidtorevised&","&new_outstanding/>
	            <cfelse>
	    	        <cfset new_outstanding =  uidtorevised/>
	            </cfif>
				<cfif listlen(new_approved) AND listfindnocase(new_approved,uidtorevised) LTE listlen(new_approved) AND listfindnocase(new_approved,uidtorevised) GT 0>
	      	    	<cfset new_approved =  listdeleteat(new_approved,listfindnocase(new_approved,uidtorevised))/>
	            </cfif>
	    
	            <cfquery name="local.qUpdRequest" datasource="#request.sdsn#">
	       	    	UPDATE TCLTREQUEST SET
	           	    approval_data = <cfqueryparam value="#new_approvaldata#" cfsqltype="cf_sql_varchar">,
	               	approved_list = <cfqueryparam value="#new_approved#" cfsqltype="cf_sql_varchar">,
				<!--- 	approval_list = <cfqueryparam value="#uidtorevised#" cfsqltype="cf_sql_varchar">, 	
					approval_position_list = <cfqueryparam value="#uidtorevised#" cfsqltype="cf_sql_varchar">, 	 --->
	                outstanding_list = <cfqueryparam value="#new_outstanding#" cfsqltype="cf_sql_varchar">,
					modified_by = <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
	                 modified_date = <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp">,
	       	        status = 2
	           	    WHERE company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
	        	        AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	       		        AND UPPER(req_type) = 'PERFORMANCE.EVALUATION'
	           		    AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	               		AND reqemp = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	    				
	       	    </cfquery>
	       	<cfelse>
	        	<cfset error_found = 2>
	        </cfif>
	            
	        <!---<cfcatch>
	        	<cfset error_found = 1>
	        </cfcatch>
	        </cftry>--->
	        
			<cfif not error_found>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully opening performance form",true)>
			<cfelseif error_found eq 2>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSCan't opening performance form because this form has been adjusted before",true)>
			<cfelse>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed opening performance form",true)>
	        </cfif>
	        

			
				<!---- start Condition : New Layout Performance Evaluation Form  ------>
	        	<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
					<cfoutput>
						<script>
							alert("#LOCAL.SFLANG#");
							popClose();
							refreshPage();
						</script>
					</cfoutput>

    			    <!--- Notif goes here --->
                    <cfif val(FORM.UserInReviewStep) GTE 1 AND val(FORM.UserInReviewStep) LTE Listlen(FORM.FullListAppr) > <!---Validasi ada next approver--->
        		        <cfset LOCAL.lstNextApprover = ListGetAt( FORM.FullListAppr , val(FORM.UserInReviewStep) )><!---hanya get list next approver--->
    
                        <cfset LOCAL.additionalData = StructNew() >
                        <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                        
                        <cfif lstNextApprover NEQ ''>
                            <cfset lstSendEmail = replace(lstNextApprover,"|",",","all")>
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalNotifOpenForm', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        </cfif>
                    </cfif>
    			    <!--- Notif goes here --->	

				<cfelse>
				
					<cfif not error_found>
						<cfscript>
							data = {"success"="1","request_no"="#reqno#","form_no"="#qGetSPMH.form_no#"};
						</cfscript>
    						
        			    <!--- Notif goes here --->
		       		    <cfset local.strckListApprover = GetApproverList(reqno=reqno,empid=empid,reqorder='-',varcoid=REQUEST.SCOOKIE.COID,varcocode=REQUEST.SCOOKIE.COCODE)>

                        <cfif val(strckListApprover.index) GTE 1 AND val(strckListApprover.index) LTE Listlen(strckListApprover.FullListApprover) > <!---Validasi ada next approver--->
            		        <cfset LOCAL.lstNextApprover = ListGetAt( strckListApprover.FullListApprover , val(strckListApprover.index) )><!---hanya get list next approver--->
        
                            <cfset LOCAL.additionalData = StructNew() >
                            <cfset additionalData['REQUEST_NO'] = reqno ><!---Additional Param Untuk template--->
                            
                            <cfif lstNextApprover NEQ ''>
                                <cfset lstSendEmail = replace(lstNextApprover,"|",",","all")>
                                <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                    template_code = 'PerformanceEvalNotifOpenForm', 
                                    lstsendTo_empid = lstSendEmail , 
                                    reviewee_empid = empid ,
                                    strckData = additionalData
                                )>
                            </cfif>
                        </cfif>
        			    <!--- Notif goes here --->	
						
					<cfelse>
						<cfscript>
							data = {"success"="0","MSG"="#SFLANG#"};
						</cfscript>
					</cfif>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
    				
					
				</cfif>
				<!---- End Condition : New Layout Performance Evaluation Form  ------>
				
			
	    	
	    </cffunction>
          <cffunction name="DeleteFormAsDraft">
	    	<cfset local.strckData = structnew()>
	        <cfset strckData.reviewee_empid = FORM.requestfor>
	        <cfset strckData.request_no = FORM.request_no>
	        <cfset strckData.formno = FORM.formno>
	        <cfset strckData.period_code = FORM.period_code>
	        <cfset strckData.reference_date = FORM.reference_date>

	        <cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>  <!--- TCK0618-81679 ----->
	        
	        <cftry>
	        
				<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
					DELETE FROM TPMDPERFORMANCE_EVALNOTE
					WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
				    AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
					DELETE FROM TPMDPERFORMANCE_EVALD
					WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				    AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
				    
	            </cfquery>
	            <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
	            	DELETE FROM TPMDPERFORMANCE_EVALH
					WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
	                AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
	                AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
	                AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp">
	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				    AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
	             </cfquery>
	            
    					<cfquery name="Local.qPMCheck2" datasource="#request.sdsn#">
        					select head_status from TPMDPERFORMANCE_EVALH
        					WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
        					AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
        					AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
        					AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp">
        					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
        					AND reviewer_empid <> <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
    					</cfquery>
    					<cfif ReturnVarCheckCompParam eq true>
    					    <cfif qPMCheck2.recordcount eq 0 >
    					     
    					    <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
    					     UPDATE TCLTREQUEST
    					    	    SET status = 1
    						        WHERE req_type = 'PERFORMANCE.EVALUATION'
    						        AND req_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
    						        AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    						       </cfquery>
    						 </cfif>      
    		            </cfif>	
    			
				<!---- start Condition : New Layout Performance Evaluation Form  ------>
	        	<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
					<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully Deleting Performance Form Request", true)>
					<cfoutput>
						<script>
							alert("#strMessage#");
							parent.refreshPage();
							parent.popClose();
						</script>
					</cfoutput>
				<cfelse>
					<cfscript>
						data = {"success"="1"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
				<!---- End Condition : New Layout Performance Evaluation Form  ------>
				
	        <cfcatch>
				<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
					<cfset strMessage = Application.SFParser.TransMLang("JSFailed Deleting Performance Form Request", true)>
					<cfoutput>
						<script>
							alert("#strMessage#");
							parent.refreshPage();
							parent.popClose();
						</script>
					</cfoutput>
				<cfelse>
					<cfscript>
						data = {"success"="0"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
	        	
	        </cfcatch>
	        </cftry>
	    </cffunction>
	    <cffunction name="DeleteReqForm">
	    	<cfset local.strckData = structnew()>
	        <cfset strckData.reviewee_empid = FORM.requestfor>
	        <cfset strckData.request_no = FORM.request_no>
	        <cfset strckData.formno = FORM.formno>
	        <cfset strckData.period_code = FORM.period_code>
	        <cfset strckData.reference_date = FORM.reference_date>
	        
	        <cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>  <!--- TCK0618-81679 ----->
	        
	        <cftry>
	        	<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
					DELETE FROM TPMDPERFORMANCE_EVALNOTE
					WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
					    <cfif ReturnVarCheckCompParam eq true> <!--- delete per reviewer draft --->
				            AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
				        </cfif>
	            </cfquery>
	            <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
					DELETE FROM TPMDPERFORMANCE_EVALD
					WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					    <cfif ReturnVarCheckCompParam eq true> <!--- delete per reviewer draft --->
				            AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
				        </cfif>
	            </cfquery>
	            
	            <!---Delete EvalKPI--->
    			<cfif ReturnVarCheckCompParam eq false>
    				<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">	
    					DELETE FROM TPMDPERFORMANCE_EVALKPI
    					WHERE  period_code = <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
    					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    				</cfquery>
    			<cfelse>
    				<cfquery name="Local.qPMCheck" datasource="#request.sdsn#">
        				select head_status from TPMDPERFORMANCE_EVALH
        				WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
                        AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
                        AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
                        AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp">
                        AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
        				AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
    				</cfquery>
    	            <cfif qPMCheck.head_status eq 0>
    					<cfquery name="Local.qPMCheck2" datasource="#request.sdsn#">
        					select head_status from TPMDPERFORMANCE_EVALH
        					WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
        					AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
        					AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
        					AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp">
        					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
        					AND reviewer_empid <> <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
    					</cfquery>
    					<cfif qPMCheck2.recordcount eq 0>
    						<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">	
    							DELETE FROM TPMDPERFORMANCE_EVALKPI
    							WHERE period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
    							AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    						</cfquery>
    					</cfif>
    				</cfif>
    			</cfif>
	            <!---Delete EvalKPI--->
	            
	            <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
	            	DELETE FROM TPMDPERFORMANCE_EVALH
					WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
	                AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
	                AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
	                AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp">
	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					    <cfif ReturnVarCheckCompParam eq true> <!--- delete per reviewer draft --->
				            AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
				        </cfif>
	            </cfquery>
	            
	            <cfif ReturnVarCheckCompParam eq false>
    	            <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
    					DELETE FROM TCLTREQUEST
    					WHERE req_type = 'PERFORMANCE.EVALUATION'
    					AND req_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
    	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    	            </cfquery>
    	        <cfelse>
    				<cfquery name="Local.qPMCheck2" datasource="#request.sdsn#">
    					select request_no from TPMDPERFORMANCE_EVALH
    					WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
    					AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
    					AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
    					AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp">
    					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    				
    				</cfquery>
    				<cfif qPMCheck2.recordcount eq 0>
    					<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
    						UPDATE TCLTREQUEST
    						SET status = 1
    						WHERE req_type = 'PERFORMANCE.EVALUATION'
    						AND req_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
    						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    					</cfquery>
    				</cfif>
    	        </cfif>
				
				<!---- start Condition : New Layout Performance Evaluation Form  ------>
	        	<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
					<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully Deleting Performance Form Request", true)>
					<cfoutput>
						<script>
							alert("#strMessage#");
							parent.refreshPage();
							parent.popClose();
						</script>
					</cfoutput>
				<cfelse>
					<cfscript>
						data = {"success"="1"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
				<!---- End Condition : New Layout Performance Evaluation Form  ------>
				
	        <cfcatch>
				<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
					<cfset strMessage = Application.SFParser.TransMLang("JSFailed Deleting Performance Form Request", true)>
					<cfoutput>
						<script>
							alert("#strMessage#");
							parent.refreshPage();
							parent.popClose();
						</script>
					</cfoutput>
				<cfelse>
					<cfscript>
						data = {"success"="0"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
	        	
	        </cfcatch>
	        </cftry>
	    </cffunction>
	    
	   <cffunction name="Inbox"> 
			<cfargument name="RequestData" type="Struct" required="Yes">
			<cfargument name="ProcData" type="array" required="Yes">
			<cfargument name="RowNumber" type="Numeric" required="Yes">
			<cfargument name="RequestMode" type="String" required="Yes">
			<cfargument name="RequestStatus" type="Numeric" required="Yes">
			<cfargument name="RequestKey" type="String" required="No">
			  <!---start : ENC51115-79853--->
			<cfargument name="varcoid" required="No" default="#request.scookie.coid#"> 
			<cfargument name="varcocode" required="No" default="#request.scookie.cocode#">
			 <!---end : ENC51115-79853--->
			<cfset LOCAL.SFMLANG=Application.SFParser.TransMLang(listAppend("FDLink|FDRemark|View Performance Evaluation Form|FDLastReviewer|Previous Step Reviewer",(isdefined("FORMMLANG")?FORMMLANG:""),"|"))>
		
	        <cfset Local.reqorder = "inbox">
			<cfif structkeyexists(REQUEST,"SHOWCOLUMNGENERATEPERIOD")>
				<cfset local.ReturnVarCheckCompParam = REQUEST.SHOWCOLUMNGENERATEPERIOD>
			<cfelse>
				<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
			</cfif>
			<cfif ReturnVarCheckCompParam eq false >
				<cfif not structkeyexists(Arguments.RequestData,"requestfor")>
					<cfset Local.reqorder = getApprovalOrder(reviewee=Arguments.RequestData.EMP_ID,reviewer=request.scookie.user.empid)> 
				 <cfelse>
					<cfset Local.reqorder = getApprovalOrder(reviewee=Arguments.RequestData.requestfor,reviewer=request.scookie.user.empid)> 
				 </cfif>
			<cfelse>
				 <cfset Local.reqorder = "-">
			</cfif>
	       
			<cfset LOCAL.scProc=Arguments.ProcData>
	        <cfquery name="Local.qGetAllParam" datasource="#request.sdsn#">
	        	SELECT  p.emp_id, c.grade_code, c.position_id  FROM  TEODEMPCOMPANY c
				INNER JOIN TEOMEMPPERSONAL p ON c.emp_id = p.emp_id
				 <cfif not structkeyexists(Arguments.RequestData,"requestfor")>
					WHERE c.emp_id = <cfqueryparam value="#Arguments.RequestData.EMP_ID#" cfsqltype="cf_sql_varchar">
				 <cfelse>
					WHERE c.emp_id = <cfqueryparam value="#Arguments.RequestData.requestfor#" cfsqltype="cf_sql_varchar">
				 </cfif>
	        </cfquery>
	        <cfquery name="Local.qGetFormNo" datasource="#request.sdsn#">
	        	SELECT  form_no, reviewer_empid FROM TPMDPERFORMANCE_EVALH
	            WHERE request_no = <cfqueryparam value="#Arguments.RequestData.request_no#" cfsqltype="cf_sql_varchar">
	            AND period_code = <cfqueryparam value="#Arguments.RequestData.period_code#" cfsqltype="cf_sql_varchar">
				<cfif not structkeyexists(Arguments.RequestData,"requestfor")>
					AND reviewee_empid = <cfqueryparam value="#Arguments.RequestData.EMP_ID#" cfsqltype="cf_sql_varchar">
				<cfelse>
					AND reviewee_empid = <cfqueryparam value="#Arguments.RequestData.requestfor#" cfsqltype="cf_sql_varchar">
				</cfif>
	            AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            and head_status = 1
				order by review_step desc
	        </cfquery>
			<cfset local.infoLastReviewer = " : -">
			<cfif qGetFormNo.recordcount eq 0>
				 <cfquery name="Local.qGetFormNo" datasource="#request.sdsn#">
					SELECT  form_no FROM TPMDPERFORMANCE_EVALGEN
					WHERE req_no = <cfqueryparam value="#Arguments.RequestData.request_no#" cfsqltype="cf_sql_varchar">
					AND period_code = <cfqueryparam value="#Arguments.RequestData.period_code#" cfsqltype="cf_sql_varchar">
					<cfif not structkeyexists(Arguments.RequestData,"requestfor")>
						AND reviewee_empid = <cfqueryparam value="#Arguments.RequestData.EMP_ID#" cfsqltype="cf_sql_varchar">
					<cfelse>
						AND reviewee_empid = <cfqueryparam value="#Arguments.RequestData.requestfor#" cfsqltype="cf_sql_varchar">
					</cfif>
					AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
				  </cfquery>
			<cfelse>
				 <cfquery name="Local.qGetinfoName" datasource="#request.sdsn#">
				SELECT p.full_name , c.emp_no  FROM  TEODEMPCOMPANY c
				INNER JOIN TEOMEMPPERSONAL p
					ON c.emp_id = p.emp_id
				WHERE c.emp_id = <cfqueryparam value="#qGetFormNo.REVIEWER_EMPID#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset infoLastReviewer = " : #qGetinfoName.full_name#">
			</cfif>
			<cfset local.ibxlabel="background-color:##e9e9e9;padding:2px 5px;border-bottom: 1px solid black; border-right:0px;">
			<cfset local.ibxdata="background-color:##fff;padding:2px 5px;border-bottom: 1px solid black; border-right:0px;">
	        
			<cfoutput>
				#LOCAL.SFMLANG.PreviousStepReviewer##infoLastReviewer#
				<br/><br>
	            <style>
					##linktoperformanceform a span {
						display: inline;
						padding: 8px 9px;
					}
					##linktoperformanceform a{
						color: black;
						font-weight: bold;
						cursor: pointer;
						text-decoration:underline;
					}
				</style>
	            <div id="linktoperformanceform">
				
					<cfif not structkeyexists(Arguments.RequestData,"requestfor")>
						<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE EQ 1>
							<a href="?sfid=hrm.performance.evalform.newlayout.viewevalform&empid=#Arguments.RequestData.EMP_ID#&periodcode=#Arguments.RequestData.period_code#&refdate=#Arguments.RequestData.reference_date#&formno=#qGetFormNo.form_no#&amp;reqno=#Arguments.RequestData.request_no#&planformno=&reqorder=#reqorder#&amp;varcoid=#request.scookie.coid#&amp;varcocode=#request.scookie.cocode#"><span>#LOCAL.SFMLANG.ViewPerformanceEvaluationForm#</span></a>
						<cfelse>
							<a href="?xfid=hrm.performance.evalform.mainload&empid=#Arguments.RequestData.EMP_ID#&periodcode=#Arguments.RequestData.period_code#&refdate=#Arguments.RequestData.reference_date#&formno=#qGetFormNo.form_no#&amp;reqno=#Arguments.RequestData.request_no#&planformno=&reqorder=#reqorder#&amp;varcoid=#request.scookie.coid#&amp;varcocode=#request.scookie.cocode#"><span>#LOCAL.SFMLANG.ViewPerformanceEvaluationForm#</span></a>
						</cfif>
					<cfelse>
						<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE EQ 1>
							<a href="?sfid=hrm.performance.evalform.newlayout.viewevalform&empid=#Arguments.RequestData.requestfor#&periodcode=#Arguments.RequestData.period_code#&refdate=#Arguments.RequestData.reference_date#&formno=#qGetFormNo.form_no#&amp;reqno=#Arguments.RequestData.request_no#&planformno=&reqorder=#reqorder#&amp;varcoid=#request.scookie.coid#&amp;varcocode=#request.scookie.cocode#"><span>#LOCAL.SFMLANG.ViewPerformanceEvaluationForm#</span></a>
						<cfelse>
							<a href="?xfid=hrm.performance.evalform.mainload&empid=#Arguments.RequestData.requestfor#&periodcode=#Arguments.RequestData.period_code#&refdate=#Arguments.RequestData.reference_date#&formno=#qGetFormNo.form_no#&amp;reqno=#Arguments.RequestData.request_no#&planformno=&reqorder=#reqorder#&amp;varcoid=#request.scookie.coid#&amp;varcocode=#request.scookie.cocode#"><span>#LOCAL.SFMLANG.ViewPerformanceEvaluationForm#</span></a>
						</cfif>
					</cfif>
					
	               
	            </div>
				<br />
			</cfoutput>
			<cfreturn scProc>
		</cffunction>
	    
	    
		
	    <!--- ambil list lookup score --->
	    <cffunction name="getLookUpScoreList">
	    	<cfargument name="lookupcode" default="">
	    	<cfargument name="periodcode" default="">
	    	<cfargument name="componentcode" default="">
	        <cfargument name="refdate" default="">
			<cfquery name="local.qGetLookup" datasource="#request.sdsn#">
		        SELECT  ML.method, ML.symbol, DL.lookup_score, DL.lookup_value
				FROM TPMDLOOKUP DL
					INNER JOIN TPMMLOOKUP ML ON ML.lookup_code = DL.lookup_code AND ML.period_code = DL.period_code AND ML.company_code = DL.company_code
					INNER JOIN TPMDPERIODCOMPONENT C ON C.period_code = ML.period_code AND C.company_code = C.company_code
	                	<cfif not len(refdate)>
						AND C.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	                    </cfif>
				WHERE C.lookup_code = <cfqueryparam value="#arguments.lookupcode#" cfsqltype="cf_sql_varchar">
					AND C.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND C.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND C.component_code = <cfqueryparam value="#arguments.componentcode#" cfsqltype="cf_sql_varchar">
			</cfquery>
	        
	        <cfreturn qGetLookup>
	    </cffunction>

	    <!--- ambil data-data period --->
	    <cffunction name="getPeriodData">
	    	<cfargument name="periodcode" default="">
	        <cfargument name="refdate" default="">
	        <cfargument name="varcocode" default="#request.scookie.cocode#" required="No">
	        <cfquery name="Local.qData" datasource="#request.sdsn#">
				SELECT  P.period_name_#request.scookie.lang# AS period_name, P.reference_date, P.final_startdate, P.final_enddate, P.conclusion_lookup, P.score_type, P.period_startdate, P.period_enddate, P.gauge_type, P.usenormalcurve
				FROM TPMMPERIOD P
				WHERE P.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND P.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
					AND P.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfreturn qData>
	    </cffunction>

	    <!--- fungsi ini buat ambil bobot komponen period, baik untuk posisi tersebut ada atau tidak (ambil dari yang general) --->
	    <cffunction name="getPeriodCompData">
	    	<cfargument name="periodcode" default="">
	        <cfargument name="refdate" default="">
	        <cfargument name="posid" default="">
	        <cfargument name="compcode" default="">
	        <cfquery name="Local.qData" datasource="#request.sdsn#">
	        	SELECT DISTINCT PC.component_code,
				lookup_scoretype, lookup_total, <!---- added by ENC51017-81177 --->
	            	<cfif len(arguments.posid)>
					CASE WHEN CPW.weight IS NOT NULL THEN CPW.weight ELSE PC.weight END weight
	                <cfelse>
	                PC.weight
	                </cfif>
				FROM TPMDPERIODCOMPONENT PC

	           	<cfif len(arguments.posid)>
				LEFT JOIN TPMDPERIODCOMPPOSWEIGHT CPW 
					ON CPW.period_code = PC.period_code 
					AND CPW.reference_date = PC.reference_date 
					AND CPW.component_code = PC.component_code
					AND CPW.company_code = PC.company_code
					AND CPW.position_id = <cfqueryparam value="#arguments.posid#" cfsqltype="cf_sql_integer">
	            </cfif>
	            
				WHERE PC.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	            	AND PC.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	                <cfif len(arguments.compcode)>
	                	AND PC.component_code = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                </cfif>
	        </cfquery>
		
	        <cfreturn qData>
	    </cffunction>

	    <cffunction name="getReqEmpData">
	        <cfargument name="reqno" default="">
	        <cfargument name="formno" default="">
	        <cfargument name="empid" default="">
	    	<cfargument name="periodcode" default="">
	        <cfargument name="refdate" default="">
	        <cfargument name="reviewer" default="">
	        <cfargument name="compcode" default=""> <!--- ALL / COMPONENT / APPRAISAL / PERSKPI / ORGKPI / COMPETENCY --->
	        <cfargument name="libcode" default="">
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">
	        <cfquery name="Local.qData" datasource="#request.sdsn#">
	        	SELECT EH.form_no, ED.lib_code, ED.lib_type, ED.achievement, 
	        	    case when ED.score is null then 0 else ED.score end score, 
	        	    case when ED.weightedscore is null then 0 else ED.weightedscore end weightedscore, 
	        	    case when ED.weight is null then 0 else ED.weight end weight,
	        	    ED.target, ED.notes
					,ED.reviewer_empid ,EH.score AS conscore, EH.conclusion
				FROM TPMDPERFORMANCE_EVALH EH
				LEFT JOIN TPMDPERFORMANCE_EVALD ED 
	            	ON ED.form_no = EH.form_no 
	                AND ED.company_code = EH.company_code 
	   	            AND ED.reviewer_empid = EH.reviewer_empid
				WHERE EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
					AND EH.reviewee_empid = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
					AND EH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND EH.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
					AND EH.reviewer_empid IN (<cfqueryparam value="#arguments.reviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	   	            AND ED.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
					AND ED.lib_type = <cfqueryparam value="COMPONENT" cfsqltype="cf_sql_varchar">
	                <cfif len(arguments.libcode)>
						AND ED.lib_code = <cfqueryparam value="#arguments.libcode#" cfsqltype="cf_sql_varchar">
	                </cfif>
	   	    </cfquery>
	           
	        <cfreturn qData>
	    </cffunction>

	    <cffunction name="getActualAndScoreType">
	    	<cfargument name="periodcode" default="">
	    	<cfargument name="compcode" default="">
	        <cfargument name="varcocode" default="#request.scookie.cocode#" required="No">
			
	        <cfquery name="Local.qGetType" datasource="#request.sdsn#">
	        	SELECT P.conclusion_lookup, PC.component_code, PC.actual_type, PC.lookup_code,
				<!---- Start : ENC51017-81177 --->
				CASE WHEN PC.lookup_scoretype <> '0' AND  PC.lookup_scoretype <> '' THEN PC.lookup_scoretype ELSE P.score_type END AS score_type
			
				<!---- end : ENC51017-81177 --->
				FROM TPMMPERIOD P
				INNER JOIN TPMDPERIODCOMPONENT PC 
					ON PC.period_code = P.period_code 
					AND PC.company_code = P.company_code 
					AND PC.reference_date = P.reference_date
				WHERE P.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND P.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	                <cfif len(arguments.compcode)>
	                AND PC.component_code = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                </cfif>
	        </cfquery>
	        <cfreturn qGetType>
	    </cffunction>

	    <cffunction name="getScoringDetail">
	    	<cfargument name="scorecode" default="">
	    	<cfargument name="complibcode" default=""> <!--- untuk competency lib --->
	        <cfargument name="varcocode" default="#request.scookie.cocode#" required="No"> <!--- ENC51115-79853 --->
			
	        <cfif len(scorecode)>
		    	<cfquery name="local.qGetScDet" datasource="#request.sdsn#">
		        	SELECT S.score_type,
		        	    <cfif request.dbdriver eq "MSSQL"> 
		        	    '['+CONVERT(varchar,scoredet_value)+'] '+ SD.scoredet_mask AS opttext, 
		        	    <cfelse>
		        	    '['||CONVERT(scoredet_value,char)||'] '|| coalesce(SD.scoredet_mask,'') AS opttext, 
		        	    </cfif>
	                	SD.scoredet_value AS optvalue, SD.scoredet_value, SD.scoredet_desc, SD.scoredet_mask
					FROM TGEMSCORE S
					INNER JOIN TGEDSCOREDET SD ON SD.score_code = S.score_code AND SD.company_code = S.company_code
					WHERE S.score_code = <cfqueryparam value="#arguments.scorecode#" cfsqltype="cf_sql_varchar">
						AND S.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					ORDER BY SD.scoredet_value
		        </cfquery>
				<cfreturn qGetScDet>
				
	      <cfelseif len(complibcode)>

		    	<cfquery name="local.qGetScDet" datasource="#request.sdsn#">
	            	SELECT 'L' score_type, point_value AS optvalue, 
	            	<cfif request.dbdriver eq "MSSQL"> 
	            	'['+CONVERT(varchar,point_value)+'] '+ point_name_#request.scookie.lang# AS opttext
	            	<cfelse>
	            	'['||CONVERT(point_value,char)||'] '|| point_name_#request.scookie.lang# AS opttext
	            	</cfif>
					FROM TPMDCOMPETENCEPOINT
					WHERE competence_code = <cfqueryparam value="#arguments.complibcode#" cfsqltype="cf_sql_varchar">
					ORDER BY point_value
		        </cfquery>
				<cfreturn qGetScDet> 
	        </cfif>
	        
	        
	    </cffunction>
	    
		
		
		
		
		
		

	    <cffunction name="getJSONForLookUp">
	    	<cfargument name="periodcode" default="">
	        <cfargument name="lookupcode" default="">
	        <cfargument name="varcocode" default="#request.scookie.cocode#" required="No">
	        <cfset Local.strckLookData = structnew()>
	        <cfset Local.strckReturnData = structnew()>
	        <cfset local.strckTemp = structnew()>

	        <cfquery name="local.qGetLookUpDetail" datasource="#request.sdsn#">
				SELECT  M.method, M.symbol
				FROM TPMMLOOKUP M 
				WHERE M.lookup_code = <cfqueryparam value="#lookupcode#" cfsqltype="cf_sql_varchar">
					AND M.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND M.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
			</cfquery>
			
			<cfif qGetLookUpDetail.recordcount eq 0>
				<cfquery name="local.qGetLookUpDetail" datasource="#request.sdsn#">
					SELECT  M.method, M.symbol
					FROM TPMMLOOKUP M 
					WHERE M.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
						AND M.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				</cfquery>
			
			</cfif>

	        <cfset strckTemp["method"] = qGetLookUpDetail.method>
	        <cfset strckTemp["symbol"] = qGetLookUpDetail.symbol>
	        
	        <cfquery name="local.qGetLookUpDetail" datasource="#request.sdsn#">
				<!---
				ada ubah PK di TPMDLOOKUP
				SELECT D.lookup_value AS returnval, D.lookup_score AS lookval, M.method, M.symbol
				--->
				SELECT D.lookup_score AS returnval, D.lookup_value AS lookval, M.method, M.symbol
				FROM TPMMLOOKUP M 
				INNER JOIN TPMDLOOKUP D 
			    	ON D.lookup_code = M.lookup_code 
			        AND D.period_code = M.period_code 
			        AND D.company_code = M.company_code
				WHERE M.lookup_code = <cfqueryparam value="#lookupcode#" cfsqltype="cf_sql_varchar">
					AND M.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND M.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				ORDER BY <cfif request.dbdriver eq "MSSQL">CONVERT(FLOAT,D.lookup_value)<cfelse>CONVERT(D.lookup_value,DOUBLE)</cfif> <cfif listfindnocase("LT,LTE",ucase(strckTemp.symbol))>ASC<cfelseif listfindnocase("GT,GTE",ucase(strckTemp.symbol))>DESC</cfif>
			</cfquery>
			
			<cfif qGetLookUpDetail.recordcount eq 0>
				<cfquery name="local.qGetLookUpDetail" datasource="#request.sdsn#">
					<!---
					ada ubah PK di TPMDLOOKUP
					SELECT D.lookup_value AS returnval, D.lookup_score AS lookval, M.method, M.symbol
					--->
					SELECT D.lookup_score AS returnval, D.lookup_value AS lookval, M.method, M.symbol
					FROM TPMMLOOKUP M 
					INNER JOIN TPMDLOOKUP D 
						ON D.lookup_code = M.lookup_code 
						AND D.period_code = M.period_code 
						AND D.company_code = M.company_code
					WHERE M.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
						AND M.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					<!---ORDER BY <cfif request.dbdriver eq "MSSQL">CONVERT(FLOAT,D.lookup_value)<cfelse>CONVERT(D.lookup_value,DOUBLE)</cfif> <cfif listfindnocase("LT,LTE",ucase(strckTemp.symbol))>ASC<cfelseif listfindnocase("GT,GTE",ucase(strckTemp.symbol))>DESC</cfif> --->
				</cfquery>
				
			</cfif>

	        <cfloop query="qGetLookUpDetail">
	        	<cfset strckLookData["#currentrow#"] = lookval>
	        	<cfset strckReturnData["#currentrow#"] = returnval>
	        	
	        </cfloop>
	        <cfset strckTemp["look"] = strckLookData>
	        <cfset strckTemp["return"] = strckReturnData>
	       
	       	<cfreturn serializeJSON(strckTemp)>
			
	    </cffunction>
	    
	    <cffunction name="getEmpName">
	    	<cfparam name="empid" default="">

			<cfquery name="local.qGetEmp" datasource="#request.sdsn#">
				SELECT DISTINCT full_name + ' [' + emp_no + ']' empname
				FROM TEOMEMPPERSONAL join TEODEMPCOMPANY on TEOMEMPPERSONAL.emp_id = TEODEMPCOMPANY.emp_id
				AND TEOMEMPPERSONAL.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfreturn qGetEmp>
		</cffunction>
		
		<cffunction name="getEmpLogin">
	    	<cfargument name="empid" default="">

			<cfquery name="local.qGetEmp" datasource="#request.sdsn#">
				SELECT DISTINCT full_name
				FROM TEOMEMPPERSONAL
				WHERE emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfreturn qGetEmp.full_name>
		</cffunction>
		
		<cffunction name="TaskDash">
	    	<cfargument name="empid" default="">
			<cfargument name="startdate" default="">
			<cfargument name="enddate" default="">
			<cfargument name="chkstat" default="6">
			
			<cfif len(trim(startdate)) eq 0>
				<cfset startdate = createdate(year(now()),1,1)>			
			</cfif>

			<cfif len(trim(enddate)) eq 0>
				<cfset enddate = createdate(year(now()),12,31)>			
			</cfif>
			
	        <cfquery name="local.qGetTaskListing" datasource="#request.sdsn#">
	        	SELECT  TK.task_code, EP.full_name AS asignee_name, TK.task_desc, TK.priority, TK.status, TK.startdate, TK.duedate, GBY.full_name AS givenby, TK.status_task, TK.completion_date, TK.created_task
				FROM TPMDTASK TK
				INNER JOIN TEOMEMPPERSONAL GBY
					ON GBY.emp_id = TK.created_task
				INNER JOIN TEOMEMPPERSONAL EP 
					ON EP.emp_id = TK.assignee 
					AND TK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND TK.assignee = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
				WHERE TK.duedate >= <cfqueryparam value="#startdate#" cfsqltype="cf_sql_timestamp">
				AND TK.duedate <= <cfqueryparam value="#enddate#" cfsqltype="cf_sql_timestamp">
				<cfif chkstat neq 6>
					AND TK.status_task IN (<cfqueryparam value="#chkstat#" cfsqltype="cf_sql_varchar" list="yes">)
				</cfif>
				ORDER BY duedate, startdate, GBY.full_name
	        </cfquery>
	        <cfreturn qGetTaskListing>
	    </cffunction>
		
		<cffunction name="FeedbackDash">
	    	<cfargument name="empid" default="">
			<cfargument name="startdate" default="">
			<cfargument name="enddate" default="">
			<cfargument name="chkFeedback" default="6">
			
			<cfif len(trim(startdate)) eq 0>
				<cfset startdate = createdate(year(now()),1,1)>			
			</cfif>

			<cfif len(trim(enddate)) eq 0>
				<cfset enddate = createdate(year(now()),12,31)>			
			</cfif>

	        <cfquery name="local.qGetFeedbackListing" datasource="#request.sdsn#">
	        	SELECT  FB.feedback_code, EP.full_name AS asignee_name, FB.feedback_type, FB.feedback_desc, FB.severity_level, FB.status, FB.created_date, GBY.full_name AS givenby, FB.created_feedback
				FROM TPMDFEEDBACK FB
				INNER JOIN TEOMEMPPERSONAL GBY
					ON GBY.emp_id = FB.created_feedback
				INNER JOIN TEOMEMPPERSONAL EP 
					ON EP.emp_id = FB.feedback_for
					AND FB.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND FB.feedback_for = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
				WHERE FB.created_date >= <cfqueryparam value="#startdate#" cfsqltype="cf_sql_timestamp">
				AND FB.created_date <= <cfqueryparam value="#enddate#" cfsqltype="cf_sql_timestamp">
				<cfif chkFeedback neq 4>
					AND FB.feedback_type IN (<cfqueryparam value="#chkFeedback#" cfsqltype="cf_sql_varchar" list="yes">)
				</cfif>
				ORDER BY created_date ASC, GBY.full_name
	        </cfquery>

	        <cfreturn qGetFeedbackListing>
	    </cffunction>
		
		<cffunction name="TaskNotes">
	    	<cfparam name="task_code" default="">
			
			<cfquery name="local.qGetTaskListing" datasource="#request.sdsn#">
	        	SELECT DISTINCT TK.task_code, EP.full_name AS asignee_name, TK.task_desc, TK.priority, TK.status, TK.startdate, TK.duedate, GBY.full_name AS empname, TK.status_task, TK.completion_date, TK.created_task
				FROM TPMDTASK TK
				INNER JOIN TEOMEMPPERSONAL GBY
					ON GBY.emp_id = TK.assignee
				INNER JOIN TEOMEMPPERSONAL EP 
					ON EP.emp_id = TK.assignee 
					AND TK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND TK.task_code = <cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">			
	        </cfquery>
	        <cfreturn qGetTaskListing>
	    </cffunction>
		
		<cffunction name="SaveTask">
			<cfoutput>
				<cfset LOCAL.SFLANG1=Application.SFParser.TransMLang("JSTask Desc Is Empty",true)>
				<cfset LOCAL.SFLANG2=Application.SFParser.TransMLang("JSStart Date Is Empty",true)>
				<cfset LOCAL.SFLANG3=Application.SFParser.TransMLang("JSStart Date Is Not In Date Format",true)>
				<cfset LOCAL.SFLANG4=Application.SFParser.TransMLang("JSDue Date Is Empty",true)>
				<cfset LOCAL.SFLANG5=Application.SFParser.TransMLang("JSDue Date Is Not In Date Format",true)>
				<cfset LOCAL.SFLANG6=Application.SFParser.TransMLang("JSCompletion Date Is Not In Date Format",true)>
				<cfset LOCAL.SFLANG7=Application.SFParser.TransMLang("JSCompletion Date Is Empty",true)>
				
				<cftransaction>
					<cfloop from="1" to="#hdn_totalrow#" index="local.idx">
						<cfif isdefined("task_code_#idx#")>
							<cfset local.task_code = evaluate("task_code_#idx#")>
							<cfset local.task_desc = evaluate("task_desc_#idx#")>
							<cfset local.start_date = evaluate("startdate_#idx#")>
							<cfset local.due_date = evaluate("duedate_#idx#")>
							<cfset local.priority = evaluate("priority_#idx#")>
							<cfif isdefined("status_#idx#")>
								<cfset local.status_task = evaluate("status_#idx#")>
								<cfset local.completion_date = evaluate("completiondate_#idx#")>
								
								<cfif len(trim(task_desc)) eq 0>
									<script>
										alert("#SFLANG1#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif len(trim(start_date)) eq 0>
									<script>
										alert("#SFLANG2#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif not isdate(start_date)>
									<script>
										alert("#SFLANG3#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif len(trim(due_date)) eq 0>
									<script>
										alert("#SFLANG4#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif not isdate(due_date)>
									<script>
										alert("#SFLANG5#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif len(trim(completion_date)) and not isdate(completion_date)>
									<script>
										alert("#SFLANG6#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif (status_task eq 2 or status_task eq 3) and len(trim(completion_date)) eq 0>
									<script>
										maskButton(false);
									</script>
									<CF_SFABORT>
								</cfif>
								
								<cfif evaluate("task_code_#idx#") neq "---"> <!--- update data yang lama --->
									<cfquery name="local.qUpdate" datasource="#request.sdsn#">
										UPDATE TPMDTASK
										SET task_desc = <cfqueryparam value="#task_desc#" cfsqltype="cf_sql_varchar">
										,priority = <cfqueryparam value="#priority#" cfsqltype="cf_sql_integer">
										,status_task = <cfqueryparam value="#status_task#" cfsqltype="cf_sql_integer">
										,startdate = <cfqueryparam value="#CreateODBCDate(start_date)#" cfsqltype="cf_sql_timestamp">
										,duedate = <cfqueryparam value="#CreateODBCDate(due_date)#" cfsqltype="cf_sql_timestamp">
										<cfif (status_task eq 2 or status_task eq 3) and len(trim(completion_date))>
											,completion_date = <cfqueryparam value="#CreateODBCDate(completion_date)#" cfsqltype="cf_sql_timestamp">
										<cfelse>
											,completion_date = NULL
										</cfif>
										WHERE task_code = <cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">
										AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
									</cfquery>
								<cfelse> <!--- insert data baru --->
									<cfset task_code = trim(Application.SFUtil.getCode("PRMTASK",'no','true'))>
									<cfquery name="local.qInsert" datasource="#request.sdsn#">
										INSERT INTO TPMDTASK (task_code, assignee, company_code, task_desc, priority, status, 
										startdate, duedate, created_by, created_date, modified_by, modified_date, created_task, status_task, completion_date)
										VALUES(
										<cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#assignee#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#task_desc#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#priority#" cfsqltype="cf_sql_integer">,
										0,
										<cfqueryparam value="#CreateODBCDate(start_date)#" cfsqltype="cf_sql_timestamp">,
										<cfqueryparam value="#CreateODBCDate(due_date)#" cfsqltype="cf_sql_timestamp">,
										<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
										<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
										<cfqueryparam value="#emplogin#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#status_task#" cfsqltype="cf_sql_integer">,
										<cfif (status_task eq 2 or status_task eq 3) and len(trim(completion_date))>
											<cfqueryparam value="#CreateODBCDate(completion_date)#" cfsqltype="cf_sql_timestamp">
										<cfelse>
											NULL
										</cfif>
										)
									</cfquery>
								</cfif>
							</cfif>
						</cfif>
					</cfloop>
				</cftransaction>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Update Performance Task",true)>
				<script>
					alert("#SFLANG#");
					parent.popClose();
					refreshPage();
				</script>
			</cfoutput>	
		</cffunction>
		
		<cffunction name="SaveFeedback">
			<cfoutput>
				<cfset LOCAL.SFLANG1=Application.SFParser.TransMLang("JSFeedback Desc Is Empty",true)>
				<cfset LOCAL.SFLANG2=Application.SFParser.TransMLang("JSDate Is Empty",true)>
				<cfset LOCAL.SFLANG3=Application.SFParser.TransMLang("JSDate Is Not In Date Format",true)>
				
				<cftransaction>
					<cfloop from="1" to="#hdn_totalrow#" index="local.idx">
						<cfif isdefined("feedback_code_#idx#")>
							<cfset local.feedback_code = evaluate("feedback_code_#idx#")>
							<cfset local.feedback_desc = evaluate("feedback_desc_#idx#")>
							<cfset local.created_date = evaluate("createddate_#idx#")>
							<cfset local.feedback_type = evaluate("feedback_type_#idx#")>
							<cfset local.severity_level = evaluate("severity_level_#idx#")>
							
							<cfif len(trim(feedback_desc)) eq 0>
								<script>
									alert("#SFLANG1#");
									maskButton(false);
								</script>
								<CF_SFABORT>
							<cfelseif len(trim(created_date)) eq 0>
								<script>
									alert("#SFLANG2#");
									maskButton(false);
								</script>
								<CF_SFABORT>
							<cfelseif not isdate(created_date)>
								<script>
									alert("#SFLANG3#");
									maskButton(false);
								</script>
								<CF_SFABORT>
							</cfif>
							
							<cfif feedback_code neq "---"> <!--- update data yang lama --->
								<cfquery name="local.qUpdate" datasource="#request.sdsn#">
									UPDATE TPMDFEEDBACK
									SET feedback_desc = <cfqueryparam value="#feedback_desc#" cfsqltype="cf_sql_varchar">
									,feedback_type = <cfqueryparam value="#feedback_type#" cfsqltype="cf_sql_varchar">
									,severity_level = <cfqueryparam value="#severity_level#" cfsqltype="cf_sql_integer">
									,created_date = <cfqueryparam value="#created_date#" cfsqltype="cf_sql_timestamp">
									,modified_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
									WHERE feedback_code = <cfqueryparam value="#feedback_code#" cfsqltype="cf_sql_varchar">
									AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
								</cfquery>
							<cfelse> <!--- insert data baru --->
								<cfset feedback_code = trim(Application.SFUtil.getCode("PRMFEEDBACK",'no','true'))>
								<cfquery name="local.qInsert" datasource="#request.sdsn#">
									INSERT INTO TPMDFEEDBACK (feedback_code, feedback_for, company_code, feedback_type,
									feedback_desc, severity_level, status, created_by, created_date, modified_by, modified_date, created_feedback)
									VALUES(
									<cfqueryparam value="#feedback_code#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#assignee#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#feedback_type#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#feedback_desc#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#severity_level#" cfsqltype="cf_sql_integer">,
									0,
									<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#created_date#" cfsqltype="cf_sql_timestamp">,
									<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
									<cfqueryparam value="#emplogin#" cfsqltype="cf_sql_varchar">
									)
								</cfquery>
							</cfif>
						</cfif>
					</cfloop>
				</cftransaction>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Update Performance Feedback",true)>
				<script>
					alert("#SFLANG#");
					parent.popClose();
					refreshPage();
				</script>
			</cfoutput>	
		</cffunction>
		
		<cffunction name="saveNotes">
			<cfparam name="emplogin" default="">
			<cfparam name="assigner" default="">
			<cfparam name="assignee" default="">
			<cfparam name="task_code" default="">
			<cfparam name="hdnFlag" default="">
			
			<cfoutput>
			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSCompletion Date Is Empty",true)>
			
			<cftransaction>
			<cfif hdnFlag eq 2>			
				<cfif empStatus eq 2 and len(trim(EmpCompletionDate)) eq 0>
					<script>
						alert("#SFLANG#");
						maskButton(false);
					</script>
					<CF_SFABORT>
				</cfif>
				
				<cfquery name="local.qUpdate" datasource="#request.sdsn#">
					UPDATE TPMDTASK
					SET status_task = <cfqueryparam value="#empStatus#" cfsqltype="cf_sql_varchar">,
					<cfif empStatus eq 2 and len(trim(EmpCompletionDate)) and isdate(EmpCompletionDate)>
						completion_date = <cfqueryparam value="#EmpCompletionDate#" cfsqltype="cf_sql_timestamp">
					<cfelse>
						completion_date = NULL
					</cfif>
					WHERE task_code = <cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				</cfquery>
			<cfelse>
				<cfif status_task eq 2 and len(trim(completiondate)) eq 0>
					<script>
						alert("#SFLANG#");
						maskButton(false);
					</script>
					<CF_SFABORT>
				</cfif>
				
				<cfquery name="local.qUpdate" datasource="#request.sdsn#">
					UPDATE TPMDTASK
					SET priority = <cfqueryparam value="#priority#" cfsqltype="cf_sql_varchar">,
						status_task = <cfqueryparam value="#status_task#" cfsqltype="cf_sql_varchar">,
					<cfif (status_task eq 2 or status_task eq 3) and len(trim(completiondate)) and isdate(completiondate)>
						completion_date = <cfqueryparam value="#completiondate#" cfsqltype="cf_sql_timestamp">
					<cfelse>
						completion_date = NULL
					</cfif>
					<cfif emplogin eq assigner and isdefined("startdate") and isdate(startdate)>
						,startdate = <cfqueryparam value="#startdate#" cfsqltype="cf_sql_timestamp">
					</cfif>
					<cfif emplogin eq assigner and isdefined("duedate") and isdate(duedate)>
						,duedate = <cfqueryparam value="#duedate#" cfsqltype="cf_sql_timestamp">
					</cfif>
					WHERE task_code = <cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				</cfquery>
			</cfif>
			
			<cfif isdefined("task_note") and len(trim(task_note))>
				<cfquery name="local.qOrder" datasource="#request.sdsn#">
					SELECT max(note_order) maxorder FROM TPMDTASKNOTES
					WHERE task_code = <cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">
				</cfquery>
				
				<cfset local.order_no = val(qOrder.maxorder) + 1>
				<cfquery name="local.qInsert" datasource="#request.sdsn#">
					INSERT INTO TPMDTASKNOTES  (task_code,company_code,note_order,task_note,created_by,created_date,modified_by,modified_date)  
					VALUES(
						<cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#order_no#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#task_note#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
						<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
					)
				</cfquery>	
			</cfif>	
			</cftransaction>
			
			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Update Detail Performance Task",true)>
				<script>
					alert("#SFLANG#");
					parent.popClose();
					refreshPage();
				</script>
			</cfoutput>			
		</cffunction>

	    <!--- tambahan yan --->
	<cffunction name="getLibComparison">
	        <cfargument name="empid" default="">
	        <cfargument name="periodcode" default="">
	        <cfargument name="reviewer" default="">
	        <cfargument name="libtype" default="">
	        <cfargument name="libcode" default="">
	        <cfargument name="refdate" default="">
	        
	        <cfquery name="Local.qData" datasource="#request.sdsn#">
	        	SELECT DISTINCT C.full_name AS empname, D.pos_name_en AS emppos, E.grade_name AS empgrade, A.achievement, A.score, H.reviewee_empid, B.emp_no AS empno 
	           	<cfif ucase(libtype) eq "APPRAISAL">
		            , LIB.appraisal_name_#request.scookie.lang# AS lib_name
	           	<cfelseif listfindnocase("PERSKPI,ORGKPI",ucase(libtype))>
	               	, LIB.kpi_name_#request.scookie.lang# AS lib_name
	           	<cfelseif ucase(libtype) eq "COMPETENCE">
	               	, LIB.competence_name_#request.scookie.lang# AS lib_name
	            </cfif>
				FROM TPMDPERFORMANCE_EVALD A 

	           	<cfif ucase(libtype) eq "APPRAISAL">
				LEFT JOIN TPMDPERIODAPPRLIB LIB 
					ON LIB.apprlib_code = A.lib_code 
	           	<cfelseif listfindnocase("PERSKPI,ORGKPI",ucase(libtype))>
	            LEFT JOIN TPMDPERIODKPILIB LIB 
	            	ON LIB.kpilib_code = A.lib_code
	           	<cfelseif ucase(libtype) eq "COMPETENCE">
	            LEFT JOIN TPMMCOMPETENCE LIB 
	            	ON LIB.competence_code = A.lib_code
	            </cfif>
	           	<cfif listfindnocase("PERSKPI,ORGKPI,APPRAISAL",ucase(libtype))>
					AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND LIB.reference_date = <cfqueryparam value="#refdate#" cfsqltype="cf_sql_timestamp">
					AND LIB.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            </cfif>
				INNER JOIN TPMDPERFORMANCE_EVALH H 
					ON H.form_no = A.form_no 
					AND H.company_code = A.company_code 
					AND H.reviewer_empid = A.reviewer_empid
	                AND H.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					<!--- nilainya ambil langsung dari form pake js--->
	                AND H.reviewee_empid <> <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					AND H.reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">

				LEFT JOIN TEODEMPCOMPANY B 
	            	ON B.emp_id = H.reviewee_empid AND B.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMEMPPERSONAL C 
	            	ON C.emp_id = B.emp_id
				LEFT JOIN TEOMPOSITION D 
	            	ON D.position_id = B.position_id 
	            	AND D.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMJOBGRADE E 
	            	ON E.grade_code = B.grade_code 
	                AND E.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				WHERE A.lib_type = <cfqueryparam value="#libtype#" cfsqltype="cf_sql_varchar">
					AND A.lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
				ORDER BY A.score DESC

	        	<!---SELECT C.full_name AS empname, D.pos_name_#request.scookie.lang# AS emppos, E.grade_name AS empgrade, A.achievement, H.reviewee_empid, B.emp_no AS empno
	           	<cfif ucase(libtype) eq "APPRAISAL">
	               	, LIB.appraisal_name AS lib_name
	           	<cfelseif ucase(libtype) eq "OBJECTIVE">
	               	, LIB.objective_name AS lib_name
	           	<cfelseif ucase(libtype) eq "COMPETENCE">
	               	, LIB.competency_name AS lib_name
	            </cfif>
				FROM TPMDCPMLIBDETAIL A
	           	<cfif ucase(libtype) eq "APPRAISAL">
	            LEFT JOIN TPMDPERIODAPPLIB LIB ON LIB.appraisal_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	           	<cfelseif ucase(libtype) eq "OBJECTIVE">
	            LEFT JOIN TPMDPERIODOBJLIB LIB ON LIB.objective_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	           	<cfelseif ucase(libtype) eq "COMPETENCE">
	            LEFT JOIN TPMDPERIODCOMPLIB LIB ON LIB.competence_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	            </cfif>
	            INNER JOIN TPMDCPMH 
	            	H ON H.request_no = A.request_no 
	                AND H.company_code = A.company_code
	                AND H.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	                
					<!--- nilainya ambil langsung dari form pake js--->
	                AND H.reviewee_empid <> <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	                
				LEFT JOIN TEODEMPCOMPANY B 
	            	ON B.emp_id = H.reviewee_empid AND B.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMEMPPERSONAL C 
	            	ON C.emp_id = B.emp_id
				LEFT JOIN TEOMPOSITION D 
	            	ON D.position_id = B.position_id 
	            	AND D.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMJOBGRADE E 
	            	ON E.grade_code = B.grade_code 
	                AND E.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				WHERE A.lib_type = <cfqueryparam value="#libtype#" cfsqltype="cf_sql_varchar">
					AND A.lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
	            ORDER BY A.achievement DESC--->
	        </cfquery>
	        <cfreturn qData>
	    </cffunction>
	    
        <cffunction name="getEmpFormData">
	    	<cfargument name="empid" default="">
	        <cfargument name="periodcode" default="">
	        <cfargument name="refdate" default="">
	        <cfargument name="compcode" default="">
	        <cfargument name="reqno" default="">
	        <cfargument name="formno" default="">
	        <cfargument name="reviewerempid" default="">
	        <cfargument name="lastreviewer" default="">
			<!---start : ENC51115-79853--->
			<cfargument name="varcoid" required="No" default="#request.scookie.coid#"> 
			<cfargument name="varcocode" required="No" default="#request.scookie.cocode#">
			 <!---end : ENC51115-79853--->
	        <!--- bakalan ada kasus kalo pindah posisi (SOLUSI : harusnya dipassing atau ?)--->
	        <cfquery name="Local.qGetEmpAttr" datasource="#request.sdsn#">
	        	SELECT DISTINCT EC.position_id AS posid, POS.dept_id AS deptid, POS.jobtitle_code AS jtcode
				FROM TEODEMPCOMPANY EC
	            LEFT JOIN TEOMPOSITION POS 
	            	ON POS.position_id = EC.position_id 
		            AND POS.company_id = EC.company_id
				WHERE EC.emp_id = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
					AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
	        </cfquery>
	        <cfif ucase(compcode) eq "ORGKPI">
		        <cfset local.empposid = qGetEmpAttr.deptid>
	        <cfelse>
		        <cfset local.empposid = qGetEmpAttr.posid>
	        </cfif>
	        
	        <!--- Task: BUG50615-45605 --->
	        <cfif len(empposid) eq 0>
	            <cfset empposid = -1>
	        </cfif>
	        
	        <cfset local.showFromLastReviewer = 0>
	        <!--- cek kalo udah pernah kesimpan belum (untuk kasus, tabnya ga dibuka terlebih dahulu --->
	        <cfset local.lstLibCode = "">
	        <cfif listfindnocase("COMPETENCY,PERSKPI,ORGKPI,APPRAISAL",ucase(compcode))>
		        <cfquery name="Local.qCekData" datasource="#request.sdsn#">
	    	    	SELECT DISTINCT D.lib_code
					FROM TPMDPERFORMANCE_EVALH H
					INNER JOIN TPMDPERFORMANCE_EVALD D 
						ON D.form_no = H.form_no
						AND D.reviewer_empid = H.reviewer_empid
						AND D.lib_type = <cfqueryparam value="#ucase(arguments.compcode)#" cfsqltype="cf_sql_varchar"> 
					WHERE H.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
						AND H.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">

						<cfif REQUEST.DBDRIVER EQ 'ORACLE'>
							AND H.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
						<cfelse>
							AND H.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
						</cfif>

						AND H.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
						AND H.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						AND H.reviewer_empid = <cfqueryparam value="#reviewerempid#" cfsqltype="cf_sql_varchar">
		        </cfquery>
	            <cfif not qCekData.recordcount>
			        <cfquery name="Local.qCekData" datasource="#request.sdsn#">
		    	    	SELECT DISTINCT D.lib_code
						FROM TPMDPERFORMANCE_EVALH H
						INNER JOIN TPMDPERFORMANCE_EVALD D 
							ON D.form_no = H.form_no
							AND D.reviewer_empid = H.reviewer_empid
							AND D.lib_type = <cfqueryparam value="#ucase(arguments.compcode)#" cfsqltype="cf_sql_varchar"> 
						WHERE H.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
							AND H.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
							AND H.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
							AND H.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
							AND H.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
							AND H.reviewer_empid = <cfqueryparam value="#lastreviewer#" cfsqltype="cf_sql_varchar">
			        </cfquery>
		            <cfset showFromLastReviewer = 1>
	            </cfif>
	            <cfif listlen(arguments.reviewerempid)>
	            </cfif>
	            <cfset lstLibCode = valuelist(qCekData.lib_code)>
	            <cfset local.records = qCekData.recordcount>
	        </cfif>
	        
	        <cfif ucase(compcode) eq "COMPETENCY">
	            <cfif request.dbdriver eq "MSSQL">
	            <cfquery name="Local.qGetCompDefault" datasource="#request.sdsn#">
	            	WITH CompLibHier (competence_code,parent_code)
					AS (
						SELECT A.competence_code, A.parent_code
						FROM TPMMCOMPETENCE A
						INNER JOIN TPMRJOBTITLECOMPETENCE B
							ON B.competence_code = A.competence_code
	                        <cfif len(arguments.reqno) and records>
							AND B.competence_code IN (<cfqueryparam value="#lstLibCode#" list="yes" cfsqltype="cf_sql_varchar">)
	                        <cfelse>
							AND B.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
	                        </cfif>
						UNION ALL
			
						SELECT A.competence_code, A.parent_code
						FROM TPMMCOMPETENCE A
						INNER JOIN CompLibHier B ON A.competence_code = B.parent_code
					)
					SELECT DISTINCT Z.competence_code AS libcode, Z.parent_code AS pcode, C.competence_name_#request.scookie.lang# AS libname, 
						C.competence_depth AS depth, C.iscategory, 

		                <cfif len(arguments.reqno) and records>
		                    '' maxpoint,
			                ED.target,
							ED.achievement,
							ED.score,
							ED.weight,
							ED.weightedscore,
	                        ED.reviewer_empid,
	                    <cfelse>
		                    C.maxpoint, D.point_value AS target,
							'' achievement,
	       	                '' score,
	       	                CASE WHEN PC.weight IS NOT NULL THEN PC.weight WHEN C.weight IS NOT NULL THEN C.weight ELSE '0' END weight,
					   		'0' weightedscore,
	                        '#request.scookie.user.empid#' reviewer_empid,
	                    </cfif>

						'' achscoretype,
				   		'' lookupscoretype,
				   		'N' weightedit,
				   		'N' targetedit

					FROM CompLibHier Z
	                <cfif len(arguments.reqno) and records>
	                LEFT JOIN TPMDPERFORMANCE_EVALH EH
				   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
				   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
						AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
					LEFT JOIN TPMDPERFORMANCE_EVALD ED
						ON ED.form_no = EH.form_no
						AND ED.company_code = EH.company_code
						AND ED.lib_code = Z.competence_code
						AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                    <cfif len(arguments.reviewerempid)>
	                    	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
			                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
		                    <cfelse>
			                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
		                    </cfif>
	                    </cfif>
	                    
	                </cfif>

					LEFT JOIN TPMMCOMPETENCE C
						ON C.competence_code = Z.competence_code
					LEFT JOIN TPMRJOBTITLECOMPETENCE D
						ON D.competence_code = Z.competence_code
						AND D.competence_code = C.competence_code
						AND D.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
					LEFT JOIN TPMDPERIODCOMPETENCE PC 
	                	ON PC.competence_code = C.competence_code 
	                	AND PC.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
	                	AND PC.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	                ORDER BY C.competence_depth, libname
	            </cfquery>
	            <cfelse> <!---riz--->
	            <cfquery name="Local.qGetCompDefault" datasource="#request.sdsn#">
	            	
					SELECT DISTINCT Z.competence_code AS libcode, Z.parent_code AS pcode, C.competence_name_#request.scookie.lang# AS libname, 
						C.competence_depth AS depth, C.iscategory, 

		                <cfif len(arguments.reqno) and records>
		                    '' maxpoint,
			                ED.target,
							ED.achievement,
							ED.score,
							ED.weight,
							ED.weightedscore,
	                        ED.reviewer_empid,
	                    <cfelse>
		                    C.maxpoint, D.point_value AS target,
							'' achievement,
	       	                '' score,
	       	                <cfif request.dbdriver EQ 'ORACLE'>
	       	                	CASE WHEN TO_CHAR(TO_NUMBER(PC.weight)) IS NOT NULL THEN TO_CHAR(TO_NUMBER(PC.weight)) WHEN TO_CHAR(TO_NUMBER(C.weight)) IS NOT NULL THEN TO_CHAR(TO_NUMBER(C.weight)) ELSE '0' END weight,
	       	                <cfelse>
	       	                	CASE WHEN PC.weight IS NOT NULL THEN PC.weight WHEN C.weight IS NOT NULL THEN C.weight ELSE '0' END weight,
	       	                </cfif>
					   		'0' weightedscore,
	                        '#request.scookie.user.empid#' reviewer_empid,
	                    </cfif>

						'' achscoretype,
				   		'' lookupscoretype,
				   		'N' weightedit,
				   		'N' targetedit

					FROM (
					    SELECT A.competence_code, A.parent_code
						FROM TPMMCOMPETENCE A
						INNER JOIN TPMRJOBTITLECOMPETENCE B
							ON B.competence_code = A.competence_code
	                        <cfif len(arguments.reqno) and records>
							AND B.competence_code IN (<cfqueryparam value="#lstLibCode#" list="yes" cfsqltype="cf_sql_varchar">)
	                        <cfelse>
							AND B.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
	                        </cfif>
		
						UNION ALL
			
						SELECT A.competence_code, A.parent_code
						FROM TPMMCOMPETENCE A
						INNER JOIN (
						    SELECT A.competence_code, A.parent_code
						    FROM TPMMCOMPETENCE A
						    INNER JOIN TPMRJOBTITLECOMPETENCE B
							ON B.competence_code = A.competence_code
	                        <cfif len(arguments.reqno) and records>
							AND B.competence_code IN (<cfqueryparam value="#lstLibCode#" list="yes" cfsqltype="cf_sql_varchar">)
	                        <cfelse>
							AND B.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
	                        </cfif>
						) B ON A.competence_code = B.parent_code
					) Z
	                <cfif len(arguments.reqno) and records>
	                LEFT JOIN TPMDPERFORMANCE_EVALH EH
				   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
				   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
						AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
					LEFT JOIN TPMDPERFORMANCE_EVALD ED
						ON ED.form_no = EH.form_no
						AND ED.company_code = EH.company_code
						AND ED.lib_code = Z.competence_code
						AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                    <cfif len(arguments.reviewerempid)>
	                    	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
			                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
		                    <cfelse>
			                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
		                    </cfif>
	                    </cfif>
	                    
	                </cfif>

					LEFT JOIN TPMMCOMPETENCE C
						ON C.competence_code = Z.competence_code
					LEFT JOIN TPMRJOBTITLECOMPETENCE D
						ON D.competence_code = Z.competence_code
						AND D.competence_code = C.competence_code
						AND D.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
					LEFT JOIN TPMDPERIODCOMPETENCE PC 
	                	ON PC.competence_code = C.competence_code 
	                	AND PC.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
	                	AND PC.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	                ORDER BY C.competence_depth,libname
	            </cfquery>
	            </cfif>
	          
	            
	            <cfreturn qGetCompDefault>
	        
	        <cfelseif listfindnocase("ORGKPI",ucase(compcode))>
	        	<cfquery name="local.qCekFromPlanOrEval" datasource="#request.sdsn#">
	            	SELECT lib_code FROM TPMDPERFORMANCE_EVALKPI
	            	WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	                    AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	                    AND orgunit_id = <cfqueryparam value="#qGetEmpAttr.deptid#" cfsqltype="cf_sql_integer">
	            </cfquery>
				 
				
	            <cfif len(arguments.reqno) and records>
	            
	                <cfquery name="Local.qGetOrgUnit" datasource="#request.sdsn#">
	                    SELECT DISTINCT ED.lib_name_#request.scookie.lang# AS libname, 
	                    	EVKPI.lib_desc_#request.scookie.lang# lib_desc_en,
	    			        ED.lib_code AS libcode, ED.parent_code AS pcode, ED.lib_depth AS depth, ED.iscategory,
			                ED.target,
							ED.achievement,
							ED.score,
							ED.weight,
							ED.weightedscore,
	                        ED.reviewer_empid,
	                        ED.achievement_type AS achscoretype,
	    			   		ED.lookup_code AS lookupscoretype,
	    			   		EVKPI.lib_order,
	                        <cfif not qCekFromPlanOrEval.recordcount>
	                            '0' evalkpi_status
	                        <cfelse>
	                            EVKPI.evalkpi_status
	                        </cfif>
	                    <cfif not qCekFromPlanOrEval.recordcount>
	    				FROM TPMDPERFORMANCE_PLANKPI EVKPI
	                    <cfelse>
	    				FROM TPMDPERFORMANCE_EVALKPI EVKPI
	                    </cfif>
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.lib_code = EVKPI.lib_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        <cfif len(arguments.reqno) and records>
	    					AND ED.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	                        </cfif>

	                        <cfif len(arguments.reviewerempid)>
	    	                    <cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>
	    				WHERE EVKPI.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND EVKPI.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    					AND EVKPI.orgunit_id = <cfqueryparam value="#qGetEmpAttr.deptid#" cfsqltype="cf_sql_integer">
	    				ORDER BY EVKPI.lib_order, ED.lib_depth, ED.lib_name_#request.scookie.lang#
	                </cfquery>
	                
	            <cfelse>
	            
	    	        <cfquery name="Local.qGetOrgUnit" datasource="#request.sdsn#">
	    				SELECT distinct EVKPI.lib_code AS libcode, EVKPI.parent_code AS pcode, EVKPI.lib_name_#request.scookie.lang# AS libname, 
	    				EVKPI.lib_desc_#request.scookie.lang# lib_desc_en,
	    					EVKPI.lib_depth AS depth, EVKPI.iscategory,  
	    					<cfif len(arguments.reqno) and records>
	    		                ED.target,
	    						ED.achievement,
	    						ED.score,
	    						Round(ED.weight,#REQUEST.InitVarCountDeC#) weight,
	    						Round(ED.weightedscore,#REQUEST.InitVarCountDeC#) weightedscore,
	                            ED.reviewer_empid,
	                        <cfelseif not qCekFromPlanOrEval.recordcount>
	    		                EVKPI.target,
	                            '' achievement,
	    		                '0' score,
	    		                Round(EVKPI.weight,#REQUEST.InitVarCountDeC#) weight,
	    		                '0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                        <cfelse>
	    		                EVKPI.target,
	                            EVKPI.achievement,
	    		                EVKPI.score,
	    		                Round(EVKPI.weight,#REQUEST.InitVarCountDeC#) weight,
	    		                '0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                        </cfif>
	    
	    					<!---EVKPI.achievement_type AS achscoretype, --->
							<cfif not qCekFromPlanOrEval.recordcount>
							CASE WHEN EVKPI.isnew = 'Y' THEN EVKPI.achievement_type 
								WHEN EVKPI.isnew = 'N' THEN LIB.achievement_type 
								END achscoretype,
							<cfelse>
							CASE 
									WHEN EVKPI.achievement_type IS NOT NULL AND <cfif request.dbdriver eq "MSSQL">LEN(EVKPI.achievement_type)<cfelse>LENGTH(EVKPI.achievement_type)</cfif> <> 0 THEN EVKPI.achievement_type
									WHEN PK.achievement_type IS NOT NULL THEN PK.achievement_type
									ELSE LIB.achievement_type
								END achscoretype,
							</cfif>
	                        CASE
	                        	WHEN EVKPI.lookup_code IS NOT NULL THEN EVKPI.lookup_code <!--- TCK1507-002557 --->
	                        	WHEN PK.lookup_code IS NOT NULL THEN PK.lookup_code
	                        	ELSE ''
	                        END lookupscoretype,
	                        
	    			   		'N' weightedit,
	    			   		'N' targetedit,
	    			   		
	    			   		EVKPI.lib_order,
	                        
	                    <cfif not qCekFromPlanOrEval.recordcount>
	                        '0' evalkpi_status
	                    <cfelse>
	                        EVKPI.evalkpi_status
	                    </cfif>
	    
	                    <cfif not qCekFromPlanOrEval.recordcount>
	    				FROM TPMDPERFORMANCE_PLANKPI EVKPI
	                    <cfelse>
	    				FROM TPMDPERFORMANCE_EVALKPI EVKPI
	                    </cfif>
	                    
	                    <cfif len(arguments.reqno) and records>
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.lib_code = EVKPI.lib_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        
	                        <cfif len(arguments.reqno) and records>
	    					AND ED.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	                        </cfif>
	                        
	                        <cfif len(arguments.reviewerempid)>
	                        	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>
	                    </cfif>
	                    
	                    LEFT JOIN TPMDPERIODKPI PK
	    					ON PK.period_code = EVKPI.period_code 
	    					AND PK.reference_date = EVKPI.reference_date 
	    					AND PK.company_code = EVKPI.company_code
	    					AND PK.position_id = EVKPI.orgunit_id
	    					AND PK.kpilib_code = EVKPI.lib_code
	    					AND PK.kpi_type = 'ORGUNIT'
	    				LEFT JOIN TPMDPERIODKPILIB LIB
	    					ON LIB.period_code = EVKPI.period_code
	    					AND LIB.company_code = EVKPI.company_code
	    					AND LIB.kpilib_code = EVKPI.lib_code
	    					AND LIB.reference_date = EVKPI.reference_date
	    
	    				WHERE EVKPI.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND EVKPI.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    					AND EVKPI.orgunit_id = <cfqueryparam value="#qGetEmpAttr.deptid#" cfsqltype="cf_sql_integer">						
	                    ORDER BY EVKPI.lib_order, EVKPI.lib_depth, EVKPI.lib_name_#request.scookie.lang#
	    	        </cfquery>
					
	    	        <cfif not qGetOrgUnit.recordcount>
	    		        <cfquery name="Local.qGetOrgUnit" datasource="#request.sdsn#">
	    		        	SELECT PLKPI.lib_code AS libcode, PLKPI.lib_order,PLKPI.parent_code AS pcode, PLKPI.lib_name_#request.scookie.lang# AS libname, PLKPI.lib_desc_en, 
	    						PLKPI.lib_depth AS depth, PLKPI.iscategory, 
	    						PLKPI.achievement_type AS achscoretype, PLKPI.weight, PLKPI.target, PLKPI.isnew, '' evalkpi_status,
	                            '' achievement, 
	                            PLKPI.lookup_code lookupscoretype, <!--- TCK1507-002557 --->
	                            '' score, '0' weightedscore
	    					FROM TPMDPERFORMANCE_PLANKPI PLKPI
	    					INNER JOIN TCLTREQUEST R 
	    						ON R.req_no = PLKPI.request_no
	    						AND R.req_type = 'PERFORMANCE.PLAN'
	    						AND R.company_code = PLKPI.company_code
	    						AND R.status IN (3,9)
	    					WHERE PLKPI.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						AND PLKPI.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    						AND PLKPI.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND PLKPI.orgunit_id = <cfqueryparam value="#qGetEmpAttr.deptid#" cfsqltype="cf_sql_integer">
	    		               
								<!---start : ENC50915-79511--->
								AND PLKPI.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
								<!---end : ENC50915-79511--->
	    	                ORDER BY PLKPI.lib_order, PLKPI.lib_depth, PLKPI.lib_name_#request.scookie.lang#
	    		        </cfquery>
						
	    	        </cfif>
		        
		        </cfif>
		        
			    <cfreturn qGetOrgUnit>
	            
	        <cfelseif listfindnocase("PERSKPI",ucase(compcode))>

	        	<!--- cek kalo ada di PLAND --->
	            <cfquery name="Local.qGetFromPlan" datasource="#request.sdsn#">
	            	SELECT DISTINCT form_no, reviewer_empid, request_no,created_date FROM TPMDPERFORMANCE_PLANH
	                WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	   	            	AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	           	        AND reviewee_empid = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
	               	    AND isfinal = 1
	               	    AND head_status = 1
	               	order by created_date desc
	       	            <!--- AND reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp"> --->
	            </cfquery>
	            
	            <!--- <cfquery name="Local.qCekLib" datasource="#request.sdsn#">
	            	SELECT * FROM TPMDPERFORMANCE_PLAND
	                WHERE form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                	AND reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
	            </cfquery> ---->
	            
	            <cfquery name="Local.qGetNewLib" datasource="#request.sdsn#">
	            	SELECT DISTINCT lib_code FROM TPMDPERFORMANCE_PLAND
	                WHERE form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                	AND reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
	                    AND isnew = 'Y'
	            </cfquery>
	           
	            <cfset Local.lstNewLibCode = valuelist(qGetNewLib.lib_code)>
	            
	            <cfif (len(arguments.reqno) and records)> <!---OR (not qCekLib.recordcount) BUG50915-51061--->
	          
	            	<cfquery name="Local.qGetKPIDefault" datasource="#request.sdsn#">
	            	    SELECT * from (
	            	    SELECT DISTINCT ED.lib_name_#request.scookie.lang# AS libname,AP.kpi_desc_#request.scookie.lang# AS lib_desc_en,
	    			        ED.lib_code AS libcode, ED.parent_code AS pcode, ED.lib_depth AS depth, ED.iscategory,
			                ED.target,
							ED.achievement,
							ED.score,
							ED.weight,
							ED.weightedscore,
	                        ED.reviewer_empid,
	                        ED.achievement_type AS achscoretype,
	                            <cfif qGetFromPlan.recordcount>
	                            PLD.lib_order,
	                            <cfelse>
	                            '0' lib_order,
	                            </cfif>
	    			   		ED.lookup_code AS lookupscoretype
	                        <!---
	    			   		, PA.editable_weight AS weightedit
	    			   		, PA.editable_target AS targetedit
	    			   		--->
	                    FROM TPMDPERFORMANCE_EVALH EH
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	    			    LEFT JOIN TPMDPERIODKPILIB AP 
		                    ON ED.lib_code = AP.kpilib_code AND EH.period_code=AP.period_code 
		                    AND ED.company_code =  AP.company_code
	                    <cfif qGetFromPlan.recordcount>
	    	            LEFT JOIN TPMDPERFORMANCE_PLAND PLD
	                        ON PLD.lib_code = ED.lib_code
	                        AND PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                        AND PLD.reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
							AND PLD.request_no = <cfqueryparam value="#qGetFromPlan.request_no#" cfsqltype="cf_sql_varchar">
	                    </cfif>

	                    WHERE 
	                        <cfif len(arguments.reviewerempid)>
	    	                    <cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                     ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                     ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>

	                        AND EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND EH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				) tblperskpi
	    				ORDER BY tblperskpi.lib_order, tblperskpi.depth, tblperskpi.libname
	            	</cfquery>
	            	
	            <cfelse>
	                
					
					
					<cfquery name="Local.qGetKPIDefault" datasource="#request.sdsn#">
	            	   SELECT * from (
	            	    SELECT DISTINCT PLD.lib_name_en AS libname, 
	    			        PLD.lib_code AS libcode, PLD.parent_code AS pcode, PLD.lib_depth AS depth, PLD.iscategory,
			                PLD.target,
							'' achievement,
							'' score,
							PLD.weight,
							'' weightedscore,
	                        '' reviewer_empid,
	                        PLD.achievement_type AS achscoretype,
	                            PLD.lib_order,
	    			   		PLD.lookup_code AS lookupscoretype,
	    			   		AP.kpi_desc_#request.scookie.lang# AS lib_desc_en
	                       
	                    FROM TPMDPERFORMANCE_PLANH PLANH
	    				  LEFT JOIN TPMDPERFORMANCE_PLAND PLD
	    				  
	                        ON (PLD.lib_code = PLD.lib_code
							 <cfif qGetFromPlan.recordcount> 
							 AND PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
							 AND PLD.request_no = <cfqueryparam value="#qGetFromPlan.request_no#" cfsqltype="cf_sql_varchar">
							 AND PLD.reviewer_empid  = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
							 <cfelse>
							AND 1 = 0
							 </cfif>
	                        )
	                        LEFT JOIN TPMDPERIODKPILIB AP 
		                    ON PLD.lib_code = AP.kpilib_code AND PLANH.period_code=AP.period_code 
		                    AND PLD.company_code =  AP.company_code
	                        WHERE PLANH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND PLANH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
							<cfif qGetFromPlan.recordcount> 
								AND PLANH.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
								AND PLANH.request_no = <cfqueryparam value="#qGetFromPlan.request_no#" cfsqltype="cf_sql_varchar">
								AND PLANH.REVIEWER_EMPID = <cfqueryparam value="#qGetFromPlan.REVIEWER_EMPID#" cfsqltype="cf_sql_varchar">
							<cfelse>
								AND 1 = 0
							</cfif>
							
							
	    				) tblperskpi
	    				ORDER BY tblperskpi.lib_order, tblperskpi.depth, tblperskpi.libname
	    				
	    				
	            	</cfquery>
					
					<!---<cf_sfwritelog dump="arguments.lastreviewer,arguments.reviewerempid,qGetFromPlan.REVIEWER_EMPID" prefix="qGetKPIDefault_"> ---->
					
					<!-----
					
					<cfif request.dbdriver eq "MSSQL">
						  
	            	<cfquery name="Local.qGetKPIDefault" datasource="#request.sdsn#">
	                	WITH KPILibHier (kpilib_code,parent_code,kpi_name, depth, iscategory)
	    				AS (
	    					SELECT K.kpilib_code, K.parent_code, K.kpi_name_#request.scookie.lang#, K.kpi_depth, K.iscategory
	    					FROM TPMDPERIODKPILIB K
	    					INNER JOIN TPMDPERIODKPI PK
	    						ON PK.period_code = K.period_code
	    						AND PK.company_code =K.company_code
	    						AND PK.reference_date = K.reference_date
	    						AND PK.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    						AND PK.kpilib_code = K.kpilib_code
	    					WHERE PK.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						AND PK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND PK.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	                            <cfif ucase(compcode) eq "PERSKPI">
	    	                        AND PK.kpi_type = 'PERSONAL'
	                            <cfelse>
	    	                        AND PK.kpi_type = 'ORGUNIT'
	                            </cfif>
	    	
	    					UNION ALL
	    		
	    					SELECT A.kpilib_code, A.parent_code, A.kpi_name_#request.scookie.lang#, A.kpi_depth, A.iscategory
	    					FROM TPMDPERIODKPILIB A
	    					INNER JOIN KPILibHier AS B ON A.kpilib_code = B.parent_code
	    					<!--- pake yg category juga --->
	    					<!---
	    					WHERE A.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						AND A.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND A.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    				
	    		--->
	    				)	
	    
	                    <cfif qGetNewLib.recordcount>
	                    SELECT * FROM (
	                    </cfif>
	                    
	    				SELECT DISTINCT Z.kpi_name AS libname,z.lib_desc_en, Z.kpilib_code AS libcode, Z.parent_code AS pcode, Z.depth, Z.iscategory,
	    	                <cfif len(arguments.reqno) and records>
	    		                ED.target,
	    						ED.achievement,
	    						ED.score,
	    						ED.weight,
	    						ED.weightedscore,
	                            ED.reviewer_empid,
	                            <cfif qGetFromPlan.recordcount>
	                            PLD.lib_order,
	                            <cfelse>
	                            '0' lib_order,
	                            </cfif>
	    	                <cfelseif qGetFromPlan.recordcount>
	                        	PLD.target,
	                            '' achievement,
	           	                '' score,
	                            PLD.weight,
	                            '0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            PLD.lib_order,
	                        <cfelse>
	    						PK.target,
	    						'' achievement,
	           	                '' score,
	    						CASE 
	                            	<!---
	    							WHEN PK.weight IS NOT NULL AND PK.weight <> 0 THEN PK.weight 
	    							WHEN PK.weight = 0 AND KPI.weight IS NOT NULL AND KPI.weight <> 0 THEN KPI.weight
	    							ELSE PK.weight 
	    							--->
	    							WHEN PK.weight IS NOT NULL THEN PK.weight 
	    							WHEN KPI.weight IS NOT NULL THEN KPI.weight
	    							ELSE '0'
	    						END weight,
	    				   		'0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            '0' lib_order,
	                        </cfif>
	    			   		CASE 
	    			   			WHEN PK.achievement_type IS NOT NULL THEN PK.achievement_type
	    			   			ELSE KPI.achievement_type
	    			   		END achscoretype,
	    			
	    			   		PK.lookup_code AS lookupscoretype,
	    			   		PK.editable_weight AS weightedit,
	    			   		PK.editable_target AS targetedit
	       		
	    			   	FROM KPILibHier Z
	                    
	                    <cfif len(arguments.reqno) and records>
	                    LEFT JOIN TPMDPERFORMANCE_EVALH EH
	    			   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND ED.lib_code = Z.kpilib_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        <cfif len(arguments.reviewerempid)>
	                        	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>
	                    </cfif>
	                    
	                    <!--- dipisah, biar yang isnew juga keambil --->
	                    <cfif qGetFromPlan.recordcount>
	    	            LEFT JOIN TPMDPERFORMANCE_PLAND PLD
	                        ON PLD.lib_code = Z.kpilib_code
	                        AND PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                        AND PLD.reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
							AND PLD.request_no in (select request_no from TPMDPERFORMANCE_PLANH where isfinal=1 and form_no = PLD.form_no) <!---added by ENC50915-79511--->
	                    </cfif>
	    
	    			   	LEFT JOIN TPMDPERIODKPILIB KPI
	    			   		ON KPI.kpilib_code = Z.kpilib_code
	    			   		AND KPI.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND KPI.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    					AND KPI.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    				LEFT JOIN TPMDPERIODKPI PK
	    					ON PK.period_code = KPI.period_code
	    					AND PK.company_code =KPI.company_code
	    					AND PK.reference_date = KPI.reference_date
	    					AND PK.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    					AND PK.kpilib_code = KPI.kpilib_code
	                        <cfif ucase(compcode) eq "PERSKPI">
	    	                    AND PK.kpi_type = 'PERSONAL'
	                        <cfelse>
	    	                    AND PK.kpi_type = 'ORGUNIT'
	                        </cfif>
	                        
	                    <cfif not qGetNewLib.recordcount>
	    					ORDER BY Z.depth, Z.kpi_name
	                    </cfif>
	                    
	                    <cfif qGetNewLib.recordcount>
	                    UNION
	                    
	                    SELECT PLD.lib_name_en AS libname,AP.kpi_desc_#request.scookie.lang# AS lib_desc_en, PLD.lib_code AS libcode, PLD.parent_code AS pcode, PLD.lib_depth AS depth, PLD.iscategory,
	    	                <cfif len(arguments.reqno) and records>
	    						ED.target,
	    						ED.achievement,
	    						ED.score,
	    						ED.weight,
	    						ED.weightedscore,
	                            ED.reviewer_empid,
	                            PLD.lib_order,
	                    	<cfelse>
	    						PLD.target,
	    						'' achievement,
	    						'' score,
	    						PLD.weight,
	    						'0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            PLD.lib_order,
	                        </cfif>
	                            PLD.achievement_type achscoretype,
	                            PLD.lookup_code AS lookupscoretype, <!--- TCK1507-002557 --->
	                            <!---
	                            '' lookupscoretype,
	                            --->

	                            'N' weightedit,
	                            'N' targetedit
	                            
	                    FROM TPMDPERFORMANCE_PLAND PLD  
	                    
	    				<!---lstNewLibCode--->
	                    <cfif len(arguments.reqno) and records>
	                    LEFT JOIN TPMDPERFORMANCE_EVALH EH
	    			   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND ED.lib_code = PLD.lib_code
	    					
	    			    LEFT JOIN TPMDPERIODKPILIB AP 
		                    ON ED.lib_code = AP.kpilib_code AND EH.period_code=AP.period_code 
		                    AND ED.company_code =  AP.company_code	
	                    </cfif>
	                    
	                    WHERE 
	                        upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        <cfif len(arguments.reviewerempid)>
	                        	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif> AND
	                        PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                    	AND PLD.reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
	                        AND PLD.isnew = 'Y'
							AND PLD.request_no in (select request_no from TPMDPERFORMANCE_PLANH where isfinal=1 and form_no = PLD.form_no) <!---added by ENC50915-79511--->
	                    </cfif>
	                    
	                    <cfif qGetNewLib.recordcount>
	                    ) tblperskpi
	                    ORDER BY tblperskpi.lib_order, tblperskpi.depth, tblperskpi.libname
	                    </cfif>
	                </cfquery>
						
	                <cfelse> <!---riz--->
	                    <cfquery name="Local.qGetKPIDefault" datasource="#request.sdsn#">
	    
	                    <cfif qGetNewLib.recordcount>
	                    SELECT * FROM (
	                    </cfif>
	                    
	    				SELECT DISTINCT Z.kpi_name AS libname,Z.lib_desc_en, Z.kpilib_code AS libcode, Z.parent_code AS pcode, Z.depth, Z.iscategory,
	    	                <cfif len(arguments.reqno) and records>
	    		                ED.target,
	    						ED.achievement,
	    						ED.score,
	    						ED.weight,
	    						ED.weightedscore,
	                            ED.reviewer_empid,
	                            <cfif qGetFromPlan.recordcount>
	                            PLD.lib_order,
	                            <cfelse>
	                            '0' lib_order,
	                            </cfif>
	    	                <cfelseif qGetFromPlan.recordcount>
	                        	PLD.target,
	                            '' achievement,
	           	                '' score,
	                            PLD.weight,
	                            '0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            PLD.lib_order,
	                        <cfelse>
	    						PK.target,
	    						'' achievement,
	           	                '' score,
	    						CASE 
	                            	<!---
	    							WHEN PK.weight IS NOT NULL AND PK.weight <> 0 THEN PK.weight 
	    							WHEN PK.weight = 0 AND KPI.weight IS NOT NULL AND KPI.weight <> 0 THEN KPI.weight
	    							ELSE PK.weight 
	    							--->
	    							WHEN PK.weight IS NOT NULL THEN PK.weight 
	    							WHEN KPI.weight IS NOT NULL THEN KPI.weight
	    							ELSE '0'
	    						END weight,
	    				   		'0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            '0' lib_order,
	                        </cfif>
	    			   		CASE 
	    			   			WHEN PK.achievement_type IS NOT NULL THEN PK.achievement_type
	    			   			ELSE KPI.achievement_type
	    			   		END achscoretype,
	    			
	    			   		PK.lookup_code AS lookupscoretype,
	    			   		PK.editable_weight AS weightedit,
	    			   		PK.editable_target AS targetedit
	       		
	    			   	FROM 
	    			   	(
	    					SELECT K.kpilib_code, K.parent_code,K.kpi_desc_#request.scookie.lang# AS lib_desc_en, K.kpi_name_#request.scookie.lang# kpi_name, K.kpi_depth depth, K.iscategory
	    					FROM TPMDPERIODKPILIB K
	    					INNER JOIN TPMDPERIODKPI PK
	    						ON PK.period_code = K.period_code
	    						AND PK.company_code =K.company_code
	    						AND PK.reference_date = K.reference_date
	    						AND PK.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    						AND PK.kpilib_code = K.kpilib_code
	    					WHERE PK.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						AND PK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND PK.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	                            <cfif ucase(compcode) eq "PERSKPI">
	    	                        AND PK.kpi_type = 'PERSONAL'
	                            <cfelse>
	    	                        AND PK.kpi_type = 'ORGUNIT'
	                            </cfif>
	    	
	    					UNION ALL
	    		
	    					SELECT A.kpilib_code, A.parent_code,K.kpi_desc_#request.scookie.lang# AS lib_desc_en,A.kpi_name_#request.scookie.lang#, A.kpi_depth, A.iscategory
	    					FROM TPMDPERIODKPILIB A
	    					INNER JOIN (
	    					    SELECT K.kpilib_code, K.parent_code, K.kpi_name_#request.scookie.lang#, K.kpi_depth, K.iscategory
	        					FROM TPMDPERIODKPILIB K
	        					INNER JOIN TPMDPERIODKPI PK
	        						ON PK.period_code = K.period_code
	        						AND PK.company_code =K.company_code
	        						AND PK.reference_date = K.reference_date
	        						AND PK.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	        						AND PK.kpilib_code = K.kpilib_code
	        					WHERE PK.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	        						AND PK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	        						AND PK.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	                                <cfif ucase(compcode) eq "PERSKPI">
	        	                        AND PK.kpi_type = 'PERSONAL'
	                                <cfelse>
	        	                        AND PK.kpi_type = 'ORGUNIT'
	                                </cfif>
	    					) AS B ON A.kpilib_code = B.parent_code
	    					
	    		
	    				) Z
	                    
	                    <cfif len(arguments.reqno) and records>
	                    LEFT JOIN TPMDPERFORMANCE_EVALH EH
	    			   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND ED.lib_code = Z.kpilib_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        <cfif len(arguments.reviewerempid)>
	                        	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>
	                    </cfif>
	                    
	                    <!--- dipisah, biar yang isnew juga keambil --->
	                    <cfif qGetFromPlan.recordcount>
	    	            LEFT JOIN TPMDPERFORMANCE_PLAND PLD
	                        ON PLD.lib_code = Z.kpilib_code
	                        AND PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                        AND PLD.reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
							AND PLD.request_no in (select request_no from TPMDPERFORMANCE_PLANH where isfinal=1 and form_no = PLD.form_no) <!---added by ENC50915-79511--->
	                    </cfif>
	    
	    			   	LEFT JOIN TPMDPERIODKPILIB KPI
	    			   		ON KPI.kpilib_code = Z.kpilib_code
	    			   		AND KPI.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND KPI.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    					AND KPI.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    				LEFT JOIN TPMDPERIODKPI PK
	    					ON PK.period_code = KPI.period_code
	    					AND PK.company_code =KPI.company_code
	    					AND PK.reference_date = KPI.reference_date
	    					AND PK.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    					AND PK.kpilib_code = KPI.kpilib_code
	                        <cfif ucase(compcode) eq "PERSKPI">
	    	                    AND PK.kpi_type = 'PERSONAL'
	                        <cfelse>
	    	                    AND PK.kpi_type = 'ORGUNIT'
	                        </cfif>
	                        
	                    <cfif not qGetNewLib.recordcount>
	    					ORDER BY Z.depth, Z.kpi_name
	                    </cfif>
	                    
	                    <cfif qGetNewLib.recordcount>
	                    UNION
	                    
	                    SELECT PLD.lib_name_en AS libname, PLD.lib_code AS libcode, PLD.parent_code AS pcode, PLD.lib_depth AS depth, PLD.iscategory,
	    	                <cfif len(arguments.reqno) and records>
	    						ED.target,
	    						ED.achievement,
	    						ED.score,
	    						ED.weight,
	    						ED.weightedscore,
	                            ED.reviewer_empid,
	                            PLD.lib_order,
	                    	<cfelse>
	    						PLD.target,
	    						'' achievement,
	    						'' score,
	    						PLD.weight,
	    						'0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            PLD.lib_order,
	                        </cfif>
	                            
	                            PLD.achievement_type achscoretype,
	                            PLD.lookup_code AS lookupscoretype, <!--- TCK1507-002557 --->
	                            <!---
	                            '' lookupscoretype,
	                            --->

	                            'N' weightedit,
	                            'N' targetedit
	                            
	                    FROM TPMDPERFORMANCE_PLAND PLD  
	                    
	    				<!---lstNewLibCode--->
	                    <cfif len(arguments.reqno) and records>
	                    LEFT JOIN TPMDPERFORMANCE_EVALH EH
	    			   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND ED.lib_code = PLD.lib_code
	    			  	 LEFT JOIN TPMDPERIODKPIRLIB AP 
		                 ON ED.lib_code = AP.kpilib_code AND EH.period_code=AP.period_code 
		                 AND ED.company_code =  AP.company_code
	                    WHERE 
	                       upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        <cfif len(arguments.reviewerempid)>
	                        	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>
	                    </cfif>
	                        PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                    	AND PLD.reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
	                        AND PLD.isnew = 'Y'
							AND PLD.request_no in (select request_no from TPMDPERFORMANCE_PLANH where isfinal=1 and form_no = PLD.form_no) <!---added by ENC50915-79511--->
	                    </cfif>
	                    
	                    <cfif qGetNewLib.recordcount>
	                    ) tblperskpi
	                    ORDER BY tblperskpi.lib_order, tblperskpi.depth, tblperskpi.libname
	                    </cfif>
	                </cfquery>
	                </cfif> <!---riz--->
					
					---->
	                
	            </cfif>
	         
			    <cfreturn qGetKPIDefault>
			    
	        <cfelseif ucase(compcode) eq "APPRAISAL">
	            <cfif len(arguments.reqno) and records>
	    			<cfquery name="local.qGetApprDefault" datasource="#request.sdsn#">
	    			    SELECT DISTINCT ED.lib_name_#request.scookie.lang# AS libname, AP.appraisal_desc_#request.scookie.lang# as description,
	    			        ED.lib_code AS libcode, ED.parent_code AS pcode, ED.lib_depth AS depth, ED.iscategory,
			                ED.target,
							ED.achievement,
							ED.score,
							ED.weight,
							ED.weightedscore,
	                        ED.reviewer_empid,
	                        ED.achievement_type AS achscoretype,
	    			   		ED.lookup_code AS lookupscoretype,
							AP.order_no
	                        <!---
	    			   		, PA.editable_weight AS weightedit
	    			   		, PA.editable_target AS targetedit
	    			   		--->
	                    FROM TPMDPERFORMANCE_EVALH EH
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    			    LEFT JOIN TPMDPERIODAPPRLIB AP 
		                ON ED.lib_code = AP.apprlib_code AND EH.period_code=AP.period_code 
		                AND ED.company_code =  AP.company_code
	
	    					
	                    WHERE EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND EH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
							<cfif varcocode eq request.scookie.cocode>
								<cfif len(arguments.reviewerempid)>
									<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
										AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
									<cfelse>
										AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
									</cfif>
								</cfif>
							</cfif>
	    		  	ORDER BY ED.lib_depth, AP.order_no, ED.lib_name_#request.scookie.lang#
	    			</cfquery>
	    	
	            <cfelse>
	                <cfif request.dbdriver eq "MSSQL">
	                <cfquery name="Local.qGetApprDefault" datasource="#request.sdsn#">
	    	           	WITH ApprLibHier (apprlib_code,parent_code,order_no,appraisal_name,description,depth, iscategory)
	    				AS (
	    					SELECT A.apprlib_code, A.parent_code,A.order_no, A.appraisal_name_#request.scookie.lang#,  A.appraisal_desc_#request.scookie.lang#,A.appraisal_depth, A.iscategory
	    					FROM TPMDPERIODAPPRLIB A
	    					INNER JOIN TPMDPERIODAPPRAISAL PA
	    						ON PA.period_code = A.period_code
	    						AND PA.company_code =A.company_code
	    						AND PA.reference_date = A.reference_date
	    						AND PA.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    						AND PA.apprlib_code = A.apprlib_code
	    					WHERE PA.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						AND PA.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND PA.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    		
	    					UNION ALL
	    					SELECT A.apprlib_code, A.parent_code, A.order_no,A.appraisal_name_#request.scookie.lang#, 
	    					A.appraisal_desc_#request.scookie.lang#,A.appraisal_depth, A.iscategory
	    					FROM TPMDPERIODAPPRLIB A
	    					INNER JOIN ApprLibHier B ON A.apprlib_code = B.parent_code
	    					WHERE A.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						AND A.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND A.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    				)

	    				SELECT DISTINCT Z.appraisal_name AS libname, z.description,Z.apprlib_code AS libcode, Z.order_no, Z.parent_code AS pcode, Z.depth, Z.iscategory,
	    	                <cfif len(arguments.reqno) and records>
	    		                ED.target,
	    						ED.achievement,
	    						ED.score,
	    						ED.weight,
	    						ED.weightedscore,
	                            ED.reviewer_empid,
	                        <cfelse>
	    						PA.target,
	    						'' achievement,
	           	                '' score,
	    						CASE 
	                            	<!---
	    							WHEN PA.weight IS NOT NULL AND PA.weight <> 0 THEN PA.weight 
	    							WHEN PA.weight = 0 AND APPR.weight IS NOT NULL AND APPR.weight <> 0 THEN APPR.weight
	    							ELSE PA.weight
	    							--->
	    							WHEN PA.weight IS NOT NULL THEN PA.weight 
	    							WHEN APPR.weight IS NOT NULL THEN APPR.weight
	    							ELSE '0'
	    						END weight,
	    				   		'0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                        </cfif>
	    			   		CASE 
	    			   			WHEN PA.achievement_type IS NOT NULL THEN PA.achievement_type
	    			   			ELSE APPR.achievement_type
	    		   			END achscoretype,
	    			   		PA.lookup_code AS lookupscoretype,
	    
	    			   		PA.editable_weight AS weightedit,
	    			   		PA.editable_target AS targetedit

	    			   	FROM ApprLibHier Z
	                    <cfif len(arguments.reqno) and records>
	                    LEFT JOIN TPMDPERFORMANCE_EVALH EH
	    			   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND ED.lib_code = Z.apprlib_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
							<cfif varcocode eq request.scookie.cocode>
								<cfif len(arguments.reviewerempid)>
									<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
										AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
									<cfelse>
										AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
									</cfif>
								</cfif>
							</cfif>
	                    </cfif>
	            
	    			   	LEFT JOIN TPMDPERIODAPPRLIB APPR
	    			   		ON APPR.apprlib_code = Z.apprlib_code
	                   	    AND APPR.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND APPR.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    					AND APPR.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    				LEFT JOIN TPMDPERIODAPPRAISAL PA
	    					ON PA.period_code = APPR.period_code
	    					AND PA.company_code =APPR.company_code
	    					AND PA.reference_date = APPR.reference_date
	    					AND PA.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    					AND PA.apprlib_code = APPR.apprlib_code
	    				
						ORDER BY Z.depth, Z.order_no, Z.appraisal_name
	    			</cfquery>
	    			<cfelse> <!---riz--->
						<cfquery name="Local.qGetApprDefault" datasource="#request.sdsn#">
							SELECT DISTINCT Z.appraisal_name AS libname, z.description,Z.apprlib_code AS libcode, Z.order_no,Z.parent_code AS pcode, Z.depth, Z.iscategory,
								<cfif len(arguments.reqno) and records>
									ED.target,
									ED.achievement,
									ED.score,
									ED.weight,
									ED.weightedscore,
									ED.reviewer_empid,
								<cfelse>
									PA.target,
									'' achievement,
									'' score,
									<cfif request.dbdriver eq 'ORACLE'>
										CASE 
											WHEN PA.weight IS NOT NULL THEN PA.weight
											WHEN APPR.weight IS NOT NULL THEN APPR.weight
											ELSE 0
										END weight,
									<cfelse>
										CASE 
											<!---
											WHEN PA.weight IS NOT NULL AND PA.weight <> 0 THEN PA.weight 
											WHEN PA.weight = 0 AND APPR.weight IS NOT NULL AND APPR.weight <> 0 THEN APPR.weight
											ELSE PA.weight
											--->
											WHEN PA.weight IS NOT NULL THEN PA.weight 
											WHEN APPR.weight IS NOT NULL THEN APPR.weight
											ELSE '0'
										END weight,
									</cfif>
									'0' weightedscore,
									'#request.scookie.user.empid#' reviewer_empid,
								</cfif>
								CASE 
									WHEN PA.achievement_type IS NOT NULL THEN PA.achievement_type
									ELSE APPR.achievement_type
								END achscoretype,
								PA.lookup_code AS lookupscoretype,
			
								PA.editable_weight AS weightedit,
								PA.editable_target AS targetedit

							FROM 
							(
								SELECT A.apprlib_code, A.parent_code, A.order_no, A.appraisal_name_#request.scookie.lang# appraisal_name,
								A.appraisal_desc_#request.scookie.lang# description,A.appraisal_depth depth, A.iscategory
								FROM TPMDPERIODAPPRLIB A
								INNER JOIN TPMDPERIODAPPRAISAL PA
									ON PA.period_code = A.period_code
									AND PA.company_code =A.company_code
									AND PA.reference_date = A.reference_date
									AND PA.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
									AND PA.apprlib_code = A.apprlib_code
								WHERE PA.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
									AND PA.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
									AND PA.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
					
								UNION ALL
					
								SELECT A.apprlib_code, A.parent_code, A.order_no, A.appraisal_name_#request.scookie.lang# ,
								A.appraisal_desc_#request.scookie.lang#,A.appraisal_depth, A.iscategory
								FROM TPMDPERIODAPPRLIB A
								INNER JOIN (
									SELECT A.apprlib_code, A.parent_code, A.appraisal_name_#request.scookie.lang#,  A.appraisal_desc_#request.scookie.lang#,A.appraisal_depth, A.iscategory
									FROM TPMDPERIODAPPRLIB A
									INNER JOIN TPMDPERIODAPPRAISAL PA
										ON PA.period_code = A.period_code
										AND PA.company_code =A.company_code
										AND PA.reference_date = A.reference_date
										AND PA.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
										AND PA.apprlib_code = A.apprlib_code
									WHERE PA.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
										AND PA.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
										AND PA.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
								) B ON A.apprlib_code = B.parent_code
								WHERE A.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
									AND A.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
									AND A.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
							) Z
							<cfif len(arguments.reqno) and records>
							LEFT JOIN TPMDPERFORMANCE_EVALH EH
								ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
								AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
								AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
							LEFT JOIN TPMDPERFORMANCE_EVALD ED
								ON ED.form_no = EH.form_no
								AND ED.company_code = EH.company_code
								AND ED.lib_code = Z.apprlib_code
								AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
								<cfif varcocode eq request.scookie.cocode>
									<cfif len(arguments.reviewerempid)>
										<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
											AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
										<cfelse>
											AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
										</cfif>
									</cfif>
								</cfif>
							</cfif>
					
							LEFT JOIN TPMDPERIODAPPRLIB APPR
								ON APPR.apprlib_code = Z.apprlib_code
								AND APPR.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
								AND APPR.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
								AND APPR.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
							LEFT JOIN TPMDPERIODAPPRAISAL PA
								ON PA.period_code = APPR.period_code
								AND PA.company_code =APPR.company_code
								AND PA.reference_date = APPR.reference_date
								AND PA.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
								AND PA.apprlib_code = APPR.apprlib_code
							ORDER BY   Z.depth, Z.order_no, Z.appraisal_name
						</cfquery>
	
	    			</cfif> <!---riz--->
	    			
	            </cfif>
				 
				<!---- start -lena- : reorder library per parent and child ---->
				<cfquery name="LOCAL.qGetCategoryFormData" dbtype="query">
					SELECT * FROM qGetApprDefault where pcode = 0 OR iscategory = 'Y' order by depth, <cfif isDefined('qGetApprDefault.order_no')>order_no,</cfif>  libname
				</cfquery>
				<cfif qGetCategoryFormData.recordcount gt 0>
					<cfset local.clDataNew = qGetApprDefault.ColumnList >
					<cfset LOCAL.qEmpFormDataNew = queryNew(clDataNew)> 
					<cfloop query="#qGetCategoryFormData#">
						<cfset LOCAL.temp = QueryAddRow(qEmpFormDataNew)>
						<cfloop list="#clDataNew#" index="idxColName">
							<cfset temp = QuerySetCell(qEmpFormDataNew,idxColName,evaluate("qGetCategoryFormData.#idxColName#"))/>
						</cfloop>
						<cfquery name="LOCAL.qGetSubFormData" dbtype="query">
							SELECT * FROM qGetApprDefault where pcode = '#qGetCategoryFormData.libcode#' and (iscategory = 'N' OR iscategory is null OR iscategory = '')
							order by depth, <cfif isDefined('qGetApprDefault.order_no')>order_no,</cfif> libname
						</cfquery>
						<cfif qGetSubFormData.recordcount gt 0>
							<cfloop query="#qGetSubFormData#">
								<cfset LOCAL.temp = QueryAddRow(qEmpFormDataNew)>
								<cfloop list="#clDataNew#" index="idxColName">
									<cfset temp = QuerySetCell(qEmpFormDataNew,idxColName,evaluate("qGetSubFormData.#idxColName#"))/>
								</cfloop>
							</cfloop>
						</cfif>
					</cfloop>
					<cfreturn qEmpFormDataNew>
				<cfelse>
					<cfreturn qGetApprDefault>
				</cfif>
				<!---- end -lena- : reorder library per parent and child ---->
			   
			</cfif>
	       
	    </cffunction>
	    
	    <cffunction name="getEmpNoteData">
	        <cfargument name="periodcode" default="">
	        <cfargument name="refdate" default="">
	        <cfargument name="lstreviewer" default="">
	        <cfargument name="formno" default="">
	        <cfargument name="planformno" default="">
			<cfargument name="varcocode" default="#request.scookie.cocode#">
	        <cfif not len(formno)>
	            <cfquery name="Local.qGetEvalNote" datasource="#request.sdsn#">
		            SELECT note_name, note_order, '' note_answer, '#request.scookie.user.empid#' AS rvid FROM TPMDPERIODNOTE
					WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
		       </cfquery>
	        <cfelse>
				<cfset local.newlstrev = "">
				<cfloop list="#arguments.lstreviewer#" index="local.idxreviewer">
					<cfquery name="Local.qCheckStat" datasource="#request.sdsn#">
						SELECT head_status FROM TPMDPERFORMANCE_EVALH
						WHERE form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
						AND reviewer_empid = <cfqueryparam value="#idxreviewer#" cfsqltype="cf_sql_varchar">
						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					</cfquery>
					<cfif (qCheckStat.head_status eq 1 AND idxreviewer neq REQUEST.SCOOKIE.USER.EMPID) OR ((qCheckStat.head_status eq 0 OR qCheckStat.head_status eq 1) AND idxreviewer eq REQUEST.SCOOKIE.USER.EMPID)>
						<cfset local.newlstrev = ListAppend(newlstrev, idxreviewer)/>
					</cfif>
				</cfloop>
				<cfif newlstrev neq "">
					<cfquery name="Local.qGetEvalNote" datasource="#request.sdsn#">
						SELECT note_name, note_order, note_answer, reviewer_empid AS rvid FROM TPMDPERFORMANCE_EVALNOTE
						WHERE form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
						AND reviewer_empid IN (<cfqueryparam value="#newlstrev#" list="yes" cfsqltype="cf_sql_varchar">)
						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					</cfquery>
					<cfif qGetEvalNote.recordcount eq 0>
						<cfquery name="Local.qGetEvalNote" datasource="#request.sdsn#">
						SELECT note_name, note_order, '' note_answer, '#request.scookie.user.empid#' AS rvid FROM TPMDPERIODNOTE
						WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
						AND reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						</cfquery>
					</cfif>
				<cfelse>
					<cfquery name="Local.qGetEvalNote" datasource="#request.sdsn#">
					SELECT note_name, note_order, '' note_answer, '#request.scookie.user.empid#' AS rvid FROM TPMDPERIODNOTE
					WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					</cfquery>
				</cfif>
		        
	        </cfif>
	        <cfreturn qGetEvalNote>
	    </cffunction>
	    
	    
	    <!--- FUNGSI-FUNGSI CUSTOM REQUEST --->
	    <cffunction name="Approve">
	        <cfreturn true>
	    </cffunction>

		<cffunction name="FullyApprovedProcess" access="public">
			<cfargument name="strRequestNo" type="string" required="yes">
			<cfargument name="iApproverUserId" type="string" required="yes">
			<cfargument name="strckFormApprove" type="struct" required="no">
			<cfquery name="Local.qCheckIfRequestHasBeenApproved" datasource="#request.sdsn#">
				SELECT DISTINCT reviewer_empid, isfinal, reviewee_empid, head_status FROM TPMDPERFORMANCE_EVALH
			    WHERE request_no = <cfqueryparam value="#strRequestNo#" cfsqltype="cf_sql_varchar">
	            	AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
			</cfquery>
	        <cfif qCheckIfRequestHasBeenApproved.recordcount>
	        	<!--- Update Final Record --->
	            <cfquery name="local.qGetFinalRecord" dbtype="query">
	            	SELECT * FROM qCheckIfRequestHasBeenApproved
	                WHERE reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            <cfif qGetFinalRecord.recordcount and qGetFinalRecord.isfinal eq 0>
			        <cfquery name="local.qUpdatePMReqForm" datasource="#request.sdsn#">
						UPDATE TPMDPERFORMANCE_EVALH
			            SET isfinal = 1
					    WHERE request_no = <cfqueryparam value="#strRequestNo#" cfsqltype="cf_sql_varchar">
			                AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
			        </cfquery>
			        
			        <!--- yan tambahan yang send dari draft --->
			        <cfquery name="local.qCheckIfExistsInFinal" datasource="#request.sdsn#">
			            SELECT F.form_no,F.company_code,EH.score, EH.conclusion
			            FROM TPMDPERFORMANCE_FINAL F
			            LEFT JOIN TPMDPERFORMANCE_EVALH EH ON F.form_no = EH.form_no AND F.company_code = EH.company_code
			            WHERE EH.request_no = <cfqueryparam value="#strRequestNo#" cfsqltype="cf_sql_varchar">
			                AND EH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
			                AND EH.reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
			        </cfquery>
			        <cfif not qCheckIfExistsInFinal.recordcount>
			            <cfquery name="local.qInsertFinal" datasource="#request.sdsn#">
			                INSERT INTO TPMDPERFORMANCE_FINAL
	                    	(
	                    	form_no, company_code, period_code, reference_date,
	                    	reviewee_empid, reviewee_posid, reviewee_grade, reviewee_employcode,
	                    	final_score, final_conclusion, created_by, created_date,
	                    	modified_by, modified_date,
	                    	ori_conclusion, adjust_no, ori_score
	                    	)
	                        SELECT form_no, company_code, period_code, reference_date, 
	                        	reviewee_empid, reviewee_posid, reviewee_grade, reviewee_employcode, 
	                        	score, conclusion, '#request.scookie.user.uname#', <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>, 
	                        	'#request.scookie.user.uname#', <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
	                        	conclusion, NULL, NULL
	                        FROM TPMDPERFORMANCE_EVALH
	                        WHERE request_no = <cfqueryparam value="#strRequestNo#" cfsqltype="cf_sql_varchar">
			                    AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
			                    AND isfinal = 1
			            </cfquery>
			        </cfif>
			        <!--- --->
	            </cfif>
	            
	            <!--- DELETE RECORD yang di SKIP --->
	            <cfquery name="local.qGetSkipRecord" dbtype="query">
	            	SELECT reviewer_empid FROM qCheckIfRequestHasBeenApproved
	                WHERE head_status = 0
	            </cfquery>
	            <cfset Local.LstReviewerSkipped = valuelist(qGetSkipRecord.reviewer_empid)>
	            <cfif listlen(LstReviewerSkipped)>
	            	<!--- harusnya hapus data-data untuk empid tersebut --->
	            </cfif>
	        </cfif>
	        
			<cfreturn>
		</cffunction>

       <cffunction name="SendToNext">
	    	<cfparam name="sendtype" default="next">
			<cfset local.strckData = FORM/>
			<cfset var objRequestApproval = CreateObject("component", "SFRequestApproval").init(false) /><!---TCK1908-0518296 set ke false untuk skip approver ketika step workflow approval tidak ditemukan employeenya--->
			<cfset Local.temp_outs_list = "">
			<cfquery name="local.qCekPMReqStatus" datasource="#request.sdsn#">
				SELECT DISTINCT reqemp, status, approval_list, outstanding_list FROM TCLTREQUEST
				WHERE req_type = 'PERFORMANCE.EVALUATION'
					AND req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
					AND company_id = <cfqueryparam value="#strckData.COID#" cfsqltype="cf_sql_integer"> <!---modified by  ENC51115-79853 --->
					AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
			</cfquery>
            			
            			
            <!---Chcek is planning already fullyApproved--->
            <cfparam name="listPeriodComponentUsed" default="">
            <cfset LOCAL.strMessage = Application.SFParser.TransMLang("JSPerformance Planning is not Fully approved yet", true)>
            <cfif formno NEQ '' AND ( ListfindNoCase(listPeriodComponentUsed,'ORGKPI')  OR ListfindNoCase(listPeriodComponentUsed,'PERSKPI') ) > 
                <cfquery name="LOCAL.qCheckPlanning" datasource="#REQUEST.SDSN#">
                    SELECT FORM_NO FROM TPMDPERFORMANCE_PLANH
                    INNER JOIN TCLTREQUEST 
                    	ON TCLTREQUEST.req_no = TPMDPERFORMANCE_PLANH.request_no
                    WHERE TCLTREQUEST.status NOT IN (9,3)
                    AND FORM_NO = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
                </cfquery>
                <cfif qCheckPlanning.recordcount neq 0>
        			<cfoutput>
        				<script>
        					alert("#strMessage#");
        					parent.refreshPage();
        					parent.popClose();
        				</script>
        			</cfoutput>
        			<cf_sfabort>
                </cfif>
            </cfif>
            <!---Chcek is planning already fullyApproved--->
			
			
	        <cfif sendtype neq 'draft'>
		     
				<cfif qCekPMReqStatus.status eq 0> 
						<cfset local.tempOutstanding = 1>
						<cfset local.tempStatus = 2>
						<cfif ListLast(strckData.FullListAppr) eq qCekPMReqStatus.reqemp>
							<cfset tempStatus = 3>
							<cfset tempOutstanding = 0>
						</cfif>
							<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
								DELETE FROM TPMDPERFORMANCE_EVALNOTE
								WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
							</cfquery>
							<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
								DELETE FROM TPMDPERFORMANCE_EVALD
								WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
								AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar">
							</cfquery>
							<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
								DELETE FROM TPMDPERFORMANCE_EVALH
								WHERE request_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
								AND form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
								AND period_code =  <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
								AND reference_date = <cfqueryparam value="#reference_date#" cfsqltype="cf_sql_timestamp">
								AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar">
							</cfquery>
							<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
								DELETE FROM TCLTREQUEST
								WHERE req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
							</cfquery>
							
							<cfif not structkeyexists(strckData,"persKPIArray")>
							<cfelse>
								<cfset strckData.persKPIArray = Replace(strckData.persKPIArray, "\r\n", " ","all")>
							</cfif>
							<cfif not structkeyexists(strckData,"competencyArray")>
							<cfelse>
								<cfset strckData.competencyArray = Replace(strckData.competencyArray, "\r\n", " ","all")>
							</cfif>
							<cfset Add()>
				<cfelse>
						
							<cfif qCekPMReqStatus.status eq 4 and listlen(qCekPMReqStatus.outstanding_list)>
								<cfset temp_outs_list = qCekPMReqStatus.outstanding_list>
								<cfset temp_outs_list = listdeleteat(temp_outs_list,listfindnocase(temp_outs_list,REQUEST.SCOOKIE.USER.UID,","))>
							</cfif>
							
							<cfif len(temp_outs_list)>
								<!----<cf_sfwritelog dump="temp_outs_list" prefix="temp_outs_list">---->
								<cfquery name="local.qUpdApprovedData" datasource="#request.sdsn#">
									UPDATE TCLTREQUEST
									SET outstanding_list = <cfqueryparam value="#temp_outs_list#" cfsqltype="cf_sql_varchar">,
									
									<cfif qCekPMReqStatus.reqemp eq REQUEST.SCOOKIE.USER.EMPID>
										status = 1,
									<cfelse>
										status = 2,
									</cfif>
									
									modified_by = <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
									modified_date = <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp">		
									WHERE req_type = 'PERFORMANCE.EVALUATION'
										AND req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
										AND company_id = <cfqueryparam value="#strckData.COID#" cfsqltype="cf_sql_integer"> 
										AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar"> 
								</cfquery>
							</cfif>
							
							<cfset local.valret = objRequestApproval.ApproveRequest(request_no, REQUEST.SCookie.User.uid, true) />
							<cfif not isBoolean(valret)>
							<cfelse>
    							<cfif valret>
    								<cfquery name="local.qCekPMReqStatus" datasource="#request.sdsn#">
    									SELECT status FROM TCLTREQUEST
    									WHERE req_type = 'PERFORMANCE.EVALUATION'
    										AND req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
    										AND company_id = <cfqueryparam value="#strckData.COID#" cfsqltype="cf_sql_integer"> 
    										AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar"> 
    							
    								</cfquery>
    								<cfif qCekPMReqStatus.status eq 3>
    									<cfset sendtype = 'final'>
    									<cfset strckData.isfinal = 1/>
    									<cfset strckData.head_status = 1/>
    								</cfif>
    							</cfif>
							</cfif>
							
							
                            <!--- TCK0818-81809 (Revise) | Send to next delete EVALH and EVALD Higher Approver --->
                        	<cfquery name="local.qSelStepHigher" datasource="#request.sdsn#">
                            	SELECT reviewer_empid FROM TPMDPERFORMANCE_EVALH 
                            	WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
                            	AND request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
                            	AND review_step > <cfqueryparam value="#strckData.USERINREVIEWSTEP#" cfsqltype="cf_sql_varchar">
                            	AND company_code =  <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
                            </cfquery>
                            
                            <cfloop query="qSelStepHigher">
                        	    <cfquery name="local.qDelPlanD" datasource="#request.sdsn#">
                            	    DELETE FROM  TPMDPERFORMANCE_EVALD 
                            		WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
                            		AND reviewer_empid = <cfqueryparam value="#qSelStepHigher.reviewer_empid#" cfsqltype="cf_sql_varchar">
                            	    AND company_code =  <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
                                </cfquery>
                                
                                <cfquery name="local.qDelPlanD" datasource="#request.sdsn#">
                            	    DELETE FROM  TPMDPERFORMANCE_EVALH 
                            		WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
                            		AND request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
                            		AND reviewer_empid = <cfqueryparam value="#qSelStepHigher.reviewer_empid#" cfsqltype="cf_sql_varchar">
                            	    AND company_code = <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
                                </cfquery>
                            </cfloop>
                            <!--- TCK0818-81809 (Revise) | Send to next delete EVALH and EVALD Higher Approver --->
							
							<cfset SaveTransaction(50,strckData)/>
				</cfif>
				
				
				<!--- Notif here --->
    		    <!---Get alloskip param--->
                <cfset LOCAL.allowskipCompParam = "Y">
                <cfset LOCAL.requireselfassessment = 1>
                <cfquery name="LOCAL.qCompParam" datasource="#request.sdsn#">
                	SELECT field_value, UPPER(field_code) field_code from tclcappcompany where UPPER(field_code) IN ('ALLOW_SKIP_REVIEWER', 'REQUIRESELFASSESSMENT') and company_id = '#REQUEST.SCookie.COID#'
                </cfquery>
                
                <cfloop query="qCompParam">
                    <cfif TRIM(qCompParam.field_code) eq "ALLOW_SKIP_REVIEWER" AND TRIM(qCompParam.field_value) NEQ ''>
                    	<cfset allowskipCompParam = TRIM(qCompParam.field_value)>
                    <cfelseif TRIM(qCompParam.field_code) eq "REQUIRESELFASSESSMENT" AND TRIM(qCompParam.field_value) NEQ '' >
                    	<cfset requireselfassessment = TRIM(qCompParam.field_value)> <!---Bypass self assesment--->
                    </cfif>
                </cfloop>
    		    <!---Get alloskip param--->
    		    
    		    <!---Get status Request--->
				<cfquery name="local.qCekPMReqCurrentStatus" datasource="#request.sdsn#">
					SELECT status FROM TCLTREQUEST
					WHERE req_type = 'PERFORMANCE.EVALUATION'
						AND req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
						AND company_id = <cfqueryparam value="#strckData.COID#" cfsqltype="cf_sql_integer"> 
						AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar"> 
				</cfquery>
    		    <!---Get status Request--->
    		    
                <cfif qCekPMReqCurrentStatus.status EQ 3 > <!---Validasi Jika fully approved--->
                    <cfset LOCAL.additionalData = StructNew() >
                    <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                    
                    <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                        template_code = 'PerformanceEvalNotifFullyApproved', 
                        lstsendTo_empid = reviewee_empid , 
                        reviewee_empid = reviewee_empid ,
                        strckData = additionalData
                    )>
                <cfelseif val(FORM.UserInReviewStep)+1 LTE Listlen(FORM.FullListAppr) > <!---Validasi ada next approver--->
                    <cfif allowskipCompParam EQ 'N' > <!---Tidak bisa skip harus berurutan--->
        		        <cfset LOCAL.lstNextApprover = ListGetAt( FORM.FullListAppr , val(FORM.UserInReviewStep)+1 )><!---hanya get list next approver--->
                    <cfelse>
        		        <cfset LOCAL.lstNextApprover = ''><!---all approver dikirim--->
                        <cfloop index="LOCAL.idx" from="#val(FORM.UserInReviewStep)+1#" to="#Listlen(FORM.FullListAppr)#" >
        		            <cfset tempList = ListGetAt( FORM.FullListAppr , idx )><!---get list next approver--->
    		                <cfset lstNextApprover = ListAppend(lstNextApprover,tempList) ><!---all approver dikirim--->
                        </cfloop>
                    </cfif>
                    
                    <cfset LOCAL.additionalData = StructNew() >
                    <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                    
                    <cfif lstNextApprover NEQ ''>
                        <cfset lstSendEmail = replace(lstNextApprover,"|",",","all")>
                        <cfif reviewee_empid EQ request.scookie.user.empid> <!--- Send by reviewee status not requested --->
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalSubmitByReviewee', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        <cfelse><!--- Send by approver status not requested --->
                        
                            <cfif ListLast(FORM.FullListAppr) EQ lstNextApprover>
                                <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                    template_code = 'PerformanceEvalSubmitToLastApprover', 
                                    lstsendTo_empid = lstSendEmail , 
                                    reviewee_empid = reviewee_empid ,
                                    strckData = additionalData
                                )>
                            <cfelse>
                                <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                    template_code = 'PerformanceEvalSubmitByApprover', 
                                    lstsendTo_empid = lstSendEmail , 
                                    reviewee_empid = reviewee_empid ,
                                    strckData = additionalData
                                )>
                            </cfif>
                        </cfif>
                    </cfif>
                </cfif>
				<!--- Notif here --->
				
	        <cfelse>
		        <cfset SaveTransaction(50,strckData)/>
				
	        </cfif>
	        
	        <!--- Tampilkan Alert ketika ada yang di skip --->
	        <cfif sendtype neq 'draft'>
    	        <cfquery name="LOCAL.qGetApprInfo" datasource="#request.sdsn#">
                    SELECT reviewer_empid, review_step, head_status FROM TPMDPERFORMANCE_EVALH 
                    WHERE  request_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
                        AND form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
    	        </cfquery>
    	        <cfquery name="LOCAL.qGetCurrApprInfo" dbtype="query">
                    SELECT reviewer_empid, review_step, head_status FROM qGetApprInfo 
                    WHERE  reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
    	        </cfquery>
    	        <cfquery name="LOCAL.cekApprover" dbtype="query">
                    SELECT * FROM qGetApprInfo 
                    WHERE reviewer_empid <> <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
                       AND review_step < <cfqueryparam value="#qGetCurrApprInfo.review_step#" cfsqltype="cf_sql_varchar">
                       AND head_status = 0
    	        </cfquery>
    	        <cfif cekApprover.recordcount neq 0>
        			<cfoutput>
        				<script>
        					alert("#Application.SFParser.TransMLang("JSThere are some approver skipped", true)#");
        				</script>
        			</cfoutput>
    	        </cfif>
	        </cfif>
	        <!--- Tampilkan Alert ketika ada yang di skip --->
			<cfquery name="LOCAL.qGetDataRequest" datasource="#request.sdsn#">
                SELECT seq_id, req_no, status,outstanding_list, company_id, email_list, approval_list FROM TCLTREQUEST 
                WHERE  req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
	        </cfquery> 
	        <cfif sendtype eq 'draft'>
				<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully Save Request as Draft", true)>
	        <cfelseif sendtype eq 'final' OR qGetDataRequest.status EQ 3 >
				<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully Save Request as Final Conclusion", true)>
				<!--- <cfset tempSendEmail = SendEmail(qGetDataRequest.req_no, qGetDataRequest.status,qGetDataRequest.email_list,qGetDataRequest.seq_id,qGetDataRequest.company_id) /> --->
	        <cfelse>
				<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully Send Request to Next Reviewer", true)>
				<!--- <cfset tempSendEmail = NewRequestNotif({mailtmpltRqster="",mailtmpltRqstee="",mailtmpltAprvr="NewRequestNotification",notiftmpltRqster="",notiftmpltRqstee="",notiftmpltAprvr="3",strRequestNo=qGetDataRequest.req_no,iStatusOld=qGetDataRequest.status,lstNextApprover=qGetDataRequest.outstanding_list,requestcoid=qGetDataRequest.company_id,requestId=qGetDataRequest.seq_id,lastOutstanding=ListLast(qGetDataRequest.outstanding_list)})> --->
	        </cfif>
	        <cfset flagnewui = "#REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE#">
	        <cfif flagnewui eq 0>
    			<cfoutput>
    				<script>
    					alert("#strMessage#");
    					parent.refreshPage();
    					parent.popClose();
    				</script>
    			</cfoutput>
    		<cfelseif flagnewui eq 1>
    		    <cfset data = {"success"="1","request_no"="#request_no#","form_no"="#formno#", "MSG"="#strMessage#"}>
                <cfset serializedStr = serializeJSON(data)>
    		    <cfoutput>
    		        #serializedStr#
    		    </cfoutput>
			</cfif>
			
	    </cffunction>
	    <cffunction name="ApprovalLoop">
	    	<cfargument name="wdappr" required="yes">
	    	<cfargument name="empid" required="yes">
	    	<cfargument name="ListEmpFinishedReview" default="" required="no">
	        <cfset Local.empinstep = 0>
	        <cfset Local.ApproverList = "">
	        <cfset Local.ApprovedStepList = "">
	        <cfset Local.isbreak = false>
	        <!--- looping step --->
	        <cfloop index="local.idx" from="1" to="#ArrayLen(wdappr)#">
	        	<cfif ArrayLen(wdappr[idx].approver) gt 1>
	            	<cfset local.LstTemp=""/>
			        <!--- looping share approver --->
	            	<cfloop index="local.idx2" from="1" to="#ArrayLen(wdappr[idx].approver)#">
	                    <cfif ArrayLen(wdappr[idx].approver[idx2]) gt 1>
			            	<cfset local.LstTemp2=""/>
			                <!--- looping share position --->
		                	<cfloop index="local.idx3" from="1" to="#ArrayLen(wdappr[idx].approver[idx2])#">
				            	<cfset LstTemp2 = ListAppend(LstTemp2,wdappr[idx].approver[idx2][idx3].emp_id,"|")/> <!---";" diganti biar sama--->
	                            <cfif empid eq wdappr[idx].approver[idx2][idx3].emp_id and not isbreak>
	                            	<cfset empinstep = idx />
							        <cfset isbreak = true>
	                            </cfif>
		                    </cfloop>
		            		<cfset LstTemp = ListAppend(LstTemp,LstTemp2,"|")/>
	                    <cfelse>
			            	<cfset LstTemp = ListAppend(LstTemp,wdappr[idx].approver[idx2][1].emp_id,"|")/>
	                        <cfif empid eq wdappr[idx].approver[idx2][1].emp_id and not isbreak>
	                          	<cfset empinstep = idx />
						        <cfset isbreak = true>
	                        </cfif>
	                    </cfif>
	                </cfloop>
	            	<cfset ApproverList = ListAppend(ApproverList,LstTemp)/>
	            <cfelse>
		        	<cfif ArrayLen(wdappr[idx].approver[1]) gt 1>
		            	<cfset LstTemp=""/>
		                <!--- looping share position --->
	                	<cfloop index="local.idx22" from="1" to="#ArrayLen(wdappr[idx].approver[1])#">
	                       	<cfset LstTemp = ListAppend(LstTemp,wdappr[idx].approver[1][idx22].emp_id,"|")/> <!---";" diganti biar sama--->
	                        <cfif empid eq wdappr[idx].approver[1][idx22].emp_id and not isbreak>
	                          	<cfset empinstep = idx />
						        <cfset isbreak = true>
	                        </cfif>
	                    </cfloop>
		            	<cfset ApproverList = ListAppend(ApproverList,LstTemp)/>
	                <cfelse>
		            	<cfset ApproverList = ListAppend(ApproverList,wdappr[idx].approver[1][1].emp_id)/>
	                    <cfif empid eq wdappr[idx].approver[1][1].emp_id and not isbreak>
	                      	<cfset empinstep = idx />
					        <cfset isbreak = true>
	                    </cfif>
	                </cfif>
	            </cfif>
	        </cfloop>
	        <cfset local.strckApprCekReturn = structnew()/>
	        <cfset strckApprCekReturn.empinstep = empinstep/>
	        <!---<cfset strckApprCekReturn.approvedsteplist = ApprovedStepList/>--->
	        <cfset strckApprCekReturn.fullapproverlist = ApproverList/>
	        <cfreturn strckApprCekReturn>
	    </cffunction>
	    
	  <cffunction name="GetApproverList">
	    	<cfargument name="empid" required="yes">
	    	<cfargument name="reqno" default="">
	    	<cfargument name="emplogin" default="#request.scookie.user.empid#">
	    	<cfargument name="reqorder" default="-">
			<cfargument name="varcoid" default="#request.scookie.coid#"  required="no">
			<cfargument name="varcocode" default="#request.scookie.cocode#"  required="no">
	       	<!--- cek kalo request sudah pernah dibuat --->
	        <cfquery name="local.qCheckRequest" datasource="#request.sdsn#">
	        	SELECT requester, approval_data, approval_list, approved_list, outstanding_list, status FROM TCLTREQUEST
	            WHERE company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		            AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
		            AND req_type = 'PERFORMANCE.EVALUATION'
		            AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
		            AND reqemp = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					and req_no <> '' <!--- YH --->
	        </cfquery>
	        
	        <!--- cari yang sudah pernah isi dan statusnya--->
	        <cfquery name="Local.qCheckEmpFilled" datasource="#request.sdsn#">
	        	SELECT *
	            FROM TPMDPERFORMANCE_EVALH
	            WHERE company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            AND request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	            AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	            
	            <!--- artinya yang statusnya masih draft di skip kalo status requestnya selain revised --->
	           	<cfif qCheckRequest.status neq 4> <!--- ini butuh hapus record yg statusnya draft tapi stepnya diskip --->
	            AND (
					head_status = 1
					OR
					reviewer_empid = <cfqueryparam value="#emplogin#" cfsqltype="cf_sql_varchar">
	            )
	            </cfif>
	            <!--- [Q} pertanyaan, jika sudah final, apakah yang head statusnya = 0 ini dihapus saja ? [A] : Ya--->
	            
	            ORDER BY review_step ASC
	        </cfquery>
	        
	        <!--- merupakan list empid yang sudah pernah buat untuk reqno tersebut --->
	        <cfset local.ListFilledEmp = valuelist(qCheckEmpFilled.reviewer_empid)/>
	        <!--- merupakan list review step yang sudah pernah buat untuk reqno tersebut --->
	        <cfset local.ListFilledEmpStep = valuelist(qCheckEmpFilled.review_step)/>
	        
	        <!--- merupakan list head_status yang sudah pernah buat untuk reqno tersebut --->
	        <cfset local.ListHeadStatus = valuelist(qCheckEmpFilled.head_status)/>
	        
	   		<cfif qCheckRequest.recordcount>
				<cfset Local.strckResultRequestApproval = StructNew() />
	            <cfif len(qCheckRequest.approval_data)>
					<cfset LOCAL.wdapproval=SFReqFormat(qCheckRequest.approval_data,"R",[])>
	            	<!---TW:<cfwddx action="wddx2cfml" input="#qCheckRequest.approval_data#" output="wdapproval">--->
					<cfset strckResultRequestApproval.wdapproval = wdapproval/>
	            <cfelse><!--- status dari request masih draft --->
					<cfset strckResultRequestApproval = objRequestApproval.Generate("PERFORMANCE.EVALUATION", emplogin, empid, reqorder) />
	            </cfif>
				<cfset strckResultRequestApproval.approval_list = qCheckRequest.approval_list/>
				<cfset strckResultRequestApproval.outstanding_list = qCheckRequest.outstanding_list/>
				<cfset strckResultRequestApproval.requester = qCheckRequest.requester/>
				<cfset strckResultRequestApproval.status = qCheckRequest.status/>
	        <cfelse>
				<cfset Local.strckResultRequestApproval = StructNew() />
				<cfset strckResultRequestApproval = objRequestApproval.Generate("PERFORMANCE.EVALUATION", emplogin, empid, reqorder) />
				<cfif not isBoolean(strckResultRequestApproval)>
				<cfset strckResultRequestApproval.approval_list = ""/>
				<cfset strckResultRequestApproval.requester = ""/>
				<cfset strckResultRequestApproval.status = ""/>
				<cfset strckResultRequestApproval.outstanding_list = ""/>
				</cfif>
				
	        </cfif>
	        <cfif not isBoolean(strckResultRequestApproval)>
				<cfset local.strckAppr = ApprovalLoop(strckResultRequestApproval.wdapproval,emplogin)/>
				<cfset local.userinstep = strckAppr.empinstep/>
				<cfset local.full_list_approver = strckAppr.fullapproverlist/>
			<cfelse>
				<cfset userinstep = 0/>
				<cfset full_list_approver = ""/>
			</cfif>
	        <cfset local.list_approver = full_list_approver/>
	        
	        <!--- APPROVER IS REVIEWEE --->
	        <cfset local.reviewee_in_step = listfindnocase(full_list_approver,empid,",|")>
	        <cfif reviewee_in_step gte 1> <!--- sebelumnya gt tanpa e [YAN]--->
	            <cfset local.approver_is_reviewee = 1/>
	        <cfelse>
		        <cfset local.approver_is_reviewee = 0/>
	        </cfif>
	        
	        <!--- REVIEWEE AS APPROVER --->
	        <cfif approver_is_reviewee>
	        	<cfset local.reviewee_as_approver = 0>
	        <cfelseif (emplogin eq empid and approver_is_reviewee eq 0) or (listfindnocase(ListFilledEmp,empid))>
	        	<cfset reviewee_as_approver = 1>
	        	<cfset list_approver = listprepend(full_list_approver,empid)>
	            <cfset full_list_approver = list_approver>
                <cfif userinstep neq 0 OR request.scookie.user.empid eq empid> <!---Replace Approver--->
    	            <cfset ++userinstep/>
    	        </cfif>
	        <cfelse>
	        	<cfset reviewee_as_approver = 0>
	        </cfif>

	        <cfloop list="#list_approver#" index="local.listempinstepno">
	           	<cfloop list="#listempinstepno#" delimiters="|" index="local.cekidx">
	               	<cfif listfindnocase(ListFilledEmp,cekidx)>
	                   	<cfset list_approver = listsetat(list_approver,listfindnocase(list_approver,listempinstepno),cekidx)/>
	                    <cfbreak>
	                <cfelseif cekidx eq emplogin>
			           	<cfset list_approver = listsetat(list_approver,listfindnocase(list_approver,listempinstepno),request.scookie.user.empid)/>
	                    <cfbreak>
	                </cfif>
	            </cfloop>
	        </cfloop>
	        
	        <cfset local.list_approver_full = list_approver>
	        
	        <!--- hapus approver yang berada di step lebih tinggi dari user yang login --->
	        <cfif userinstep neq 0 and userinstep neq listlen(list_approver)>
	        	<cfloop index="local.rmv" from="#listlen(list_approver)#" to="#userinstep+1#" step="-1">
	            	<cfset list_approver = ListDeleteAt(list_approver,rmv)/>
	            </cfloop>
	        </cfif>

	        <!--- variabel ini digunakan untuk kasus step 2 melihat request yang sudah di approved oleh step di atasnya dan step 2 tidak melkukan penilaian --->
			<cfset local.higher_step_is_approving = 0>
	        
			<cfset local.step_to_viewed = "">
	        <cfloop list="#ListFilledEmpStep#" index="local.viewedstep">
	        	<cfif userinstep gt viewedstep>
					<cfset step_to_viewed = listappend(step_to_viewed,viewedstep)>
	        	<cfelseif userinstep eq viewedstep>
					<cfset step_to_viewed = listappend(step_to_viewed,viewedstep)>
					<cfset list_approver = listsetat(list_approver,viewedstep,listgetat(ListFilledEmp,listfindnocase(ListFilledEmpStep,viewedstep)))>
	            <cfelse>
	            	<cfset higher_step_is_approving = 1>
	            	<cfbreak>
	            </cfif>
	        </cfloop>
	        <cfif not isBoolean(strckResultRequestApproval)>
				<!--- kalo step si user ga ada di step yang udah pernah diisi (dan telah melewati prosesnya)--->
				<cfif not listfindnocase(step_to_viewed,userinstep) and userinstep neq 0>
				
					<!--- kalo status requestnya 3 ya hanya bisa liat saja untuk step sebelumnya, kalo status requestnya 4 dia bisa kembali isi, kalo selain itu dan higher approver sudah pernah menilai maka dia hanya bisa liat juga --->
					<cfif strckResultRequestApproval.status eq 4 or (strckResultRequestApproval.status neq 3 and not higher_step_is_approving)>
						<cfset step_to_viewed = listappend(step_to_viewed,userinstep)>
					</cfif>
				</cfif>
			</cfif>
	        
	       	<cfset local.new_list_approver = "">
	        <cfif len(list_approver)>
	        <cfloop list="#step_to_viewed#" index="local.idx">
	        	<cfset new_list_approver = listappend(new_list_approver,listgetat(list_approver,idx))>
	        </cfloop>
	        </cfif>
	        
	        <!--- untuk mencegah approver lain yang tidak menilai dapat menilai kembali, padahal statusnya adalah unfinalized --->
	        <cfif qCheckRequest.status eq 2>
		        <cfquery name="Local.qCheckAllEmpFilled" datasource="#request.sdsn#">
		        	SELECT *
		            FROM TPMDPERFORMANCE_EVALH
		            WHERE company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
		            AND request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
		            AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
		            ORDER BY review_step ASC
		        </cfquery>
	        	<cfquery name="Local.qLastApproverRecord" dbtype="query">
	            	SELECT MAX(review_step) AS stepmax FROM qCheckAllEmpFilled
	            </cfquery>
	        	<cfquery name="Local.qCekIfRequestIsUnfinal" dbtype="query">
	            	SELECT created_by, modified_by FROM qCheckAllEmpFilled
	                WHERE review_step = <cfqueryparam value="#qLastApproverRecord.stepmax#" cfsqltype="cf_sql_integer">
	            </cfquery>
	            <cfif qCekIfRequestIsUnfinal.recordcount and listfindnocase(qCekIfRequestIsUnfinal.modified_by,"UNFINAL","|")>
		        	<cfset step_to_viewed = "">
	            </cfif>
	        </cfif>

	       	<!--- ambil nilai head status --->
	       	<cfset local.approver_headstatus = -1/>
			<cfif listfindnocase(ListFilledEmp,emplogin)>
	        	<cfset approver_headstatus = listgetat(ListHeadStatus,listfindnocase(ListFilledEmp,emplogin))/>
	        </cfif>
	        
	        <!--- ambil nilai head status untuk approver sebelumnya --->
			<cfset local.approverbefore_headstatus = 0/>
	        
	        <cfif listlen(new_list_approver)>
		       	<cfset Local.approverbefore_empid = listlast(listdeleteat(new_list_approver,listlen(new_list_approver)))/>
				<cfif listfindnocase(ListFilledEmp,approverbefore_empid)>
		        	<cfset approverbefore_headstatus = listgetat(ListHeadStatus,listfindnocase(ListFilledEmp,approverbefore_empid))/>
		        </cfif>
	        </cfif>
	        
	        <cfset Local.lastApprover = "">
	        <cfif listlen(ListFilledEmp)>
	        	<cfset lastApprover = listlast(ListFilledEmp)>
	        </cfif>
	        
	        <cfset Local.revise_list_approver = "">
	        <cfset Local.revise_pos_atstep = 0>
			<cfif not isBoolean(strckResultRequestApproval)>
				<cfif strckResultRequestApproval.status eq 4>
					<cfquery name="local.qGetListEmpFilled" dbtype="query">
						SELECT * FROM qCheckEmpFilled
						<!--- WHERE head_status = 1 --->
						<!--- harusnya yang draft2 sebelumnya sudah di hapus --->
						ORDER BY review_step ASC
					</cfquery>
					<cfquery name="local.qGetMaxStepToDraft" dbtype="query">
						SELECT MIN(review_step) AS stepno FROM qGetListEmpFilled
						WHERE head_status = 0
					</cfquery>
					
					<cfset revise_list_approver = valuelist(qGetListEmpFilled.reviewer_empid)>
					<cfset revise_pos_atstep = qGetMaxStepToDraft.stepno>
				</cfif>
			<cfelse>
				 <cfset revise_list_approver = "">
				 <cfset revise_pos_atstep = 0>
			</cfif>
	        <cfset local.strckReturn = structnew()/>
	        <cfset strckReturn.index = userinstep/>
	        <cfset strckReturn.LstApprover = new_list_approver/>
	        <cfset strckReturn.FullListApprover = full_list_approver/>
			<cfset strckReturn.approver_headstatus = approver_headstatus/>
			<cfset strckReturn.approverbefore_headstatus = approverbefore_headstatus/>
			<cfif not isBoolean(strckResultRequestApproval)>
				<cfset strckReturn.status = strckResultRequestApproval.status/>
					<cfset strckReturn.current_outstanding_list = strckResultRequestApproval.outstanding_list/>
			<cfelse>
				<cfset strckReturn.status = strckResultRequestApproval/>
					<cfset strckReturn.current_outstanding_list = "">
			</cfif>
			<cfset strckReturn.reviewee_as_approver = reviewee_as_approver/>
			<cfset strckReturn.approver_is_reviewee = approver_is_reviewee/>
			<cfset strckReturn.step_to_viewed = step_to_viewed/>
			<cfset strckReturn.revise_list_approver = revise_list_approver/>
			<cfset strckReturn.revise_pos_atstep = revise_pos_atstep/>
			<cfset strckReturn.lastApprover = lastApprover/>
			
		
			<cfset strckReturn.higher_step_is_approving = higher_step_is_approving/>
	        
	        <cfreturn strckReturn/>
	    </cffunction>
	    
	    <cffunction name="getObjUnitObjective">
	    	<cfparam name="empid" default="">
	        <cfparam name="formno" default="">
	        <cfparam name="reqno" default="">
	        <cfparam name="periodcode" default="">
			<cfparam name="refdate" default="">
			<!--- add by Shinta 15 July 2014 --->
			<cfset local.appcode = 'PERFORMANCE.Evaluation'>
			<!---<cfquery name="local.qRequestApprovalOrder" datasource="#REQUEST.SDSN#">
				SELECT	seq_id,
						req_order,request_approval_name,
						request_approval_formula,requester,
						requestee FROM	TCLCReqAppSetting
				WHERE	company_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#REQUEST.scookie.COID#" />
				    AND request_approval_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#appcode#"/> 
				ORDER BY req_order DESC
			</cfquery>--->
		<!-----<cfset local.arrEmployee = objRequestApproval.GetEmployeeFromFormula(strRequestApprovalFormula=qRequestApprovalOrder.request_approval_formula,strEmpId=empid, iEmpType=0,retType="Isempid") />
			<cfset local.lstapprover = "">
			<cfloop array="#arrEmployee#" index="local.idxEmployee">
				<cfset lstapprover=listappend(lstapprover,'#idxEmployee['emp_id']#')>
			</cfloop>---->
			<cfset LOCAL.reqorderfix = getApprovalOrder(reviewee=empid,reviewer=REQUEST.scookie.user.empid)>
			
			<!---<cfset local.strckListApprover = GetApproverList(reqno=reqno,empid=empid,reqorder=qRequestApprovalOrder.req_order,varcoid=REQUEST.SCOOKIE.COID,varcocode=REQUEST.SCOOKIE.COCODE)>--->
			<cfset local.strckListApprover = GetApproverList(reqno=reqno,empid=empid,reqorder=reqorderfix,varcoid=REQUEST.SCOOKIE.COID,varcocode=REQUEST.SCOOKIE.COCODE)>
			<cfset local.lstapprover=strckListApprover.FULLLISTAPPROVER>
			<cfset local.cekapp = listfindnocase(lstapprover,#REQUEST.scookie.user.empid#)>
			<cfif cekapp gt 0>
				<cfset local.approveryn = 1 >
			<cfelse>
				<cfset approveryn = 0 >
			</cfif>

			<!--- end --->
		    <cfquery name="local.gqetPos" datasource="#REQUEST.SDSN#">
	        	select distinct emp_id,position_id from teodempcompany
	            where emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
				and  company_id = #REQUEST.SCOOKIE.COID# 
	        </cfquery>
	        <cfquery name="local.qgetheadDiv"  datasource="#REQUEST.SDSN#">
	        	<!----select distinct position_id from teomposition
	            where head_div = <cfqueryparam value="#gqetPos.position_id#" cfsqltype="cf_sql_varchar">  --->
				select dept_id position_id from teomposition
	            where position_id = <cfqueryparam value="#gqetPos.position_id#" cfsqltype="cf_sql_varchar">
	        </cfquery>
			<cfset local.head_empid = qgetheadDiv.position_id>
			
			<cfset local.login_empid = #REQUEST.sCOOKIE.USER.empid#>
			<cfquery name="local.qPoslogin" datasource="#REQUEST.SDSN#">
				select distinct emp_id,position_id from teodempcompany
	            where emp_id = <cfqueryparam value="#login_empid#" cfsqltype="cf_sql_varchar">
				and  company_id = #REQUEST.SCOOKIE.COID# 
			</cfquery>
			<cfquery name="local.qHeadlogin" datasource="#REQUEST.SDSN#">
				 <!---select position_id from teomposition
	            where head_div = <cfqueryparam value="#qPoslogin.position_id#" cfsqltype="cf_sql_varchar"> ---->
				select dept_id position_id from teomposition
	            where position_id = <cfqueryparam value="#qPoslogin.position_id#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfset local.head_login = qHeadlogin.position_id>
			<cfif head_empid neq head_login>
				<cfset local.head_div = 0>
			<cfelse>
				<cfset local.head_div = 1>
			</cfif>
		
	        <cfif qgetheadDiv.recordcount eq 0 >
	        	<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSYou are not allowed to open this form",true)>
	            <cfoutput><script>alert("#SFLANG#");popClose(true);</script></cfoutput><CF_SFABORT>
	        <cfelse>
	        	<cfquery name="local.qCheckPlan" datasource="#REQUEST.SDSN#">
	                select distinct form_no
	                FROM TPMDPERFORMANCE_PLANKPI PLKPI
						INNER JOIN TCLTREQUEST R 
							ON R.req_no = PLKPI.request_no
							AND R.req_type = 'PERFORMANCE.PLAN'
							AND R.company_code = PLKPI.company_code
							AND R.status IN (3,9)
	                where  orgunit_id =<cfqueryparam value="#qgetheadDiv.position_id#" cfsqltype="cf_sql_integer">
	                AND period_code=<cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            
	             <cfif not qCheckPlan.recordcount>
		        	<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSOrganization Unit not yet have approved KPI",true)>
		            <cfoutput><script>alert("#SFLANG#");popClose(true);</script></cfoutput><CF_SFABORT>
	            </cfif> 
	            <!--- <cfset head_div = qgetheadDiv.position_id> --->
		      <!---   <cfoutput><script>console.log("yan : #approveryn#");</script></cfoutput> --->
	        	<cfquery name="local.getEmpDataPos" datasource="#REQUEST.SDSN#" >
	            	select a.emp_id,full_name,b.position_id,user_id as emp_uid,
	                c.pos_name_en as position,c.dept_id as dept_id,d.pos_name_en as org_unit ,
	                '' as form_no,'' as request_no,'' as approval_list,'' as approved_list,'' as reqemp,'' as requester,
	                '' as useratasan,'#REQUEST.sCOOKIE.USER.UID#' as loginid,'' as modified_by,'' as created_by,'#REQUEST.sCOOKIE.USER.empid#' as loginempid,
	                '' as evalkpi_status,'#approveryn#' as approverYN, '#head_div#' as head_div
	                from teomemppersonal a
	                left join teodempcompany b on a.emp_id=b.emp_id
	                left join teomposition c on b.position_id=c.position_id
	                left join teomposition d on c.dept_id=d.position_id
	                where a.emp_id =<cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	             </cfquery>
				
	             <cfquery name="local.qGetAtasan" datasource="#REQUEST.SDSN#">
	             	select distinct user_id from teodempcompany a
	             	left join teomemppersonal c on a.emp_id=c.emp_id
	               left join teomposition b on a.position_id=b.parent_id
	               where b.position_id = <cfqueryparam value="#getEmpDataPos.position_id#" cfsqltype="cf_sql_varchar">
	             </cfquery>
				 
	             <cfset getEmpDataPos.useratasan = qGetAtasan.user_id>
	             <cfquery name="local.getReq" datasource="#REQUEST.SDSN#">
	                select distinct modified_by,created_by,evalkpi_status
	                from TPMDPERFORMANCE_EVALKPI
	                where  orgunit_id =<cfqueryparam value="#qgetheadDiv.position_id#" cfsqltype="cf_sql_integer">
	                AND period_code=<cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	             </cfquery>
	             
	             <cfif val(getReq.recordcount) gt 0>
	             	<cfset getEmpDataPos.modified_by = getReq.modified_by >
	             	<cfset getEmpDataPos.created_by = getReq.created_by >
	             	<cfset getEmpDataPos.evalkpi_status = getReq.evalkpi_status >
	             <cfelse>
	             	<cfset getEmpDataPos.modified_by = "" >
	             	<cfset getEmpDataPos.created_by = "" >
	             	<cfset getEmpDataPos.evalkpi_status = "" >
	             </cfif>
	        </cfif> 
	        <cfreturn  getEmpDataPos >
	    </cffunction>
	    
<cffunction name="SaveEvalKPI">
	    	<cfparam name="sendtype" default="">
			<cfparam name="varcoid" default="#request.scookie.coid#">
			<cfparam name="varcocode" default="#request.scookie.cocode#">
			<cfparam name="sendtype" default="">
	        <cfset local.strckFormdata =FORM >
	        <cfset strckFormdata.evalkpi_status = sendtype>
	        <cfset strckFormdata.company_code = varcocode>
	        <cfset strckFormdata.orgunit_id = dept_id >
			<cfset LOCAL.objModel = CreateObject("component", "SMPerformanceEvalKPI") />
	        <cftransaction>
	            <cfquery name="local.qEvalKPI" datasource="#REQUEST.SDSN#">
	                SELECT distinct lib_code from TPMDPERFORMANCE_EVALKPI
	                WHERE 
	                period_code=<cfqueryparam value="#strckFormdata.period_code#" cfsqltype="cf_sql_varchar">
	                AND orgunit_id = <cfqueryparam value="#strckFormdata.orgunit_id#" cfsqltype="cf_sql_integer">
	                and iscategory= 'N'
	            </cfquery>
	           
	            <cfif qEvalKPI.recordcount>
	                <cfloop query="qEvalKPI">
	                    <cfset strckFormdata.lib_code = qEvalKPI.lib_code>
	                    <cfset strckFormdata.achievement = FORM["org_achievement_#qEvalKPI.lib_code#"]>
	                    <cfset strckFormdata.score = FORM["org_score_#qEvalKPI.lib_code#"]>
	                    <cfquery name="local.qCheckEvalKPILib" datasource="#REQUEST.SDSN#">
	                        select distinct lib_code from TPMDPERFORMANCE_EVALKPI
	                        where period_code=<cfqueryparam value="#strckFormdata.period_code#" cfsqltype="cf_sql_varchar">
			                AND orgunit_id = <cfqueryparam value="#strckFormdata.orgunit_id#" cfsqltype="cf_sql_integer">
	                        and lib_code = <cfqueryparam value="#strckFormdata.lib_code#" cfsqltype="cf_sql_varchar">
	                    </cfquery>
	                
	                    <cfif qCheckEvalKPILib.recordcount>
	                        <cfset local.retvar = objModel.update(strckFormdata)>
	                    <cfelse>
	                        <cfset local.retvar = objModel.insert(strckFormdata)>
	                    </cfif>    
	                </cfloop>
	                <cfquery name="local.qUpdateevalKPIStatusAll" datasource="#REQUEST.SDSN#">
	                    Update TPMDPERFORMANCE_EVALKPI
	                    set evalkpi_status = <cfqueryparam value="#strckFormdata.evalkpi_status#" cfsqltype="cf_sql_varchar">
	                    where 
	                    period_code=<cfqueryparam value="#strckFormdata.period_code#" cfsqltype="cf_sql_varchar">
		                AND orgunit_id = <cfqueryparam value="#strckFormdata.orgunit_id#" cfsqltype="cf_sql_integer">
	                </cfquery>
	            <cfelse>
					 <cfquery name="local.qGetPlanForm" datasource="#REQUEST.SDSN#">
					 select form_no from TPMDPERFORMANCE_PLANKPI
					 where  period_code=<cfqueryparam value="#strckFormdata.period_code#" cfsqltype="cf_sql_varchar">
		                AND orgunit_id = <cfqueryparam value="#strckFormdata.orgunit_id#" cfsqltype="cf_sql_integer">
					 </cfquery>
	                <cfinvoke component="SFPerformanceEvaluation" method="getEmpFormData" empid="#emp_id#" periodcode="#period_code#" refdate="#reference_date#" compcode="ORGKPI" reviewerempid="#request.scookie.user.empid#" varcoid="#request.scookie.coid#" formno ="#qGetPlanForm.form_no#" varcocode="#request.scookie.cocode#" returnvariable="Local.qEmpFormData">
	                <cfloop query="qEmpFormData">
	                    <cfset strckFormdata.lib_code = qEmpFormData.LIBCODE>
	                    <cfset strckFormdata.lib_name_en = qEmpFormData.LIBNAME>
	                    <cfset strckFormdata.lib_desc_en = qEmpFormData.LIB_DESC_EN>
	                    <cfset strckFormdata.iscategory = qEmpFormData.ISCATEGORY>
	                    <cfset strckFormdata.lib_depth= qEmpFormData.DEPTH>
	                    <cfset strckFormdata.weight= qEmpFormData.WEIGHT>
	                    <cfset strckFormdata.target= qEmpFormData.TARGET>
	                    <cfset strckFormdata.achievement_type= qEmpFormData.ACHSCORETYPE>
	                    <cfquery name="local.qGetParentLib" datasource="#REQUEST.SDSN#">
	                        select <cfif request.dbdriver EQ "MSSQL">TOP 1</cfif> lib_code,parent_path,parent_code,lib_order,lookup_code from TPMDPERFORMANCE_PLANKPI
	                        WHERE lib_code =<cfqueryparam value="#qEmpFormData.LIBCODE#" cfsqltype="cf_sql_varchar">
	                        	AND orgunit_id = <cfqueryparam value="#strckFormdata.orgunit_id#" cfsqltype="cf_sql_integer">
	                            AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	                            AND period_code = <cfqueryparam value="#strckFormdata.period_code#" cfsqltype="cf_sql_varchar">
	                            <cfif request.dbdriver EQ "MYSQL">LIMIT 1</cfif>
	                            <cfif request.dbdriver EQ "ORACLE">AND ROWNUM = 1</cfif>
	                    </cfquery>
	                    <cfif qGetParentLib.recordcount>
	                        <cfset strckFormdata.parent_code= qGetParentLib.parent_code>
	                        <cfset strckFormdata.parent_path= qGetParentLib.parent_path>
	                        <cfset strckFormdata.lib_order= qGetParentLib.lib_order>
	                        <cfset strckFormdata.lookup_code = qGetParentLib.lookup_code>
	                    </cfif>    
	                    <cfif qEmpFormData.ISCATEGORY eq 'N'>
	                        <cfset strckFormdata.achievement = FORM["org_achievement_#libcode#"]>
	                        <cfset strckFormdata.score = FORM["org_score_#libcode#"]>
	                 	</cfif>
	                   <cfset local.retvar = objModel.insert(strckFormdata)>
	                </cfloop>
	            </cfif>
			</cftransaction>
			
			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Save Data",true)>
	        <cfoutput>
	            <script>
	                alert("#SFLANG#");
	                parent.popClose(true);
	                parent.refreshPage();
	            </script>
	        </cfoutput>    
	    </cffunction>
	  		
	  		<cffunction name="GetDataEvalD">
			<cfargument name="periodcode" default="">
			<cfargument name="formno" default="">
			<cfargument name="refdate" default="#Now()#">
			<cfargument name="parseEmp" default="">
			<cfargument name="lpr" default="">
			<cfargument name="empid" default="">
			<cfargument name="compcode" default="">
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">
			<cfquery name="local.qGetDataEvalD" datasource="#request.sdsn#">
				SELECT a.form_no, a.reviewer_empid, a.lib_code, a.company_code, a.notes, a.achievement, a.score, b.head_status
				FROM TPMDPERFORMANCE_EVALD a LEFT JOIN TPMDPERFORMANCE_EVALH b 
				ON a.form_no = b.form_no AND a.reviewer_empid = b.reviewer_empid 	
				WHERE  a.form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
				AND a.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar"> 
				<cfif varcocode eq request.scookie.cocode>
					AND a.reviewer_empid = <cfqueryparam value="#empid#" list="yes" cfsqltype="cf_sql_varchar"> 
				</cfif>
				AND a.lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
				AND b.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
				<cfif ucase(compcode) eq "appraisal">
				AND a.lib_type = 'appraisal'
				<cfelseif ucase(compcode) eq "PERSKPI">
				AND a.lib_type = 'PERSKPI'
				<cfelseif ucase(compcode) eq "ORGKPI">
				AND a.lib_type = 'ORGKPI'
				<cfelseif ucase(compcode) eq "ORGKPI">
				AND a.lib_type = 'COMPETENCY'
				</cfif>
			</cfquery>

			<cfreturn qGetDataEvalD>
		</cffunction>
		
		<!---Save Search--->
	    <cffunction name="saveKeyword">
			<cfparam name="pgid" default="">
			<cfparam name="saveSearchName" default="">
			<cfparam name="keyword" default="">
			<cfquery name="LOCAL.qSearchName" datasource="#REQUEST.SDSN#">
				SELECT search_name FROM TCLTSavedSearch 
				WHERE search_name = <cfqueryparam value="#saveSearchName#" cfsqltype="CF_SQL_VARCHAR">
					  AND formpage = <cfqueryparam value="#pgid#" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>
		
			<cfif qSearchName.recordCount>
				<cfoutput>
					<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed Save Search",true)>
					<script>	alert("#SFLANG#");</script>
				</cfoutput>			
			<cfelse>
				<cfquery name="LOCAL.qSaveData" datasource="#REQUEST.SDSN#" result="local.vSQL" debug="#REQUEST.ISDEBUG#">
					INSERT INTO TCLTSavedSearch
					(
						 search_name
						,cruser_id
						,formpage
						,searchpassing
						,created_date
						,created_by
						,modified_date
						,modified_by				
					)
					VALUES
					(
						 <cfqueryparam value="#saveSearchName#" cfsqltype="CF_SQL_VARCHAR">
						,<cfqueryparam value="#REQUEST.SCookie.COID#" cfsqltype="CF_SQL_INTEGER">
						,<cfqueryparam value="#pgid#" cfsqltype="CF_SQL_VARCHAR">
						,<cfqueryparam value="#keyword#" cfsqltype="CF_SQL_VARCHAR">
						,#CreateODBCDateTime(Now())#
						,<cfqueryparam value="#REQUEST.SCookie.User.uname#" cfsqltype="CF_SQL_VARCHAR">
						,#CreateODBCDateTime(Now())#
						,<cfqueryparam value="#REQUEST.SCookie.User.uname#" cfsqltype="CF_SQL_VARCHAR">
					)
				</cfquery>
			</cfif>
		</cffunction>
		
		<cffunction name="removeSaveSearch">
			<cfparam name="seq_id" default="">
			<cfparam name="pgid" default="">
			<cfquery name="LOCAL.qUser" datasource="#REQUEST.SDSN#">
				SELECT cruser_id FROM TCLTSavedSearch WHERE seq_id=<cfqueryparam value="#seq_id#" cfsqltype="CF_SQL_INTEGER">
			</cfquery>
		
			<cfoutput>
				<cfif #qUser.cruser_id# eq #val(REQUEST.SCookie.COID)#>		
					<cfquery name="LOCAL.qDelSaveSearch" datasource="#REQUEST.SDSN#">
						DELETE 
						<cfif request.dbdriver eq 'MYSQL'>
						from
						</cfif>
						TCLTSavedSearch WHERE seq_id=<cfqueryparam value="#seq_id#" cfsqltype="CF_SQL_INTEGER">		
					</cfquery>
					<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Remove Save Search",true)>
				
					<cfquery name="LOCAL.qDataSaveSearch" datasource="#REQUEST.SDSN#">
						SELECT seq_id, search_name, formpage, searchpassing
						FROM TCLTSavedSearch
						WHERE cruser_id = <cfqueryparam value="#REQUEST.SCookie.COID#" cfsqltype="CF_SQL_INTEGER"> 
							  AND formpage = <cfqueryparam value="#pgid#" cfsqltype="CF_SQL_VARCHAR">
					</cfquery>
					
					<ul>
						<cfif qDataSaveSearch.recordCount>
							<cfloop query="qDataSaveSearch">						
								<li>
									<a href="##" onClick="getSearch('#qDataSaveSearch.searchpassing#&seq_id=#qDataSaveSearch.seq_id#','#qDataSaveSearch.search_name#'); return false;">#htmleditformat(qDataSaveSearch.search_name)#</a>&nbsp;<a href="##" onClick="removeSearch('#qDataSaveSearch.seq_id#','divSearch'); return false;" title="Remove Search Name"><img src="#Application.PATH.LIB##Application.OSSPT#skins#Application.OSSPT#def#Application.OSSPT#images#Application.OSSPT#temp#Application.OSSPT#acssdel.png"></a>
									&nbsp;<a href="##" onClick="getSearch('#qDataSaveSearch.searchpassing#','#qDataSaveSearch.search_name#',true,'#qDataSaveSearch.seq_id#'); return false;" title="Edit Search Name"><img src="#Application.PATH.LIB##Application.OSSPT#skins#Application.OSSPT#def#Application.OSSPT#images#Application.OSSPT#temp#Application.OSSPT#ico-edit.png"></a>
								</li>						
							</cfloop>	
						<cfelse>
							<li>Empty Data</li>
						</cfif>
					</ul>
		
					<script>alert("#SFLANG#");</script>
				<cfelse>
					<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed Remove Save Search",true)>
					<script>alert("#SFLANG#");</script>			
				</cfif>
			</cfoutput>
		</cffunction>

		<cffunction name="getListSaveSearch">
			<cfparam name="seq_id" default="">
			<cfparam name="pgid" default="">
		
			<cfoutput>
				<cfquery name="LOCAL.qDataSaveSearch" datasource="#REQUEST.SDSN#">
					SELECT seq_id, search_name, formpage, searchpassing
					FROM TCLTSavedSearch
					WHERE formpage = <cfqueryparam value="#pgid#" cfsqltype="CF_SQL_VARCHAR">
				</cfquery>
				<ul>
					<cfif qDataSaveSearch.recordCount>
						<cfloop query="qDataSaveSearch">						
							<li>
								<a href="##" onClick="getSearch('#qDataSaveSearch.searchpassing#&seq_id=#qDataSaveSearch.seq_id#','#qDataSaveSearch.search_name#'); return false;">#htmleditformat(qDataSaveSearch.search_name)#</a>&nbsp;<a href="##" onClick="removeSearch('#qDataSaveSearch.seq_id#','divSearch'); return false;" title="Remove Search Name"><img src="#Application.PATH.LIB##Application.OSSPT#skins#Application.OSSPT#def#Application.OSSPT#images#Application.OSSPT#temp#Application.OSSPT#acssdel.png"></a>
								&nbsp;<a href="##" onClick="getSearch('#qDataSaveSearch.searchpassing#','#qDataSaveSearch.search_name#',true,'#qDataSaveSearch.seq_id#'); return false;" title="Edit Search Name"><img src="#Application.PATH.LIB##Application.OSSPT#skins#Application.OSSPT#def#Application.OSSPT#images#Application.OSSPT#temp#Application.OSSPT#ico-edit.png"></a>
							</li>					
						</cfloop>	
					<cfelse>
						<li>Empty Data</li>
					</cfif>
				</ul>
			</cfoutput>
		</cffunction>
		
		<cffunction name="getPlanGradeStat"> <!---ENC50616-80432--->
	    	<cfargument name="empid" default="">
	    	<cfargument name="formno" default="">
	    	<cfargument name= "reqno" default="">
	        <cfquery name="local.qGetPlanGradeStat" datasource="#request.sdsn#">
	            SELECT distinct EH.reviewee_grade,EH.reviewee_employcode, GRD.grade_name AS empgrade
	            , ES.employmentstatus_name_#request.scookie.lang# emp_status
	            FROM TPMDPERFORMANCE_EVALH EH
	            LEFT JOIN TEOMJOBGRADE GRD ON GRD.grade_code = EH.reviewee_grade 
	            LEFT JOIN TEOMEMPLOYMENTSTATUS ES ON EH.reviewee_employcode = ES.employmentstatus_code
	            WHERE EH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	            AND EH.form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
	            AND EH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	    	<cfreturn qGetPlanGradeStat>
	    </cffunction>
	    
	    
	    <!---ENC50618-81669--->
		<cffunction name="FilterEvalFormEmployeeFullyApprove">
    		<cfparam name="period_code" default="">
    		<cfparam name="grade_order" default="">
    		<cfparam name="search" default="">
    		<cfparam name="nrow" default="50">
    		
    		<cfparam name="allstatus" default="false">
    		<cfset allstatus=true><!--- TCK1018-81902 --->
    		
    		<cfif val(nrow) eq "0">
    			<cfset local.nrow="50">
    		</cfif>
    		<cfset LOCAL.searchText=trim(search)>
    		<cfset LOCAL.count = 1/>
    
    		<!--- filter employee  [ ENC50917-81121 ]--->
    		<cfparam name="ftpass" default="">
    		<cfset local.lstparams="alldept,work_loc,work_status,cost_center,job_status,job_grade,emp_pos,emp_status,gender,marital,religion,hdnfaoempnolist">
    		<cfif ftpass neq "" AND IsJSON(ftpass)>
    			<cfset local.params=DeserializeJSON(ftpass)>
    			<Cfset local.iidx = "">
    			<cfloop list="#lstparams#" index="iidx">
    				<cfif StructKeyExists(params,iidx)>
    					<cfparam name="#iidx#" default="#params[iidx]#">
    				<cfelse>
    					<cfparam name="#iidx#" default="">
    				</cfif>
    			</cfloop>
    		</cfif>
    
    		<cfif ftpass neq "" AND IsJSON(ftpass) AND isdefined("alldept") AND alldept eq "false">
    			<cfif request.dbdriver eq 'MYSQL'><!--- untuk inclusive --->
    				<cfset LOCAL.cond_dept0=replace(params.dept,",",",%' OR CONCAT(',',e.parent_path,',') LIKE '%,","All")>
    				<cfset LOCAL.cond_dept=PreserveSingleQuotes(LOCAL.cond_dept0)>
    			<cfelse>
    				<cfset LOCAL.cond_dept0=replace(params.dept,",",",%' OR ','#REQUEST.DBSTRCONCAT#e.parent_path#REQUEST.DBSTRCONCAT#',' LIKE '%,","All")>
    				<cfset LOCAL.cond_dept=PreserveSingleQuotes(LOCAL.cond_dept0)>
    			</cfif>
    		<cfelse>
    			<cfset LOCAL.cond_dept="">
    		</cfif>
    		<cfset LOCAL.lsGender="Female,Male">
    		<cfset LOCAL.lsMarital="Single,Married,Widow,Widower,Divorce">
    		<cfset LOCAL.EmpLANG=Application.SFParser.TransMLang(listAppend(lsMarital,lsGender),false,",")>
    		<!--- /filter employee  [ ENC50917-81121 ]--->
    		
    		<!--- Get emp_id fully approved perf plan--->
    		<!--- TCK1810-0479577 - Tidak pakai employee authorization, mengikuti list pef form --->
    		<cfset LOCAL.qListEmpFullyAppr = qGetListEvalFullyDelApproveAndClosed(period_code=period_code)>
    		
			<cfquery name="local.qData" datasource="#request.sdsn#">
				SELECT distinct a.emp_id, full_name, full_name AS emp_name, b.emp_no
				    ,TPMDPERFORMANCE_EVALH.form_no ,TPMMPERIOD.period_name_#request.scookie.lang# AS period_name, TPMDPERFORMANCE_EVALH.reference_date
				FROM TEOMEMPPERSONAL a
				LEFT JOIN TEODEMPCOMPANY b ON a.emp_id = b.emp_id
				LEFT JOIN TCLRGroupMember GM on GM.emp_id = b.emp_id

				LEFT JOIN TEODEMPLOYMENTHISTORY d ON a.emp_id = d.emp_id 

				LEFT JOIN TEOMPOSITION e 
					ON e.position_id = b.position_id 
					AND e.company_id = b.company_id
				LEFT JOIN TEODEmppersonal f 
					ON f.emp_id = b.emp_id 
					
				LEFT JOIN TPMDPERFORMANCE_EVALH
				    ON TPMDPERFORMANCE_EVALH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
				    AND a.emp_id = TPMDPERFORMANCE_EVALH.reviewee_empid
				    <cfif allstatus EQ false>
				        AND TPMDPERFORMANCE_EVALH.isfinal = 1
				    </cfif>
				    AND TPMDPERFORMANCE_EVALH.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
					
                LEFT JOIN TCLTREQUEST
                	ON TCLTREQUEST.req_no = TPMDPERFORMANCE_EVALH.request_no
                	AND TCLTREQUEST.req_no IS NOT NULL
                	
                LEFT JOIN TPMMPERIOD
                    ON TPMMPERIOD.period_code = TPMDPERFORMANCE_EVALH.period_code

				WHERE b.company_id = #REQUEST.SCookie.COID#
			    AND a.emp_id IN (<cfqueryparam value="#ValueList(qListEmpFullyAppr.emp_id)#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
	
	            <!------>
                    AND TPMDPERFORMANCE_EVALH.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
                    AND b.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
    
                    <cfif allstatus EQ true>
                	    AND TCLTREQUEST.status <> 5 AND TCLTREQUEST.status <> 8 <!--- 5=Rejected,8=Cancelled. All status except Cancelled and reject --->
                    <cfelse>
                    	AND (TCLTREQUEST.status = 3 OR TCLTREQUEST.status = 9) <!--- 3=Fully Approved, 9=Closed --->
                    	AND TPMDPERFORMANCE_EVALH.isfinal = 1
                    </cfif>
    
            	    AND TPMDPERFORMANCE_EVALH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
	            <!------>

				<cfif grade_order neq "">
					<cfset grade_order = replace(grade_order,",","','","ALL")/>
					AND b.grade_code IN ('#grade_order#')
				</cfif>

				<cfif len(searchText)>
					AND
					(
						a.Full_Name LIKE '%#searchText#%'
						OR b.emp_no Like '%#searchText#%'
					)
				</cfif>

				<cfif ftpass neq "" AND IsJSON(ftpass)>
					<cfif isdefined("alldept") AND alldept eq "false"> 
						AND
						<cfif params.inclusive eq "false">
							<cfset local.where_dept="(e.parent_id = " & replace(params.dept,","," OR e.parent_id = ","All") & " OR e.dept_id = " & replace(params.dept,","," OR e.dept_id = ","All") & ")">
							#where_dept#					   
						<cfelse>
							<cfif request.dbdriver eq 'MYSQL'>
								(CONCAT(',',e.parent_path,',') LIKE '%,#PreserveSingleQuotes(LOCAL.cond_dept)#,%')
							<cfelse>
								(','#REQUEST.DBSTRCONCAT#e.parent_path#REQUEST.DBSTRCONCAT#',' LIKE '%,#PreserveSingleQuotes(LOCAL.cond_dept)#,%')
							</cfif>
						</cfif>
						
					</cfif>
					<cfif isdefined("work_loc") AND len(work_loc)>
						AND b.work_location_code in (<cfqueryparam value="#work_loc#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(work_status) and work_status eq "1">
						<cfif request.dbdriver eq "MSSQL">
						 AND (b.end_date >= getdate() OR b.end_date IS NULL)
						 <cfelseif request.dbdriver eq "MYSQL">
						 AND (b.end_date >= NOW() OR b.end_date IS NULL)
						 </cfif>
					<cfelseif len(work_status) and work_status eq "0">
						<cfif request.dbdriver eq "MSSQL">
						 AND (b.end_date < getdate() AND b.end_date IS NOT NULL)
						 <cfelseif request.dbdriver eq "MYSQL">
						 AND (b.end_date < NOW() AND b.end_date IS NOT NULL)
						 </cfif>
					</cfif>
					<cfif isdefined("cost_center") AND len(cost_center)>
						AND b.cost_code IN (<cfqueryparam value="#cost_center#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif isdefined("job_status") AND len(job_status)>
						AND b.job_status_code IN (<cfqueryparam value="#job_status#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif isdefined("job_grade") AND len(job_grade)>
						AND b.grade_code IN (<cfqueryparam value="#job_grade#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(emp_pos)>
						AND b.position_id IN (<cfqueryparam value="#emp_pos#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(emp_status)>
						AND b.employ_code IN (<cfqueryparam value="#emp_status#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<!---Personal_Information--->
					<cfif len(gender) and gender neq "2">
						#APPLICATION.SFUtil.getLookupQueryPart("gender",gender,"0=Female|1=Male",0,"AND")#
					</cfif>
					<cfif len(marital)>
						AND f.maritalstatus = <cfqueryparam value="#marital#" cfsqltype="CF_SQL_INTEGER">
					</cfif>
					<cfif len(religion)>
						AND f.religion_code IN (<cfqueryparam value="#religion#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<!--- Filter Employeeno --->
					<cfif len(trim(hdnfaoempnolist))>
                        AND (#Application.SFUtil.CutList(ListQualify(hdnfaoempnolist,"'")," b.emp_no IN  ","OR",2)#)
                    </cfif>
                    <!--- Filter Employeeno --->
                <cfelse>
                    <!--- default employee aktif --->
					<cfif request.dbdriver eq "MSSQL">
					 AND (b.end_date >= getdate() OR b.end_date IS NULL)
					 <cfelseif request.dbdriver eq "MYSQL">
					 AND (b.end_date >= NOW() OR b.end_date IS NULL)
					 </cfif>
                    <!--- default employee aktif --->
				</cfif>
				<!---Filter:Employee_Information  [ ENC50917-81121 ]--->

				ORDER BY full_name	
			</cfquery>
		
			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSEmployee",true,"+")>
			<cfset LOCAL.vResult="">
			<cfloop query="qData">
			    <cfset vResult=vResult & "
				arrEntryList[#currentrow-1#]=""#JSStringFormat(form_no & "=" & emp_name & " [#emp_no#]")#"";">
			</cfloop>
			<cfoutput>
			    <cfset LOCAL.SFLANG1=Application.SFParser.TransMLang("NotAvailable",true,"+")>
				<script>
				    arrEntryList=new Array();
					document.getElementById('lbl_inp_form_no').innerHTML  = '#SFLANG# (#qData.recordcount#) <span class=\"required\">*</span>';
					$('[id=tr_inp_period_date] > [id=tdb_1]').html('#SFLANG1#');
    				<cfif len(vResult)>
    					#vResult#
    					document.getElementById('unselinp_form_no').value = '#valuelist(qData.emp_id)#'; 
    				    $('[id=tr_inp_period_date] > [id=tdb_1]').html('#DateFormat(qData.reference_date,REQUEST.config.DATE_OUTPUT_FORMAT)#');
    				</cfif>
			    </script>
			</cfoutput>
		</cffunction>
	    
	    	<cffunction name="qGetListEvalFullyDelApproveAndClosed">
			<cfparam name="period_code" default="">
			<cfparam name="lst_emp_id" default="">
			<cfparam name="is_emp_defined" default="N">
			<cfparam name="by_form_no" default="N">
			<cfparam name="form_no" default="">
			
			<cfparam name="allstatus" default="false"><!---TCK1018-81902--->
			
			<!--- Get emp_id fully approved perf plan--->
	        <cfoutput>
	        <cf_sfqueryemp name="LOCAL.qListEmpFullyApprClosed" dsn="#REQUEST.SDSN#"  ACCESSCODE="hrm.performance">
		
	            SELECT 
	            	DISTINCT
	            	TPMDPERFORMANCE_EVALH.form_no, 
	            	TPMDPERFORMANCE_EVALH.request_no, 
	            	TPMDPERFORMANCE_EVALH.period_code,
	            	TPMDPERFORMANCE_EVALH.reviewee_empid,
	            	TPMDPERFORMANCE_EVALH.reference_date
	            	
	            	,TCLTREQUEST.reqemp
	            	,TEOMEMPPERSONAL.full_name
	            	,TEODEMPCOMPANY.emp_no
	            	,TEODEMPCOMPANY.emp_id
	            	,TEOMPOSITION.pos_name_#request.scookie.lang# AS pos_name
	            	,ORG.pos_name_#request.scookie.lang# AS orgunit
	            	,TEOMJOBGRADE.grade_name
	            	
	            	,TPMMPERIOD.period_name_#request.scookie.lang# AS period_name
	            	
	            FROM TPMDPERFORMANCE_EVALH
	            
	            LEFT JOIN TCLTREQUEST
	            	ON TCLTREQUEST.req_no = TPMDPERFORMANCE_EVALH.request_no
	            	AND TCLTREQUEST.req_no IS NOT NULL
	            
	            LEFT JOIN TEOMEMPPERSONAL
	            	ON TEOMEMPPERSONAL.emp_id = TPMDPERFORMANCE_EVALH.reviewee_empid
	            	
	            LEFT JOIN TEODEMPCOMPANY 
	                ON TEODEMPCOMPANY.emp_id = TPMDPERFORMANCE_EVALH.reviewee_empid
	                
	            LEFT JOIN TEOMPOSITION
	                ON TEOMPOSITION.position_id = TEODEMPCOMPANY.position_id 

	            LEFT JOIN TEOMPOSITION ORG 
	                ON ORG.position_id = TEOMPOSITION.dept_id
	                
	            LEFT JOIN TPMMPERIOD 
	                ON TPMMPERIOD.period_code = TPMDPERFORMANCE_EVALH.period_code 
	                
	                    
	            LEFT JOIN TEOMJOBGRADE 
	                ON TEODEMPCOMPANY.grade_code = TEOMJOBGRADE.grade_code 
	                AND TEODEMPCOMPANY.company_id = TEOMJOBGRADE.company_id 
	                    	
	            WHERE TCLTREQUEST.req_no IS NOT NULL
	                AND TPMDPERFORMANCE_EVALH.company_code = <cf_sfqparamemp value="#REQUEST.SCOOKIE.COCODE#" type="cf_sql_varchar">
	                AND TEODEMPCOMPANY.company_id = <cf_sfqparamemp value="#REQUEST.SCOOKIE.COID#" type="cf_sql_varchar">
	            
                    <cfif allstatus EQ true>
                	    AND TCLTREQUEST.status <> 5 AND TCLTREQUEST.status <> 8 <!--- 5=Rejected,8=Cancelled. All status except Cancelled and reject --->
                    <cfelse>
    	            	AND (TCLTREQUEST.status = 3 OR TCLTREQUEST.status = 9) <!--- 3=Fully Approved, 9=Closed --->
    	            	AND TPMDPERFORMANCE_EVALH.isfinal = 1
                    </cfif>
	            	
	            	<cfif by_form_no EQ 'Y'>
	            	    AND TPMDPERFORMANCE_EVALH.form_no IN (<cf_sfqparamemp value="#form_no#" type="cf_sql_varchar" list="yes">)
	            	<cfelse>
	            	    AND TPMDPERFORMANCE_EVALH.period_code = <cf_sfqparamemp value="#period_code#" type="cf_sql_varchar">
	            	</cfif>
	            	
	            	<cfif is_emp_defined eq 'Y'>
	            	    AND TPMDPERFORMANCE_EVALH.reviewee_empid IN (<cf_sfqparamemp value="#lst_emp_id#" type="cf_sql_varchar" list="yes">)
	            	</cfif>
	            	
	            ORDER BY full_name
			</cf_sfqueryemp>
		    </cfoutput>
			<!--- Get emp_id fully approved perf plan--->
			<cfreturn qListEmpFullyApprClosed>
		</cffunction>
		
	    
		<cffunction name="FilterEvalFormFullyApprove">
			<cfparam name="period_code" default="">
			<cfparam name="search" default="">
			<cfparam name="nrow" default="50">
			
			<cfif val(nrow) eq "0">
				<cfset local.nrow="50">
			</cfif>
			<cfset LOCAL.searchText=trim(search)>
			<cfset LOCAL.count = 1/>

			<!--- Get emp_id fully approved perf plan--->
			<cfset LOCAL.qListEmpFullyAppr = qGetListEvalFullyApproveAndClosed(period_code=period_code)>
			<!--- Get emp_id fully approved perf plan--->
	        <cfquery name="LOCAL.qData" dbtype="query">
	            SELECT * FROM qListEmpFullyAppr
	            WHERE 1=1
				<cfif len(searchText)>
					AND
					(
						form_no LIKE '%#searchText#%'
					)
				</cfif>
	        </cfquery>
	        

			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("FDFormNo",true,"+")>
			<cfset LOCAL.vResult="">
			<cfloop query="qData">
			    <cfset vResult=vResult & "
				arrEntryList[#currentrow-1#]=""#JSStringFormat(form_no & "=" & form_no & "")#"";">
			</cfloop>
			<cfoutput>
			   
				<script>
				    arrEntryList=new Array();
					document.getElementById('lbl_inp_form_no').innerHTML  = '#SFLANG# (#qData.recordcount#) <span class=\"required\">*</span>';
					<cfif len(vResult)>
						#vResult#
						document.getElementById('unselinp_form_no').value = '#valuelist(qData.form_no)#'; 
					</cfif>
			    </script>
			</cfoutput>
		</cffunction>
	    
		<cffunction name="qGetListEvalFullyApproveAndClosed">
			<cfparam name="period_code" default="">
			<cfparam name="lst_emp_id" default="">
			<cfparam name="is_emp_defined" default="N">
			<cfparam name="by_form_no" default="N">
			<cfparam name="form_no" default="">
			
			<cfparam name="allstatus" default="false"><!---TCK1018-81902--->
			
			<!--- Get emp_id fully approved perf plan--->
			<cfquery name="local.qListEmpFullyApprClosed" datasource="#request.sdsn#">
	            SELECT 
	            	DISTINCT
	            	TPMDPERFORMANCE_EVALH.form_no, 
	            	TPMDPERFORMANCE_EVALH.request_no, 
	            	TPMDPERFORMANCE_EVALH.period_code,
	            	TPMDPERFORMANCE_EVALH.reviewee_empid,
	            	TPMDPERFORMANCE_EVALH.reference_date
	            	
	            	,TCLTREQUEST.reqemp
	            	,TEOMEMPPERSONAL.full_name
	            	,TEODEMPCOMPANY.emp_no
	            	
	            	,TEOMPOSITION.pos_name_#request.scookie.lang# AS pos_name
	            	,ORG.pos_name_#request.scookie.lang# AS orgunit
	            	,TEOMJOBGRADE.grade_name
	            	
	            	,TPMMPERIOD.period_name_#request.scookie.lang# AS period_name
	            	
	            FROM TPMDPERFORMANCE_EVALH
	            
	            LEFT JOIN TCLTREQUEST
	            	ON TCLTREQUEST.req_no = TPMDPERFORMANCE_EVALH.request_no
	            	AND TCLTREQUEST.req_no IS NOT NULL
	            
	            LEFT JOIN TEOMEMPPERSONAL
	            	ON TEOMEMPPERSONAL.emp_id = TPMDPERFORMANCE_EVALH.reviewee_empid
	            	
	            LEFT JOIN TEODEMPCOMPANY 
	                ON TEODEMPCOMPANY.emp_id = TPMDPERFORMANCE_EVALH.reviewee_empid
	                
	            LEFT JOIN TEOMPOSITION
	                ON TEOMPOSITION.position_id = TEODEMPCOMPANY.position_id 

	            LEFT JOIN TEOMPOSITION ORG 
	                ON ORG.position_id = TEOMPOSITION.dept_id
	                
	            LEFT JOIN TPMMPERIOD 
	                ON TPMMPERIOD.period_code = TPMDPERFORMANCE_EVALH.period_code 
	                
	                    
	            LEFT JOIN TEOMJOBGRADE 
	                ON TEODEMPCOMPANY.grade_code = TEOMJOBGRADE.grade_code 
	                AND TEODEMPCOMPANY.company_id = TEOMJOBGRADE.company_id 
	                    	
	            WHERE TCLTREQUEST.req_no IS NOT NULL
	                AND TPMDPERFORMANCE_EVALH.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
	                AND TEODEMPCOMPANY.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
	            
                    <cfif allstatus EQ true>
                	    AND TCLTREQUEST.status <> 5 AND TCLTREQUEST.status <> 8 <!--- 5=Rejected,8=Cancelled. All status except Cancelled and reject --->
                    <cfelse>
    	            	AND (TCLTREQUEST.status = 3 OR TCLTREQUEST.status = 9) <!--- 3=Fully Approved, 9=Closed --->
    	            	AND TPMDPERFORMANCE_EVALH.isfinal = 1
                    </cfif>
	            	
	            	<cfif by_form_no EQ 'Y'>
	            	    AND TPMDPERFORMANCE_EVALH.form_no IN (<cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar" list="yes">)
	            	<cfelse>
	            	    AND TPMDPERFORMANCE_EVALH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
	            	</cfif>
	            	
	            	<cfif is_emp_defined eq 'Y'>
	            	    AND TPMDPERFORMANCE_EVALH.reviewee_empid IN (<cfqueryparam value="#lst_emp_id#" cfsqltype="cf_sql_varchar" list="yes">)
	            	</cfif>
	            	
	            ORDER BY TEOMEMPPERSONAL.full_name
			</cfquery>
			<!--- Get emp_id fully approved perf plan--->
			<cfreturn qListEmpFullyApprClosed>
		</cffunction>
		
		<cffunction name="DeleteEvaluationForm">
		    <cfparam name="lstdelete" default="">
		    
		    <cfset LOCAL.objPerfPlan = CreateObject("component","SFPerformancePlanning")/>
		    
		    <cfloop list="#lstdelete#" index="LOCAL.form_no">
				<!--- Delete all data from Evaluation --->
				<cfset LOCAL.retvarDelPerfEval = objPerfPlan.DeleteAllPerfEvalByFormNo(form_no=form_no)>
				<!--- Delete all data from Evaluation --->
                
		    </cfloop>
		    
	        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Delete Performance Evaluation",true)>
			<cfif retvarDelPerfEval eq false>
			    <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed Delete Performance Evaluation",true)>
			</cfif>
		    
			<cfoutput>
				<script>
					alert("#SFLANG#");
					this.reloadPage();
				</script>
			</cfoutput>
		</cffunction> 
		
		<cffunction name="DeleteDetailPerfEval">
		    <cfparam name="formno" default="">
		    
		    <cfset LOCAL.objPerfPlan = CreateObject("component","SFPerformancePlanning")/>
		    <cfset LOCAL.retvarDelPerfEval = objPerfPlan.DeleteAllPerfEvalByFormNo(form_no=formno)>
		    
	        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Delete Performance Evaluation",true)>
			<cfif retvarDelPerfEval eq false>
			    <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed Delete Performance Evaluation",true)>
			</cfif>
			<cfoutput>
				<script>
					alert("#SFLANG#");
					top.popClose();
					if(top.opener){
						top.opener.reloadPage();
					}
				</script>
			</cfoutput>
		</cffunction>
	    <!---ENC50618-81669--->
		
		
		<cffunction name="GetReviewerListPerReviewee">
			<cfargument name="reviewee_empid" default="false">
			<cfargument name="period_code" default="false">
			<cfset appcode = "PERFORMANCE.EVALUATION">
			<cfset fixedLstApp = "">
			<cfif structkeyexists(REQUEST,"SHOWCOLUMNGENERATEPERIOD")>
				<cfset local.ReturnVarCheckCompParam = REQUEST.SHOWCOLUMNGENERATEPERIOD>
			<cfelse>
				<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
			</cfif>
			<cfif ReturnVarCheckCompParam EQ false>
				<cfquery name="qGetDtTrans" datasource="#request.sdsn#">
					select approval_data  from tcltrequest where req_no in (select request_no from tpmdperformance_evalh where reviewee_empid = '#arguments.reviewee_empid#' 
					and period_code = '#arguments.period_code#' and company_code = '#REQUEST.SCOOKIE.COCODE#')
				</cfquery>
				<cfif qGetDtTrans.recordcount gt 0>
					<cfset local.objWDApproval=SFReqFormat(qGetDtTrans.approval_data,"R",[])>
				<cfelse>
					<cfset strctApproverData = objRequestApproval.Generate(appcode, arguments.reviewee_empid, arguments.reviewee_empid, "-") />
					<cfset local.objWDApproval = strctApproverData.WDAPPROVAL>
				</cfif>
				<cfset tempListSharedReviewer = "">
				<cfset fixedLstApp = arguments.reviewee_empid>
				 <cfloop index="idxLoop1" from="1" to="#ArrayLen(objWDApproval)#">
				 
					<cfset structLoop1 = objWDApproval[idxLoop1]>
					<cfset structLoop1Approver = objWDApproval[idxLoop1].approver>
					<cfif ArrayLen(structLoop1Approver) eq 1>
						<cfset structLoop2Approver = structLoop1Approver[1]>
						<cfset isiStructAppEmpID = structLoop2Approver[1].emp_id>
						<cfif ListFindNoCase(fixedLstApp,isiStructAppEmpID,",") eq 0>
							<cfset fixedLstApp = ListAppend(fixedLstApp,isiStructAppEmpID)>
						</cfif>
					<cfelse>
						<cfloop index="local.idxLoop2" from="1" to="#ArrayLen(structLoop1Approver)#">
							<cfset structLoop2Approver = structLoop1Approver[idxLoop2]>	
							<cfloop index="local.idxLoop3" from="1" to="#ArrayLen(structLoop2Approver)#">
								<cfset isiStructAppEmpID = structLoop2Approver[idxLoop3].emp_id>
								<cfif ListFindNoCase(tempListSharedReviewer,isiStructAppEmpID,"|") eq 0>
									<cfset tempListSharedReviewer = ListAppend(tempListSharedReviewer,isiStructAppEmpID,"|")>		
								</cfif>	
							</cfloop>
							<cfif ListFindNoCase(fixedLstApp,tempListSharedReviewer,",") eq 0 AND ListLen(tempListSharedReviewer,"|") gt 1>
								<cfset fixedLstApp  = ListAppend(fixedLstApp,tempListSharedReviewer,",")>
							</cfif> 
						</cfloop>
					</cfif>
				 
				 </cfloop>
			<cfelse>
				<cfquery name="local.qListAppAll" datasource="#request.sdsn#">
					select reviewer_empid,review_step from tpmdperformance_evalgen where reviewee_empid = '#arguments.reviewee_empid#' 
					and period_code = '#arguments.period_code#' and company_id = #REQUEST.SCOOKIE.COID#
					order by review_step 
				</cfquery>
				<cfquery name="local.qListAppAllReviewStep" datasource="#request.sdsn#">
					select distinct review_step from tpmdperformance_evalgen where reviewee_empid = '#arguments.reviewee_empid#' 
					and period_code = '#arguments.period_code#' and company_id = #REQUEST.SCOOKIE.COID#
					order by review_step 
				</cfquery>
				<cfif qListAppAll.recordcount gt 0>
					<cfloop query="qListAppAllReviewStep">
						<cfset tempFixedLstApp = "">
						<cfquery name="local.qListAppAllLocal" dbtype="query">
						 select reviewer_empid from qListAppAll where review_step = #qListAppAllReviewStep.review_step# order by review_step
						</cfquery>
						<cfif qListAppAllLocal.recordcount gt 0>
							<cfset tempFixedLstApp = ValueList(qListAppAllLocal.reviewer_empid,"|")>
						</cfif>
						<cfset fixedLstApp = ListAppend(fixedLstApp,tempFixedLstApp,",")>
					</cfloop>
				</cfif>
				
			</cfif>
			
			<cfreturn fixedLstApp>
		</cffunction>
		<cffunction name="getApproverStep">
			<cfargument name="reviewee_empid" default="false">
			<cfargument name="reviewer_empid" default="false">
			<cfargument name="period_code" default="false">
			<cfset rvwr_empstep = 0>
			<cfset tempGetRevwrLstPerRviewee = GetReviewerListPerReviewee(reviewee_empid=arguments.reviewee_empid,period_code=arguments.period_code)>
			<cfloop list="#tempGetRevwrLstPerRviewee#" index="idxRvwr" delimiters=",">
				<cfset rvwr_empstep  = rvwr_empstep + 1>
				<cfif ListLen(idxRvwr,"|") eq 1>
					<cfif arguments.reviewer_empid eq idxRvwr>
						<cfbreak>
					</cfif>
				<cfelseif ListLen(idxRvwr,"|") gt 1>
				    <cfset LOCAL.gotIdApprover = 0>
					<cfloop list="#idxRvwr#" index="idxRvwrShared" delimiters="|">
						<cfif arguments.reviewer_empid eq idxRvwrShared>
						    <cfset gotIdApprover = 1>
						</cfif>
					</cfloop>
					<cfif gotIdApprover EQ 1>
						<cfbreak>
					</cfif>
				</cfif>
			</cfloop>
			<cfreturn rvwr_empstep>
		</cffunction>
		
		
    	<!---- start : these functions are used in New Layout Performance Evaluation Form ---->
		<cffunction name="getDetailFormBasedOnLibCode">
			<cfargument name="formno" default="">
			<cfargument name="reqno" default="">
			<cfquery name="local.qDetailFrmPerReviewer" datasource="#request.sdsn#">
				SELECT TPMDPERFORMANCE_EVALH.head_status, lib_code libcode, TEOMEMPPERSONAL.full_name, weight, target, lib_name_#request.scookie.lang# libname, 
				notes, photo, gender, TPMDPERFORMANCE_EVALD.reviewer_empid,  lib_desc_#request.scookie.lang# libdesc, achievement_type, TGEMSCORE.score_desc
				,TPMDPERFORMANCE_EVALH.isfinal,TPMDPERFORMANCE_EVALH.review_step,TPMDPERFORMANCE_EVALD.reviewer_empid
				FROM TPMDPERFORMANCE_EVALD 
				INNER JOIN TPMDPERFORMANCE_EVALH ON TPMDPERFORMANCE_EVALD.form_no = TPMDPERFORMANCE_EVALH.form_no AND TPMDPERFORMANCE_EVALD.reviewer_empid = TPMDPERFORMANCE_EVALH.reviewer_empid
				INNER JOIN TEOMEMPPERSONAL ON TPMDPERFORMANCE_EVALD.reviewer_empid = TEOMEMPPERSONAL.emp_id
				INNER JOIN TGEMSCORE ON TGEMSCORE.score_code = TPMDPERFORMANCE_EVALD.achievement_type
				WHERE TPMDPERFORMANCE_EVALD.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
				AND TPMDPERFORMANCE_EVALD.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODe#" cfsqltype="cf_sql_varchar">
				AND TPMDPERFORMANCE_EVALH.request_no =  <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
				ORDER BY TPMDPERFORMANCE_EVALH.review_step 
			</cfquery>
			<cfreturn qDetailFrmPerReviewer>
		</cffunction>
		<cffunction name="getSavedFormEvalH">
			<cfargument name="periodcode" default="">
			<cfargument name="reviewee_empid" default="">
			<cfquery name="local.qGetSavedFormEvalH" datasource="#request.sdsn#">
				select reviewer_empid, head_status,review_step , form_no, request_no, isfinal,lastreviewer_empid, modified_date, created_date,modified_by,reviewee_empid
				FROM tpmdperformance_evalh where 
				period_code= <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
				and company_code= <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
				and reviewee_empid = <cfqueryparam value="#arguments.reviewee_empid#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfreturn qGetSavedFormEvalH>
		</cffunction>
		<cffunction name="getPeriodComponent">
			<cfargument name="periodcode" default="">
			<cfquery name="local.qGetPeriodInfo" datasource="#request.sdsn#">
				select component_code,weight, tpmmperiod.score_type,tpmmperiod.conclusion_lookup,TPMMLOOKUP.lookup_code is_usinglookup from tpmdperiodcomponent 
				inner join tpmmperiod ON 
				    tpmdperiodcomponent.period_code = tpmmperiod.period_code 
				    AND tpmdperiodcomponent.company_code = tpmmperiod.company_code
				LEFT JOIN TPMMLOOKUP  <!---alv TCK1912-0536137 New Layout--->
					ON TPMDPERIODCOMPONENT.lookup_code = TPMMLOOKUP.lookup_code
					AND TPMDPERIODCOMPONENT.period_code = TPMMLOOKUP.period_code
				where tpmdperiodcomponent.period_code= <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
				and tpmdperiodcomponent.company_code= <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfreturn qGetPeriodInfo>
		</cffunction>
		<cffunction name="SaveEvaluationForm">
			 <cfparam name="period_code" default="">
			 <cfparam name="reference_date" default="">
			 <cfparam name="request_no" default="">
			 <cfparam name="formno" default="">
			 <cfparam name="coid" default="">
			 <cfparam name="cocode" default="">
			 <cfparam name="planformno" default="">
			 <cfparam name="listPeriodComponentUsed" default="">
			 <cfparam name="reqformulaorder" default="">
			 <cfparam name="RevieweeAsApprover" default="">
			 <cfparam name="UserInReviewStep" default="">
			 <cfparam name="FullListAppr" default="">
			 <cfparam name="score" default="">
			 <cfparam name="conclusion" default="">
			 <cfparam name="requestfor" default="">
			 <cfparam name="orgKPIArray" default="">
			 <cfparam name="orgKPI_lib" default="">
			 <cfparam name="persKPIArray" default="">
			 <cfparam name="persKPI_lib" default="">
			 <cfparam name="appraisalArray" default="">
			 <cfparam name="appraisal_lib" default="">
			 <cfparam name="competencyArray" default="">
			 <cfparam name="competency_lib" default="">
			 <cfparam name="appraisal" default="">
			 <cfparam name="appraisal_weight" default="">
			 <cfparam name="appraisal_weighted" default="">
			 <cfparam name="appraisal_totallookup" default="">
			 <cfparam name="appraisal_totallookupSc" default="">
			 <cfparam name="competency" default="">
			 <cfparam name="competency_weight" default="">
			 <cfparam name="competency_weighted" default="">
			 <cfparam name="task" default="">
			 <cfparam name="task_weight" default="">
			 <cfparam name="task_weighted" default="">
			 <cfparam name="feedback" default="">
			 <cfparam name="feedback_weight" default="">
			 <cfparam name="feedback_weighted" default="">
			 <cfparam name="objectiveorg" default="">
			 <cfparam name="objectiveorg_weight" default="">
			 <cfparam name="objective_totallookupSc" default="">
			 <cfparam name="action" default=""> 
			 <cfparam name="sendtype" default=""> 
			 
			 <cfif structkeyexists(REQUEST,"SHOWCOLUMNGENERATEPERIOD")>
				<cfset local.ReturnVarCheckCompParam = REQUEST.SHOWCOLUMNGENERATEPERIOD>
			<cfelse>
				<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
			</cfif>
			
			
			<cfif not structkeyexists(FORM,"persKPIArray")>

			<cfelse>
				<cfset FORM.persKPIArray = Replace(FORM.persKPIArray, "\r\n", " ","all")>
			</cfif>
			<cfif not structkeyexists(FORM,"competencyArray")>

			<cfelse>
				<cfset FORM.competencyArray = Replace(FORM.competencyArray, "\r\n", " ","all")>
			</cfif>
			
			<cfif ReturnVarCheckCompParam EQ false>
				
				<cfif request_no eq "">
					  <cfset local.retvarsfbp = SUPER.Add(true,true,FORM) />  
					  
				<cfelse>
					<cfset local.retvarsfbp = SUPER.Save(true,true,FORM) />  
					
				</cfif>
				
				<cfif retvarsfbp.result neq false>
					<cfquery name="local.qGetFormNo" datasource="#request.sdsn#">
						select form_no from tpmdperformance_evalh
						where period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar"> 
						and company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
						and request_no =  <cfqueryparam value="#retvarsfbp.REQUESTNO#" cfsqltype="cf_sql_varchar">
					</cfquery>
					
					<cfscript>
						data = {"success"="1","request_no"="#retvarsfbp.REQUESTNO#","form_no"="#qGetFormNo.form_no#"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				<cfelse>
					<cfscript>
						data = {"success"="0","MSG"="#retvarsfbp.message#"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
			
			<cfelseif ReturnVarCheckCompParam EQ true AND request_no neq "">   <!--- this is pregenerate mode , and request_no shouldn't null  ----->
			
				<cfset callSendToNext = SendToNext()>
			
			</cfif>
			 
			
		</cffunction>
		
		
		
		
		<cffunction name="SaveAdditionalNotes">
			 <cfparam name="request_no" default="">
			 <cfparam name="formno" default="">
			 <cfparam name="period_code" default="">
			 <cfparam name="evalnoterecords" default="">
			 <cfparam name="sendtype" default="0">
			 
			 <cfquery name="local.qCheckPosID" datasource="#request.sdsn#">
			 select position_id from teodempcompany where 
			 is_main=1 and company_id = #REQUEST.SCOOKIE.COID# and status=1
			 and emp_id = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar"> 
			 </cfquery>
			<cfquery name="local.qCheckNotes" datasource="#request.sdsn#">
				delete from TPMDPERFORMANCE_EVALNOTE where form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
				and reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
				and company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfloop from="1" to="#evalnoterecords#" index="local.idx">
				<cfset local.note_name = Evaluate("evalnotename_#idx#")>
				<cfset local.note_answer =  Evaluate("evalnote_#idx#")>
				<cfif qCheckPosID.recordcount gt 0 and Trim(note_answer) neq "">
					<cfquery name="local.qInsertAddNotes" datasource="#request.sdsn#">
						INSERT INTO TPMDPERFORMANCE_EVALNOTE (form_no,company_code,reviewer_empid,reviewer_posid,note_name,note_answer,note_order,created_by,created_date,modified_by,modified_date) 
						VALUES(
							<cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#qCheckPosID.position_id#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#note_name#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#note_answer#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#idx#" cfsqltype="cf_sql_integer">,
							<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
							<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
						)				
					</cfquery>
				</cfif>
				
			</cfloop>
			
			<!---Untuk Revise--->
			<cfif sendtype EQ 'revise'>
			    <cfset Revise()>
				<cf_sfabort>
			</cfif>
			<!---/Untuk Revise--->
			
			<cfset callSendToNext = SendToNext()>
			<!---<cfscript>
				data = {"success"="1","request_no"="#request_no#","form_no"="#formno#"};
			</cfscript>
			<cfoutput>
				#SerializeJSON(data)#
			</cfoutput>---->
		</cffunction>
		<!---- end : these functions are used in New Layout Performance Evaluation Form ---->
		
		
		<!--- 360  ---->
		
		<cffunction name="checkanyquestion">
		    <cfquery name="local.qGetListing" datasource="#request.sdsn#">
		        select count(*) ada
		        from TPMD360RATER
		        where rater_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
		        and UPPER(status) = 'NEW'
		    </cfquery>
		    
		    <cfset data = {isany = #qGetListing.ada#}>
		    <cfset serializedStr = serializeJSON(data)>
            <CFOUTPUT>
                #serializedStr#
            </CFOUTPUT>
		    
		</cffunction>
		
		<cffunction name="listingquestion">
			<!--- Passing Parameter --->
            <cfset LOCAL.scParam=paramRequest()>
            <!--- Query Field Definition --->
            <cfset local.lsfield="b.PERIOD_code, b.ratercode, e.period_name_#request.scookie.lang# period_name, c.full_name reviewee_name, 
            f.position_id, g.pos_name_#request.scookie.lang# position_reviewee, b.reviewee_empid, 
            h.pos_name_#request.scookie.lang# unit, k.full_name assigned_by, b.created_date:date, b.status, e.reference_date:date,b.created_date,b.modified_date">
            <!--- Table Join Definition --->
            <cfset LOCAL.lsTable= "TPMD360RATER b
                left join TEOMEMPPERSONAL c on b.reviewee_empid = c.emp_id
                left JOIN TEOMEMPPERSONAL D ON B.RATER_EMPID = D.EMP_ID
                left join TPMMPERIOD e on b.period_code = e.period_code
                left join TEODEMPCOMPANY f on c.emp_id = f.emp_id and f.company_id = #REQUEST.SCOOKIE.COid# 
                left join TEOMPOSITION g on g.position_id = f.position_id and g.company_id = #REQUEST.SCOOKIE.COid#
                left join TEOMPOSITION h on g.dept_id = h.position_id
                left join TEOMEMPPERSONAL i on b.assigned_by = i.emp_Id
                left join TCLMUSER j on b.created_by = j.user_name
                left join TEOMEMPPERSONAL k on j.user_id = k.user_id">
            <!---<cfset LOCAL.lsFilter=" (a.isfinal = 0 or a.isfinal is null)">--->
            <cfset LOCAL.lsFilter= "1 =1 ">
            <cfset local.lsFilter=lsFilter & " AND e.COMPANY_CODE = '#REQUEST.SCOOKIE.COcode#' and b.rater_empid = '#request.scookie.user.empid#'">
            <cfset ListingData(scParam,{fsort="b.created_date desc, b.modified_date asc",lsField=lsField,lsFilter=lsFilter,lsTable=lsTable,pid="ratercode,PERIOD_code"})>
		</cffunction>
		
		<!--- SAVE 360 ANSWER --->
		<cffunction name="saveanswer">
		    
		    <cfparam name="ratercode" default="">
		    <cfparam name="questioncode" default="">
		    <cfparam name="COUNTQUESTION" default=0>
		    <cfparam name="typesubmit" default="SUBMITTED">
		    <cfparam name="action" default="submit">
		    
		    <cfif LCASE(action) neq "submit">
		        <cfset typesubmit = "DRAFT">
		    </cfif>
		    
		    <cfset issuccess=true>
		    
		    <!---variable for question score--->
		    <cfset totalScore = 0>
		    <cfset isUsingScore = false>
		    <cfset totalQuestionTypeScore = 0>
		    <!---variable for question score--->
		    
		    
		    <cfloop from="1" to="#COUNTQUESTION#" index="idx">
		        <cfset questioncode = evaluate("hdnquestion_#idx#")>
		        <cfset ratercode = evaluate("hdnrater_#idx#")>
		        <cfset answer = evaluate("ANSQ_#idx#")>
    		        
                <!---Cek Is using score--->
                <cfquery name="qGetDetailQuestion" datasource="#request.sdsn#">
                    SELECT questioncode,answer_type FROM TPMD360QUESTION 
                    WHERE questioncode = <cfqueryparam value="#questioncode#" cfsqltype="cf_sql_varchar">
                </cfquery>
                <!---Cek Is using score--->
		        
		        <cftransaction>
    		        <cftry>
    		        
    		            <!--- DELETE TABLE ANSWER --->
            		    <cfquery name="qdELAnswer" datasource="#request.sdsn#">
            		        DELETE FROM TPMD360ANSWER
            		        where ratercode = <cfqueryparam value="#ratercode#" cfsqltype="cf_sql_varchar">
            		        and questioncode = <cfqueryparam value="#questioncode#" cfsqltype="cf_sql_varchar">
            		    </CFQUERY>
    		        
        		        <cfquery name="qInstAnswer" datasource="#request.sdsn#">
        		            INSERT into TPMD360ANSWER (answercode, ratercode, questioncode, answer_text, created_date, created_by, modified_date, modified_by)
        		            values (
        		                <cfqueryparam value="#CreateUUID()#" cfsqltype="cf_sql_varchar">,
        		                <cfqueryparam value="#ratercode#" cfsqltype="cf_sql_varchar">,
        		                <cfqueryparam value="#questioncode#" cfsqltype="cf_sql_varchar">,
        		                <cfqueryparam value="#answer#" cfsqltype="cf_sql_varchar">,
        		                <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
        		                <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
                                <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
                                <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">
        		            )
        		        </cfquery>
        		      
        		        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Save Answer Question",true)>
        		        
        		        <!---Cek and validation is using score--->
        		        <cfif qGetDetailQuestion.answer_type EQ 1>
		                    <cfset isUsingScore = true>
	            		    <cfset totalScore = totalScore + val(answer)>
    		    		    <cfset totalQuestionTypeScore = totalQuestionTypeScore+1 >
        		        </cfif>
        		        <!---Cek and validation is using score--->
        		        
        		        
        		    <cfcatch>
        		        <cfset issuccess=false>
        		      
        		        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed Save Answer Question",true)>
        		    </cfcatch>
    		        </cftry>
    		    </cftransaction>
		    </cfloop>
		    
		    <!--- jika berhasil insert ke table answer, maka update status ditable raternya --->
		    <cfif issuccess>
		        <cfif isUsingScore EQ true AND totalScore NEQ 0>
		            <cfset sumScore = val(totalScore/totalQuestionTypeScore)>
		        </cfif>
		    
		        <cfquery name="qUptRater" datasource="#request.sdsn#">
		            update TPMD360RATER
		            set status = <cfqueryparam value="#typesubmit#" cfsqltype="cf_sql_varchar">,
		            modified_date = <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
		            modified_by =  <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">
    		        <cfif isUsingScore EQ true AND totalScore NEQ 0>
		                ,total_score = <cfqueryparam value="#sumScore#" cfsqltype="cf_sql_varchar">
		            </cfif>
		            where ratercode = <cfqueryparam value="#ratercode#" cfsqltype="cf_sql_varchar">
		        </cfquery>
		    </cfif>
		    
		    <cfoutput>
				<script>
					alert("#SFLANG#"); 
					popClose();
					reloadPage();
				</script>
			</cfoutput>
			<CF_SFABORT>
		</cffunction>
		
	    <!---360Quest--->
		<cffunction name="filterEmployeeQuestion">
    		<cfparam name="period_code" default="">
    		<cfparam name="empid" default="">
    		<cfparam name="reviewee_empid" default="">
    		<cfparam name="grade_order" default="">
    		<cfparam name="search" default="">
    		<cfparam name="nrow" default="50">
    		
    		<cfif val(nrow) eq "0">
    			<cfset local.nrow="50">
    		</cfif>
    		<cfset LOCAL.searchText=trim(search)>
    		<cfset LOCAL.count = 1/>
    
    		<!--- filter employee  [ ENC50917-81121 ]--->
    		<cfparam name="ftpass" default="">
    		<cfset local.lstparams="alldept,work_loc,work_status,cost_center,job_status,job_grade,emp_pos,emp_status,gender,marital,religion,hdnfaoempnolist">
    		<cfif ftpass neq "" AND IsJSON(ftpass)>
    			<cfset local.params=DeserializeJSON(ftpass)>
    			<Cfset local.iidx = "">
    			<cfloop list="#lstparams#" index="iidx">
    				<cfif StructKeyExists(params,iidx)>
    					<cfparam name="#iidx#" default="#params[iidx]#">
    				<cfelse>
    					<cfparam name="#iidx#" default="">
    				</cfif>
    			</cfloop>
    		</cfif>
    
    		<cfif ftpass neq "" AND IsJSON(ftpass) AND isdefined("alldept") AND alldept eq "false">
    			<cfif request.dbdriver eq 'MYSQL'><!--- untuk inclusive --->
    				<cfset LOCAL.cond_dept0=replace(params.dept,",",",%' OR CONCAT(',',e.parent_path,',') LIKE '%,","All")>
    				<cfset LOCAL.cond_dept=PreserveSingleQuotes(LOCAL.cond_dept0)>
    			<cfelse>
    				<cfset LOCAL.cond_dept0=replace(params.dept,",",",%' OR ','#REQUEST.DBSTRCONCAT#e.parent_path#REQUEST.DBSTRCONCAT#',' LIKE '%,","All")>
    				<cfset LOCAL.cond_dept=PreserveSingleQuotes(LOCAL.cond_dept0)>
    			</cfif>
    		<cfelse>
    			<cfset LOCAL.cond_dept="">
    		</cfif>
    		<cfset LOCAL.lsGender="Female,Male">
    		<cfset LOCAL.lsMarital="Single,Married,Widow,Widower,Divorce">
    		<cfset LOCAL.EmpLANG=Application.SFParser.TransMLang(listAppend(lsMarital,lsGender),false,",")>
            <!--- TCK1810-0479577 - Tidak pakai employee authorization, mengikuti list pef form --->
			<cfquery name="local.qData" datasource="#request.sdsn#">
				SELECT distinct 
				    a.emp_id, 
				    full_name, 
				    full_name AS emp_name, 
				    b.emp_no
				    
				    <!---
				    ,TPMDPERFORMANCE_EVALH.form_no ,
				    TPMMPERIOD.period_name_#request.scookie.lang# AS period_name, 
				    TPMDPERFORMANCE_EVALH.reference_date
				    --->
				    
				FROM TEOMEMPPERSONAL a
				LEFT JOIN TEODEMPCOMPANY b ON a.emp_id = b.emp_id
				LEFT JOIN TCLRGroupMember GM on GM.emp_id = b.emp_id

				LEFT JOIN TEODEMPLOYMENTHISTORY d ON a.emp_id = d.emp_id 

				LEFT JOIN TEOMPOSITION e 
					ON e.position_id = b.position_id 
					AND e.company_id = b.company_id
				LEFT JOIN TEODEmppersonal f 
					ON f.emp_id = b.emp_id 
					
                <!---
                LEFT JOIN TPMMPERIOD
                    ON TPMMPERIOD.period_code = TPMDPERFORMANCE_EVALH.period_code
                --->

				WHERE b.company_id = #REQUEST.SCookie.COID#
				AND enddt IS NULL AND careertransition_code != 'Termination'
	
	            <!---additional filter--->
	            <!------>

				<cfif grade_order neq "">
					<cfset grade_order = replace(grade_order,",","','","ALL")/>
					AND b.grade_code IN ('#grade_order#')
				</cfif>

				<cfif len(searchText)>
					AND
					(
						a.Full_Name LIKE '%#searchText#%'
						OR b.emp_no Like '%#searchText#%'
					)
				</cfif>

				<cfif ftpass neq "" AND IsJSON(ftpass)>
					<cfif isdefined("alldept") AND alldept eq "false"> 
						AND
						<cfif params.inclusive eq "false">
							<cfset local.where_dept="(e.parent_id = " & replace(params.dept,","," OR e.parent_id = ","All") & " OR e.dept_id = " & replace(params.dept,","," OR e.dept_id = ","All") & ")">
							#where_dept#					   
						<cfelse>
							<cfif request.dbdriver eq 'MYSQL'>
								(CONCAT(',',e.parent_path,',') LIKE '%,#PreserveSingleQuotes(LOCAL.cond_dept)#,%')
							<cfelse>
								(','#REQUEST.DBSTRCONCAT#e.parent_path#REQUEST.DBSTRCONCAT#',' LIKE '%,#PreserveSingleQuotes(LOCAL.cond_dept)#,%')
							</cfif>
						</cfif>
						
					</cfif>
					<cfif isdefined("work_loc") AND len(work_loc)>
						AND b.work_location_code in (<cfqueryparam value="#work_loc#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(work_status) and work_status eq "1">
						<cfif request.dbdriver eq "MSSQL">
						 AND (b.end_date >= getdate() OR b.end_date IS NULL)
						 <cfelseif request.dbdriver eq "MYSQL">
						 AND (b.end_date >= NOW() OR b.end_date IS NULL)
						 </cfif>
					<cfelseif len(work_status) and work_status eq "0">
						<cfif request.dbdriver eq "MSSQL">
						 AND (b.end_date < getdate() AND b.end_date IS NOT NULL)
						 <cfelseif request.dbdriver eq "MYSQL">
						 AND (b.end_date < NOW() AND b.end_date IS NOT NULL)
						 </cfif>
					</cfif>
					<cfif isdefined("cost_center") AND len(cost_center)>
						AND b.cost_code IN (<cfqueryparam value="#cost_center#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif isdefined("job_status") AND len(job_status)>
						AND b.job_status_code IN (<cfqueryparam value="#job_status#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif isdefined("job_grade") AND len(job_grade)>
						AND b.grade_code IN (<cfqueryparam value="#job_grade#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(emp_pos)>
						AND b.position_id IN (<cfqueryparam value="#emp_pos#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(emp_status)>
						AND b.employ_code IN (<cfqueryparam value="#emp_status#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<!---Personal_Information--->
					<cfif len(gender) and gender neq "2">
						#APPLICATION.SFUtil.getLookupQueryPart("gender",gender,"0=Female|1=Male",0,"AND")#
					</cfif>
					<cfif len(marital)>
						AND f.maritalstatus = <cfqueryparam value="#marital#" cfsqltype="CF_SQL_INTEGER">
					</cfif>
					<cfif len(religion)>
						AND f.religion_code IN (<cfqueryparam value="#religion#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<!--- Filter Employeeno --->
					<cfif len(trim(hdnfaoempnolist))>
                        AND (#Application.SFUtil.CutList(ListQualify(hdnfaoempnolist,"'")," b.emp_no IN  ","OR",2)#)
                    </cfif>
                    <!--- Filter Employeeno --->
                <cfelse>
                    <!--- default employee aktif --->
					<cfif request.dbdriver eq "MSSQL">
					 AND (b.end_date >= getdate() OR b.end_date IS NULL)
					 <cfelseif request.dbdriver eq "MYSQL">
					 AND (b.end_date >= NOW() OR b.end_date IS NULL)
					 </cfif>
                    <!--- default employee aktif --->
				</cfif>
				<!---Filter:Employee_Information  [ ENC50917-81121 ]--->
				<!--- AND a.emp_id NOT IN(<cfqueryparam value="#empid#" cfsqltype="CF_SQL_VARCHAR" list="Yes">) reviewee bisa jadi rater di form nya sendiri ---> <!---Bukan reviewer--->

				ORDER BY full_name	
			</cfquery>
			
			<!---Get Answered for flag--->
		    <cfquery name="LOCAL.qSelectExistingAnswered" datasource="#request.sdsn#">
                SELECT
                   TPMD360RATER.ratercode,
                   TPMD360RATER.rater_empid,
                   TPMD360RATER.reviewee_empid,
                   TPMD360RATER.status,
                   TPMD360RATER.flag_email,
                   TPMD360RATER.period_code,
                   TPMD360RATER.created_date
                FROM
                   TPMD360RATER 
                WHERE
                   TPMD360RATER.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
                   AND TPMD360RATER.reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
                   AND UPPER(TPMD360RATER.status) <> UPPER(<cfqueryparam value="NEW" cfsqltype="cf_sql_varchar">)
		    </cfquery>
		    <cfset LOCAL.lstEmpidAnswered = qSelectExistingAnswered.recordcount ? ValueLIst(qSelectExistingAnswered.rater_empid) : '-'>
			<!---Get Answered for flag--->
			
			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSEmployee",true,"+")>
			<cfset LOCAL.vResult="">
			<cfloop query="qData">
			    <cfif ListFindNocase(lstEmpidAnswered,qData.emp_id)>
    			    <cfset vResult=vResult & "
    				arrEntryList[#currentrow-1#]=""#JSStringFormat(emp_id & "=" & emp_name & " [#emp_no#] *")#"";">
			    <cfelse>
    			    <cfset vResult=vResult & "
    				arrEntryList[#currentrow-1#]=""#JSStringFormat(emp_id & "=" & emp_name & " [#emp_no#]")#"";">
			    </cfif>
			</cfloop>
			<cfoutput>
				<script>
				    arrEntryList=new Array();
					document.getElementById('lbl_inp_emp_rater').innerHTML  = '#SFLANG# (#qData.recordcount#) <span class=\"required\">*</span>';
    				<cfif len(vResult)>
    					#vResult#
    				</cfif>
			    </script>
			</cfoutput>
		</cffunction>
		
    	<cffunction name="filterMemberEmployeeQuestion">
    		<cfparam name="search" default="">
    		<cfparam name="nrow" default="1000">
    		<cfparam name="period_code" default="">
    		<cfparam name="empid" default="">
    		<cfparam name="emp_rater" default="">
        	<cfif val(nrow) eq "0">
    			<cfset local.nrow="1000">
    		</cfif>

        	<cfquery name="LOCAL.qGetMember" datasource="#REQUEST.SDSN#">
        		SELECT rater_empid emp_id FROM TPMD360RATER 
        		 WHERE period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
        		   AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="CF_SQL_VARCHAR"> 
        	</cfquery>
    
    		<cfset LOCAL.listempid = "">
    		<cfif qGetMember.recordcount neq 0>
    			<cfset listempid = valuelist(qGetMember.emp_id)/>
        	</cfif>
    		
    		<cfset LOCAL.searchText=trim(search)>
    		<cfset LOCAL.listempid=trim(listempid)>
            <!--- TCK1810-0479577 - Tidak pakai employee authorization, mengikuti list pef form --->
    		<cfquery name="LOCAL.qdata" datasource="#REQUEST.SDSN#">
    			SELECT DISTINCT EC.emp_id emp_id,EC.emp_no
    				,full_name emp_name 
    			FROM TEOMEmpPersonal E 
    				INNER JOIN TEODEMPCOMPANY EC ON EC.emp_id = E.emp_id 
    			WHERE EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="CF_SQL_INTEGER"/> 
    				<cfif len(searchText)>
    				AND (E.full_name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#searchText#%"/>)
    				</cfif>
    				<cfif len(listempid)>
    					AND EC.emp_id IN (<cfqueryparam value="#listempid#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
    				<cfelse>
    					AND 1 = 0	
    				</cfif>
    			order by emp_name
    		</cfquery>
    		
			<!---Get Answered for flag--->
		    <cfquery name="LOCAL.qSelectExistingAnswered" datasource="#request.sdsn#">
                SELECT
                   TPMD360RATER.ratercode,
                   TPMD360RATER.rater_empid,
                   TPMD360RATER.reviewee_empid,
                   TPMD360RATER.status,
                   TPMD360RATER.flag_email,
                   TPMD360RATER.period_code,
                   TPMD360RATER.created_date
                FROM
                   TPMD360RATER 
                WHERE
                   TPMD360RATER.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
                   AND TPMD360RATER.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                   AND UPPER(TPMD360RATER.status) <> UPPER(<cfqueryparam value="NEW" cfsqltype="cf_sql_varchar">)
		    </cfquery>
		    <cfset LOCAL.lstEmpidAnswered = qSelectExistingAnswered.recordcount ? ValueLIst(qSelectExistingAnswered.rater_empid) : '-'>
			<!---Get Answered for flag--->
    		
    		<cfset local.lstemp = "">
    		<cfif qData.recordcount neq 0>
    			<cfset lstemp = valuelist(qData.emp_id)>
    		</cfif>
    		<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSEmployee",true,"+")>
    		<cfset LOCAL.vResult="">
    		<cfloop query="qData">
			    <cfif ListFindNocase(lstEmpidAnswered,qData.emp_id)>
        		    <cfset vResult=vResult & "
        			    arrEntryList[#currentrow-1#]=""#JSStringFormat(emp_id & "=" & emp_name & " [#emp_no#] *")#"";">
			    <cfelse>
        		    <cfset vResult=vResult & "
        			    arrEntryList[#currentrow-1#]=""#JSStringFormat(emp_id & "=" & emp_name & " [#emp_no#]")#"";">
			    </cfif>
    		</cfloop>
    		<cfoutput>
    		<script>
    			arrEntryList=new Array();
    			<cfif len(vResult)>
    			#vResult#
    			</cfif>
    			
			    try{ setTimeout(function(){ checkRaterAnswered(); }, 100); }catch(e){} // function ini ada di evalform/360question/managerater.xml
    		</script>
    		</cfoutput>
    	</cffunction>
		
		
		<cffunction name="ManageRater">
	        <cfparam name="empid" default="">
	        <cfparam name="formno" default="">
	        <cfparam name="periodcode" default="">
			<cfparam name="varcoid" default="#request.scookie.coid#">
	        <cfset local.nowdate= DATEFORMAT(CreateDate(Datepart("yyyy",now()),Datepart("m",now()),Datepart("d",now())),"mm/dd/yyyy")>
	        
	        <cfquery name="local.qGetRater" datasource="#REQUEST.SDSN#">
	          	select rater_empid, status FROM TPMD360RATER
			    WHERE period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
			        AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        
	        <cfquery name="local.qGetRaterNotNew" dbtype="query">
	        	SELECT * FROM qGetRater
	        	WHERE UPPER(status) <> 'NEW'
	        </cfquery>

	        <cfquery name="local.qGetFormDetail" datasource="#request.sdsn#">
	        	SELECT 
	        	    '#ValueList(qGetRater.rater_empid)#' emp_rater,
	        	    '#ValueList(qGetRaterNotNew.rater_empid)#' lstsubmitted_rater,
	        	    period_code,
	        	    <cfif request.dbdriver eq "MYSQL">
	        	    CONVERT (final_enddate, CHAR(10)) AS final_enddate
	        	    <cfelseif request.dbdriver eq "MSSQL">
	        	    CONVERT(VARCHAR(10), final_enddate, 120) AS final_enddate 
	        	    </cfif>
	        	    
	            FROM TPMMPERIOD
                WHERE period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
			<cfset REQUEST.KeyFields="empid=#empid#">
	    	<cfreturn qGetFormDetail>
		</cffunction>
		
		
		<cffunction name="ManageRaterSave">
	        <cfparam name="formno" default="">
	        <cfparam name="empid" default="">
	        <cfparam name="period_code" default="">
	        <cfparam name="hdnSelectedemp_rater" default="">
	        <cfparam name="fnlendate" default="">
	        <cfparam name="using_excel" default="">
	        <cfset flagnewui = "#REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE#">
		    
		    <!--- VALIDASI --->
		    
		    <cfif using_excel EQ 1><!---Upload--->
		        <CF_SFUPLOAD ACTION="UPLOAD" CODE="planningupload" FILEFIELD="fileupload" onerror="parent.refreshPage();" output="xlsuploaded">
                <cfset LOCAL.dtUpload='#xlsuploaded.SERVERFILE#'>
                <cfif xlsuploaded.ClientFileExt eq "xls">
					<cfset LOCAL.lstHeaderColumn = "EMP_NO,EMP_NAME">
					<cfset LOCAL.nColumn = ListLen(lstHeaderColumn,",")> 
                    <cfset  LOCAL.strFileExcel = xlsuploaded.SERVERDIRECTORY & "/" & xlsuploaded.SERVERFILE />
                    <cfspreadsheet action="read" src="#strFileExcel#" columns = "1-#val(nColumn)#"  query="Local.qdata" headerrow="1" excludeHeaderRow="true" columnNames="#lstHeaderColumn#">
                    <cfset LOCAL.lstEMpNo = ValueList(qdata.emp_no)>
        		    <cfquery name="LOCAL.getEmpIdFromUpload" datasource="#request.sdsn#">
        		        SELECT emp_id FROM 
        		        TEODEMPCOMPANY
        		        WHERE (#Application.SFUtil.CutList(ListQualify(lstEMpNo,"'")," emp_no IN  ","OR",2)#)
        		        AND COMPANY_ID = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
        		    </cfquery>
                    <cfset LOCAL.hdnSelectedemp_rater = ValueList(getEmpIdFromUpload.emp_id)>
				<cfelse>
				    <CF_SFUPLOAD ACTION="DELETE" CODE="planningupload" FILENAME="#xlsuploaded.SERVERFILE#" output="xlsuploadedDelete">
					<cfset LOCAL.SFLANG4=Application.SFParser.TransMLang("JSPlease upload xls format file",true)>
					<cfoutput>
						<script>
							alert("#SFLANG4#");
							maskButton(false);		
							parent.refreshPage();	
						</script>
						 <CF_SFABORT>
					</cfoutput>
                </cfif>
		    </cfif>
		    
		    <!--- cek apakah sudah di set questionnya atau belum --->
		    <cfset LOCAL.SFLANGERR=Application.SFParser.TransMLang("JSFailed to set Rater, please set Question FIrst",true)>
		    <cfquery name="LOCAL.qcheckQuestion" datasource="#request.sdsn#">
		        SELECT * FROM 
		        tpmd360question
		        WHERE PERIOD_CODE = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
		        AND COMPANY_ID = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
		    </CFQUERY>
		    
		    <cfif qcheckQuestion.recordcount lt 1>
		        <cfoutput>
        			<script>
        				alert("#SFLANGERR#");
        				this.close();
        			</script>
        		</cfoutput>
        		<CF_SFABORT>
		    </cfif>
		    
		    <!--- cek apakah rater yg diset ada terminate datenya dan apakah terminate nya ini <= final period date performance --->
		    <cfset isanyterimante = false>
		    <cfloop list="#hdnSelectedemp_rater#" index="LOCAL.rater_empid">
    		    <cfquery name="LOCAL.qCheckUserTerminate" datasource="#request.sdsn#">
    		        select terminate_date
    		        from TEODEMPCOMPANYGROUP
    		        where emp_id = <cfqueryparam value="#local.rater_empid#" cfsqltype="cf_sql_varchar">
    		        and terminate_date < <cfqueryparam value="#fnlendate#" cfsqltype="cf_sql_varchar">
    		    </cfquery>
    		    <!--- VALIDASI APAKAH USER TERSEBUT TERMINATENYA LEBIH KECIL DARI FINAL DATE 
    		        UNTUK CASE KETIKA RATER YG DI SET TERNYATA MENDEKATI TERMINATE DATENYA / TGL RESIGN --->
    		    <cfif qCheckUserTerminate.recordcount gt 0>
    		       <cfset isanyterimante = true> 
    		    </cfif>
		    </cfloop>
		    
		    <!--- END VALIDASI --->
		
		    <cfquery name="LOCAL.qSelectExisting" datasource="#request.sdsn#">
                SELECT
                   TPMD360RATER.ratercode,
                   TPMD360RATER.rater_empid,
                   TPMD360RATER.reviewee_empid,
                   TPMD360RATER.status,
                   TPMD360RATER.flag_email,
                   TPMD360RATER.period_code,
                   TPMD360RATER.created_date
                   ,RATER.full_name rater_name
                   ,RATER.email rater_email
                   ,REVIEWEE.full_name reviewee_name
                   ,TPMMPERIOD.period_name_#request.scookie.lang# period_name
                FROM
                   TPMD360RATER 
                LEFT JOIN TEOMEMPPERSONAL RATER
                    ON RATER.emp_id = TPMD360RATER.rater_empid
                LEFT JOIN TEOMEMPPERSONAL REVIEWEE
                    ON REVIEWEE.emp_id = TPMD360RATER.reviewee_empid
                LEFT JOIN TPMMPERIOD
                	ON TPMMPERIOD.period_code = TPMD360RATER.period_code
                	AND TPMMPERIOD.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
                WHERE
                   TPMD360RATER.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
                   AND TPMD360RATER.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
		    </cfquery>
		    
		    <cfset LOCAL.lstRaterCodeAnswered = ''>
		    <cfif qSelectExisting.recordcount >
    		    <cfquery name="LOCAL.qSeletSubmittedRating" datasource="#request.sdsn#">
                    SELECT
                       answercode,ratercode
                    FROM
                       TPMD360ANSWER 
                    WHERE
						<cfif qSelectExisting.ratercode neq "">
							 <!---ratercode IN (<cfqueryparam value="#ValueList(qSelectExisting.ratercode)#" cfsqltype="cf_sql_varchar" list="Yes">)--->
							 <cfset LOCAL.tempLstRaterCode = ValueList(qSelectExisting.ratercode)>
							 (#Application.SFUtil.CutList(ListQualify(tempLstRaterCode,"'")," ratercode IN  ","OR",2)#)
						<cfelse>
							1=0
						</cfif>
                      
    		    </cfquery>
    		    <cfset LOCAL.lstRaterCodeAnswered = ValueLIst(qSeletSubmittedRating.ratercode)>
    		</cfif>
		    
		    <!---Loop to get deleted and validate--->
		    <cfset LOCAL.failDeleted = ''>
		    <cfloop query="qSelectExisting">
		        <cfif NOT ListFindNoCase(hdnSelectedemp_rater,qSelectExisting.rater_empid)>
		            <cfif ListFindNoCase(lstRaterCodeAnswered,qSelectExisting.ratercode)> <!---Sudah ada jawaban--->
		                <cfset LOCAL.failDeleted = ListAppend(failDeleted, qSelectExisting.rater_name,', ')>
		            <cfelse>
            		    <cfquery name="LOCAL.qDeleteRater" datasource="#request.sdsn#">
                            DELETE FROM TPMD360RATER
                            WHERE ratercode = <cfqueryparam value="#qSelectExisting.ratercode#" cfsqltype="cf_sql_varchar">
                                AND period_code = <cfqueryparam value="#qSelectExisting.period_code#" cfsqltype="cf_sql_varchar">
                                AND reviewee_empid = <cfqueryparam value="#qSelectExisting.reviewee_empid#" cfsqltype="cf_sql_varchar">
            		    </cfquery>
            		    <cfset sendEmailNoLongerAsRater(
            		    	rater_email=qSelectExisting.rater_email,
							rater_name=qSelectExisting.rater_name,
							reviewee_name=qSelectExisting.reviewee_name,
							period_code=qSelectExisting.period_code,
							period_name=qSelectExisting.period_name
						)>
		            </cfif>
		        </cfif>
		    </cfloop>
		    <!---Loop to get deleted and validate--->
		    
		    <!---Loop selected and eliminate when already in existing--->
		    <cfset LOCAL.lstRaterExisting = ValueList(qSelectExisting.rater_empid)>
		    <cfloop list="#hdnSelectedemp_rater#" index="LOCAL.rater_empid">
		        <cfif NOT ListFindNoCase(lstRaterExisting,rater_empid)> <!---Belum ada di existing maka di insert--->
        		    <cfquery name="LOCAL.qInsertRater" datasource="#request.sdsn#">
                        INSERT INTO TPMD360RATER 
                            (
                                RATERCODE,
                                PERIOD_CODE,
                                RATER_EMPID,
                                STATUS,
                                FLAG_EMAIL,
                                CREATED_DATE,
                                CREATED_BY,
                                MODIFIED_DATE,
                                MODIFIED_BY,
                                REVIEWEE_EMPID,
                                ASSIGNED_BY
                            )
                        VALUES (
                            <cfqueryparam value="#CreateUUID()#" cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#rater_empid#" cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="NEW" cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="0" cfsqltype="cf_sql_varchar">, <!---Flag Email--->
                            <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
                            <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
                            <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
                            <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
                        )
        		    </cfquery>
		        </cfif>
		    </cfloop>
		    <!---Loop selected and eliminate when already in existing--->

		    <!---Send email--->
		    <cfset sendEmailSetRaterBasedFlagEmail(reviewee_empid=empid,period_code=period_code)>
		    <!---Send email--->
		    
		    <cfif isanyterimante>
		        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Set Rater for 360Question, but there are some rater who will resign",true)>
		    <cfelse>
                <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Set Rater for 360Question",true)>
            </cfif>
    		<cfif trim(failDeleted) neq ''>
    		    <cfset LOCAL.SFLANGAdd=Application.SFParser.TransMLang("JSWith exception",true)>
    		    <cfset SFLANG&= "\n#SFLANGAdd# : Failed to delete (#failDeleted#) because the question has been answered">
    		</cfif>
    		<cfoutput>
    			<script>
    				alert("#SFLANG#");
    				<cfif flagnewui eq 0>
        				top.popClose();
        				if(top.opener){
        					top.opener.reloadPage();
        				}
    				<cfelse>
    				    top.refreshPage()
    				    this.close();
    				</cfif>
    			</script>
    		</cfoutput>
	       
		</cffunction>
		
		<!---Send email--->
		<cffunction name="sendEmailSetRaterBasedFlagEmail">
	        <cfparam name="reviewee_empid" default="">
	        <cfparam name="period_code" default="">

    		<cfquery name="local.qEmailTemplate" datasource="#REQUEST.SDSN#">
    			SELECT subject_#request.scookie.lang# subject,body_#request.scookie.lang# body
    			FROM TSFMMAILTemplate
    			WHERE UPPER(template_code) = 'NOTIFFORRATER360QUESTION'
    		</cfquery>
            <cfset LOCAL.TemplateeSubject = qEmailTemplate.subject>
            <cfset LOCAL.TemplateeContent = qEmailTemplate.body>
		
		    <!---Get ALl Rater Flag_email = 0--->
		    <cfquery name="LOCAL.qSelectUnsentEmail" datasource="#request.sdsn#">
                SELECT
                   TPMD360RATER.ratercode,
                   TPMD360RATER.rater_empid,
                   TPMD360RATER.reviewee_empid,
                   TPMD360RATER.status,
                   TPMD360RATER.flag_email,
                   TPMD360RATER.period_code,
                   TPMD360RATER.created_date,
                   TPMD360RATER.created_by
                   ,RATER.full_name rater_name
                   ,RATER.email rater_email
                   ,TPMMPERIOD.period_name_#request.scookie.lang# period_name

                   ,REVIEWEE.full_name reviewee_name
			        ,POSREVIEWEE.pos_name_#request.scookie.lang# reviewee_posname
			        ,DEPTREVIEWEE.pos_name_#request.scookie.lang# reviewee_deptname
			        ,SETTER.full_name assignedby_name
                FROM
                   TPMD360RATER 
                LEFT JOIN TEOMEMPPERSONAL RATER
                    ON RATER.emp_id = TPMD360RATER.rater_empid

                LEFT JOIN TEOMEMPPERSONAL REVIEWEE
                    ON REVIEWEE.emp_id = TPMD360RATER.reviewee_empid
                    
                LEFT JOIN TEODEMPCOMPANY COMPREVIEWEE
                    ON COMPREVIEWEE.emp_id = REVIEWEE.emp_id
                    AND COMPREVIEWEE.status = 1
                    AND COMPREVIEWEE.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">

			    LEFT JOIN TEOMPOSITION POSREVIEWEE 
					ON POSREVIEWEE.position_id = COMPREVIEWEE.position_id 
					AND POSREVIEWEE.company_id = COMPREVIEWEE.company_id
			    LEFT JOIN TEOMPOSITION DEPTREVIEWEE 
					ON DEPTREVIEWEE.position_id = POSREVIEWEE.dept_id 
					AND DEPTREVIEWEE.company_id = POSREVIEWEE.company_id

				<!---Assigned By--->
				LEFT JOIN TCLMUSER CREATED
						ON CREATED.user_name = TPMD360RATER.created_by
				LEFT JOIN TEOMEMPPERSONAL SETTER 
						ON SETTER.user_id = CREATED.user_id
				<!---Assigned By--->

                LEFT JOIN TPMMPERIOD
                	ON TPMMPERIOD.period_code = TPMD360RATER.period_code
                	AND TPMMPERIOD.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
                WHERE
                    TPMD360RATER.flag_email = '0'
                <cfif reviewee_empid NEQ '' AND period_code NEQ ''>
                   AND TPMD360RATER.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
                   AND TPMD360RATER.reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
				<cfelse>
					AND 1=0
                </cfif>
		    </cfquery>
		    <!---Get Rater Flag_email = 0--->
    		
    	    <cfif qEmailTemplate.recordcount gt 0>
                <cfloop query="qSelectUnsentEmail">
	    			<cfset LOCAL.eSubject = TemplateeSubject>
	    			<cfset LOCAL.eContent = TemplateeContent>
	    
	    			<cfif FindNoCase("{SYS_NAME}",eContent,1)> 
	    				<cfset eContent = ReplaceNoCase(eContent,"{SYS_NAME}",#REQUEST.CONFIG.APP_NAME#,"ALL")>
	    			</cfif>
	    			<cfif FindNoCase("{EMPLOYEE_NAME}",eContent,1)>
	    				<cfset eContent = ReplaceNoCase(eContent,"{EMPLOYEE_NAME}",#HTMLEDITFORMAT(qSelectUnsentEmail.rater_name)#,"ALL")>
	    			</cfif>
	    			<cfif FindNoCase("{PERIOD_NAME}",eContent,1)>
	    				<cfset eContent = ReplaceNoCase(eContent,"{PERIOD_NAME}",#HTMLEDITFORMAT(qSelectUnsentEmail.period_name)#,"ALL")>
	    			</cfif>
	    			<cfif FindNoCase("{REVIEWEE_NAME}",eContent,1)>
	    				<cfset eContent = ReplaceNoCase(eContent,"{REVIEWEE_NAME}",#HTMLEDITFORMAT(qSelectUnsentEmail.reviewee_name)#,"ALL")>
	    			</cfif>
	    			<cfif FindNoCase("{REVIEWEE_POSITION}",eContent,1)>
	    				<cfset eContent = ReplaceNoCase(eContent,"{REVIEWEE_POSITION}",#HTMLEDITFORMAT(qSelectUnsentEmail.reviewee_posname)#,"ALL")>
	    			</cfif>
	    			<cfif FindNoCase("{REVIEWEE_ORGUNIT}",eContent,1)>
	    				<cfset eContent = ReplaceNoCase(eContent,"{REVIEWEE_ORGUNIT}",#HTMLEDITFORMAT(qSelectUnsentEmail.reviewee_deptname)#,"ALL")>
	    			</cfif>
	    			<cfif FindNoCase("{ASSIGNED_BY}",eContent,1)>
	    				<cfset eContent = ReplaceNoCase(eContent,"{ASSIGNED_BY}",#HTMLEDITFORMAT(qSelectUnsentEmail.assignedby_name)#,"ALL")>
	    			</cfif>
	    			<cfif FindNoCase("{DATE_ASSIGNED}",eContent,1)>
	    				<cfset eContent = ReplaceNoCase(eContent,"{DATE_ASSIGNED}",#DateFormat(qSelectUnsentEmail.created_date,REQUEST.config.DATE_OUTPUT_FORMAT)#,"ALL")>
	    			</cfif>
	    			<cfif qSelectUnsentEmail.rater_email neq "">
	    				<cfmail from="#REQUEST.CONFIG.ADMIN_EMAIL#" to="#qSelectUnsentEmail.rater_email#" subject="#eSubject#" type="HTML" failto="#REQUEST.CONFIG.ADMIN_EMAIL#">
	    					#eContent#
	    				</cfmail>
	    			</cfif>

	    			<!---Set Flag Email 1--->
		    		<cfquery name="local.qEmailTemplate" datasource="#REQUEST.SDSN#">
		    			UPDATE TPMD360RATER
		    			SET FLAG_EMAIL = 1
		    			WHERE period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
                   		AND reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
						<cfif qSelectUnsentEmail.rater_email neq "">
                   		AND rater_empid = <cfqueryparam value="#qSelectUnsentEmail.rater_empid#" cfsqltype="cf_sql_varchar">
						<cfelse>
						AND 1= 0
						</cfif>
		    		</cfquery>
	    			<!---Set Flag Email 1--->

                </cfloop>
    		</cfif>
		</cffunction>
		<!---Send email--->

		<cffunction name="sendEmailNoLongerAsRater">
	        <cfparam name="rater_email" default="">
	        <cfparam name="rater_name" default="">
	        <cfparam name="reviewee_name" default="">
	        <cfparam name="period_code" default="">
	        <cfparam name="period_name" default="">

    		<cfquery name="local.qEmailTemplate" datasource="#REQUEST.SDSN#">
    			SELECT subject_#request.scookie.lang# subject,body_#request.scookie.lang# body
    			FROM TSFMMAILTemplate
    			WHERE UPPER(template_code) = 'NOTIFNOLONGERASRATER360QUESTION'
    		</cfquery>
    	    <cfif qEmailTemplate.recordcount gt 0>
    			<cfset LOCAL.eSubject = qEmailTemplate.subject>
    			<cfset LOCAL.eContent = qEmailTemplate.body>
    
    			<cfif FindNoCase("{SYS_NAME}",eContent,1)>
    				<cfset eContent = ReplaceNoCase(eContent,"{SYS_NAME}",#REQUEST.CONFIG.APP_NAME#,"ALL")>
    			</cfif>
    			<cfif FindNoCase("{EMPLOYEE_NAME}",eContent,1)>
    				<cfset eContent = ReplaceNoCase(eContent,"{EMPLOYEE_NAME}",#HTMLEDITFORMAT(rater_name)#,"ALL")>
    			</cfif>
    			<cfif FindNoCase("{PERIOD_NAME}",eContent,1)>
    				<cfset eContent = ReplaceNoCase(eContent,"{PERIOD_NAME}",#HTMLEDITFORMAT(period_name)#,"ALL")>
    			</cfif>
    			<cfif FindNoCase("{REVIEWEE_NAME}",eContent,1)>
    				<cfset eContent = ReplaceNoCase(eContent,"{REVIEWEE_NAME}",#HTMLEDITFORMAT(reviewee_name)#,"ALL")>
    			</cfif>
    			<cfif rater_email neq "">
    				<cfmail from="#REQUEST.CONFIG.ADMIN_EMAIL#" to="#rater_email#" subject="#eSubject#" type="HTML" failto="#REQUEST.CONFIG.ADMIN_EMAIL#">
    					#eContent#
    				</cfmail>
    			</cfif>
    	    </cfif>
		</cffunction>
		
		<cffunction name="getRaterListing">
	        <cfparam name="periodcode" default="">
	        <cfparam name="empid" default="">
	        <cfparam name="varcoid" default="">
	        <cfparam name="varcocode" default="">
	      
            <cfquery name="LOCAL.qRecord" datasource="#request.sdsn#">
                SELECT 
                    TPMD360RATER.rater_empid,
                    TPMD360RATER.reviewee_empid,
                    TPMD360RATER.status,
                    TPMD360RATER.flag_email,
                    TPMD360RATER.period_code,
                    TPMD360RATER.created_date
                    ,RATER.full_name rater_name
                    ,POSRATER.pos_name_#request.scookie.lang# rater_posname
                    ,DEPTRATER.pos_name_#request.scookie.lang# rater_deptname
                    ,TPMD360RATER.total_score
                FROM TPMD360RATER
                LEFT JOIN TEOMEMPPERSONAL RATER
                    ON RATER.emp_id = TPMD360RATER.rater_empid
                LEFT JOIN TEODEMPCOMPANY COMPRATER
                    ON COMPRATER.emp_id = RATER.emp_id
                    AND COMPRATER.status = 1
                    AND COMPRATER.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
                LEFT JOIN TEOMPOSITION POSRATER 
            		ON POSRATER.position_id = COMPRATER.position_id 
            		AND POSRATER.company_id = COMPRATER.company_id
                LEFT JOIN TEOMPOSITION DEPTRATER 
            		ON DEPTRATER.position_id = POSRATER.dept_id 
            		AND DEPTRATER.company_id = POSRATER.company_id
                WHERE TPMD360RATER.period_code = <cfqueryparam value="#periodcode#" cfsqltype="CF_SQL_VARCHAR">
                	AND TPMD360RATER.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="CF_SQL_VARCHAR">
                ORDER BY TPMD360RATER.created_date
            </cfquery>
            <cfreturn qRecord>
		</cffunction>
		
		
		<!---Untuk Notif--->
		<cffunction name="Add">
		    <cfset SUPER.Add(false,true,FORM)>
		    
		    <!---Get alloskip param--->
            <cfset LOCAL.allowskipCompParam = "Y">
            <cfset LOCAL.requireselfassessment = 1>
            <cfquery name="LOCAL.qCompParam" datasource="#request.sdsn#">
            	SELECT field_value, UPPER(field_code) field_code from tclcappcompany where UPPER(field_code) IN ('ALLOW_SKIP_REVIEWER', 'REQUIRESELFASSESSMENT') and company_id = '#REQUEST.SCookie.COID#'
            </cfquery>
            
            <cfloop query="qCompParam">
                <cfif TRIM(qCompParam.field_code) eq "ALLOW_SKIP_REVIEWER" AND TRIM(qCompParam.field_value) NEQ ''>
                	<cfset allowskipCompParam = TRIM(qCompParam.field_value)>
                <cfelseif TRIM(qCompParam.field_code) eq "REQUIRESELFASSESSMENT" AND TRIM(qCompParam.field_value) NEQ '' >
                	<cfset requireselfassessment = TRIM(qCompParam.field_value)> <!---Bypass self assesment--->
                </cfif>
            </cfloop>
		    <!---Get alloskip param--->
            
		    <!---Get status Request--->
			<cfquery name="local.qCekPMReqCurrentStatus" datasource="#request.sdsn#">
				SELECT status FROM TCLTREQUEST
				WHERE req_type = 'PERFORMANCE.EVALUATION'
					AND req_no = <cfqueryparam value="#FORM.REQUEST_NO#" cfsqltype="cf_sql_varchar">
					AND company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer"> 
					AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar"> 
			</cfquery>
		    <!---Get status Request--->
            
		    <!---Email notif--->
            <cfif qCekPMReqCurrentStatus.status EQ 3 > <!---Validasi Jika fully approved--->
                <cfset LOCAL.additionalData = StructNew() >
                <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                
                <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                    template_code = 'PerformanceEvalNotifFullyApproved', 
                    lstsendTo_empid = reviewee_empid , 
                    reviewee_empid = reviewee_empid ,
                    strckData = additionalData
                )>
                
                
            <cfelseif val(FORM.UserInReviewStep)+1 LTE Listlen(FORM.FullListAppr) > <!---Validasi ada next approver--->
                <cfif allowskipCompParam EQ 'N' > <!---Tidak bisa skip harus berurutan--->
    		        <cfset LOCAL.lstNextApprover = ListGetAt( FORM.FullListAppr , val(FORM.UserInReviewStep)+1 )><!---hanya get list next approver--->
                <cfelse>
    		        <cfset LOCAL.lstNextApprover = ''><!---all approver dikirim--->
                    <cfloop index="LOCAL.idx" from="#val(FORM.UserInReviewStep)+1#" to="#Listlen(FORM.FullListAppr)#" >
    		            <cfset tempList = ListGetAt( FORM.FullListAppr , idx )><!---get list next approver--->
		                <cfset lstNextApprover = ListAppend(lstNextApprover,tempList) ><!---all approver dikirim--->
                    </cfloop>
                </cfif>
                
                <cfset LOCAL.additionalData = StructNew() >
                <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                
                <cfif lstNextApprover NEQ ''>
                    <cfset lstSendEmail = replace(lstNextApprover,"|",",","all")>
                    <cfif reviewee_empid EQ request.scookie.user.empid> <!--- Send by reviewee status not requested --->
                        <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                            template_code = 'PerformanceEvalSubmitByReviewee', 
                            lstsendTo_empid = lstSendEmail , 
                            reviewee_empid = reviewee_empid ,
                            strckData = additionalData
                        )>
                    <cfelse><!--- Send by approver status not requested --->
                        <cfif ListLast(FORM.FullListAppr) EQ lstNextApprover>
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalSubmitToLastApprover', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        <cfelse>
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalSubmitByApprover', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        </cfif>
                    
                    </cfif>
                </cfif>
            </cfif>
            
		</cffunction>
		
		<cffunction name="SendNotifEmailEvaluation">
            <cfparam name="template_code" default=''/>
            <cfparam name="lstsendTo_empid" default=''/>
            <cfparam name="reviewee_empid" default=''/>
            <cfparam name="strckData" default="#StructNew()#" />

            <cfquery name="local.qEmailTemplate" datasource="#REQUEST.SDSN#">
                SELECT subject_#request.scookie.lang# subject,body_#request.scookie.lang# body
                FROM TSFMMAILTemplate
                WHERE template_code = <cfqueryparam value="#template_code#" cfsqltype="cf_sql_varchar">
            </cfquery>
        
            <cfquery name="LOCAL.qGetDetailReviewee" datasource="#request.sdsn#">
                SELECT teomemppersonal.email, teomemppersonal.full_name, TEODEMPCOMPANY.emp_no FROM teomemppersonal
                LEFT JOIN TEODEMPCOMPANY 
                    ON TEODEMPCOMPANY.emp_id = teomemppersonal.emp_id
                    AND TEODEMPCOMPANY.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
                where teomemppersonal.emp_id = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
            </cfquery>

            <cfif qEmailTemplate.recordcount eq 0>
                <cfreturn true>
            </cfif>
            <cfloop list="#lstsendTo_empid#" index="idxapprover">
                <cfquery name="LOCAL.qGetDetailNextApprover" datasource="#request.sdsn#">
                    SELECT teomemppersonal.email, teomemppersonal.full_name, TEODEMPCOMPANY.emp_no FROM teomemppersonal
                    LEFT JOIN TEODEMPCOMPANY 
                        ON TEODEMPCOMPANY.emp_id = teomemppersonal.emp_id
                        AND TEODEMPCOMPANY.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
                    where teomemppersonal.emp_id = <cfqueryparam value="#idxapprover#" cfsqltype="cf_sql_varchar">
                </cfquery>

                <cfset LOCAL.eSubject = qEmailTemplate.subject>
                <cfset LOCAL.eContent = qEmailTemplate.body>

                <!--- Subject --->
                <cfif FindNoCase("{SYS_NAME}",eSubject,1)> 
                    <cfset eSubject = ReplaceNoCase(eSubject,"{SYS_NAME}",#REQUEST.CONFIG.APP_NAME#,"ALL")>
                </cfif>

                <cfif FindNoCase("{REQUEST_NO}",eSubject,1) AND StructKeyExists(strckData,'REQUEST_NO' )>
                    <cfset eSubject = ReplaceNoCase(eSubject,"{REQUEST_NO}",#strckData.REQUEST_NO#,"ALL")>
                </cfif>
                
                <cfif FindNoCase("{REVIEWEE_NAME}",eSubject,1) >
                    <cfset eSubject = ReplaceNoCase(eSubject,"{REVIEWEE_NAME}",#HTMLEDITFORMAT(qGetDetailReviewee.full_name)#,"ALL")>
                </cfif>
                <!--- Subject --->

                <!--- Content --->
                <cfif FindNoCase("{NICKNAME}",eContent,1)>
                    <cfset eContent = ReplaceNoCase(eContent,"{NICKNAME}",#HTMLEDITFORMAT(qGetDetailNextApprover.full_name)#,"ALL")>
                </cfif>
                <cfif FindNoCase("{EMP_NO}",eContent,1)>
                    <cfset eContent = ReplaceNoCase(eContent,"{EMP_NO}",#HTMLEDITFORMAT(qGetDetailNextApprover.emp_no)#,"ALL")>
                </cfif>
                <cfif FindNoCase("{REVIEWEE_NAME}",eContent,1)>
                    <cfset eContent = ReplaceNoCase(eContent,"{REVIEWEE_NAME}",#HTMLEDITFORMAT(qGetDetailReviewee.full_name)#,"ALL")>
                </cfif>
                <cfif FindNoCase("{REVIEWEE_EMPNO}",eContent,1)>
                    <cfset eContent = ReplaceNoCase(eContent,"{REVIEWEE_EMPNO}",#HTMLEDITFORMAT(qGetDetailReviewee.emp_no)#,"ALL")>
                </cfif>
                <cfif FindNoCase("{SYS_NAME}",eContent,1)> >
                    <cfset eContent = ReplaceNoCase(eContent,"{SYS_NAME}",#REQUEST.CONFIG.APP_NAME#,"ALL")>
                </cfif>
                <!--- Content --->
                
                <!---
                <cfdump var="eSubject--#eSubject#---eSubject">
                <cfdump var="eContent--#eContent#---eContent">
                --->
                <cfif qGetDetailNextApprover.email neq "">
                    <cfmail from="#REQUEST.CONFIG.ADMIN_EMAIL#" to="#qGetDetailNextApprover.email#" subject="#eSubject#" type="HTML" failto="#REQUEST.CONFIG.ADMIN_EMAIL#">
                        #eContent#
                    </cfmail>
                </cfif>
                
            </cfloop>

            <cfreturn true>
		</cffunction>
    <cffunction name="DeleteAllMonitoringByFormNo">
		<cfparam name="form_no" default="">
		<cfparam name="company_id" default="#REQUEST.Scookie.COID#">
		<cfparam name="company_code" default="#REQUEST.Scookie.COCODE#">
		<cfset local.ReturnVarCheckCompParam = CheckCompanyParamForPerformance()> <!--- TCK0618-81679 ----->
		
		<cftry>	
		    <!--- Get all req No from EvalH--->
			<cfquery name="LOCAL.qGetPerfEvalH" datasource="#REQUEST.SDSN#">
				SELECT request_no,reviewee_posid,period_code FROM TPMDPERFORMANCE_EVALH
				WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
				AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>
			
			<cfquery name="LOCAL.qGetAdjustD" datasource="#REQUEST.SDSN#">
				select adjust_no,form_no from TPMDPERFORMANCE_ADJUSTD
				    WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
				    AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>
            <cfset otherAdjustDNo = qGetAdjustD.adjust_no>
            <cfif qGetAdjustD.recordcount gt 0>
			    <cfquery name="LOCAL.deleteAdjustD" datasource="#REQUEST.SDSN#" result="adjustD">
			        delete from TPMDPERFORMANCE_ADJUSTD
				    WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
				    AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
		    	</cfquery>
            </cfif>
			<cfif otherAdjustDNo neq "">
				<cfquery name="LOCAL.qGetAdjustOtherD" datasource="#REQUEST.SDSN#">
					select adjust_no  from TPMDPERFORMANCE_ADJUSTD
					WHERE adjust_no = <cfqueryparam value="#otherAdjustDNo#" cfsqltype="CF_SQL_VARCHAR"> 
					AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
				</cfquery>
				<cfif qGetAdjustOtherD.recordcount eq 0>
					<cfquery name="LOCAL.deleteAdjustH" datasource="#REQUEST.SDSN#" result="adjustH">
						delete from TPMDPERFORMANCE_ADJUSTH
						WHERE adjust_no = <cfqueryparam value="#otherAdjustDNo#" cfsqltype="CF_SQL_VARCHAR"> 
						AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
					</cfquery>
				</cfif>
			</cfif>
			
		    <cfif qGetPerfEvalH.recordcount eq 0 > <!--- Jika baru di generate tapi belum ada yang submit form, (sudah ada form_no di evalgen)--->
    			<!--- Delete EVALGen --->
    			<cfquery name="LOCAL.qDelPerfEvalGENERATE" datasource="#REQUEST.SDSN#">
    				DELETE FROM TPMDPERFORMANCE_EVALGEN
    				WHERE form_no =  <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    				AND company_id = <cfqueryparam value="#REQUEST.Scookie.COID#" cfsqltype="CF_SQL_VARCHAR">
    			</cfquery>
    			<!--- Delete EVALGen --->
    		</cfif>
			
			<!--- Start delete all Request from this plan no--->
			<cfloop query="qGetPerfEvalH">
    			<cfquery name="LOCAL.qDelPerfPlanREQUEST" datasource="#REQUEST.SDSN#">
    				DELETE FROM TCLTREQUEST
    				WHERE req_no = <cfqueryparam value="#qGetPerfEvalH.request_no#" cfsqltype="CF_SQL_VARCHAR"> 
    				AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
    				AND UPPER(req_type) = 'PERFORMANCE.EVALUATION'
    			</cfquery>
    			
    			<!--- Delete EVALGen --->
    			<cfquery name="LOCAL.qDelPerfEvalGENERATE" datasource="#REQUEST.SDSN#">
    				DELETE FROM TPMDPERFORMANCE_EVALGEN
    				WHERE req_no = <cfqueryparam value="#qGetPerfEvalH.request_no#" cfsqltype="CF_SQL_VARCHAR"> 
    				AND form_no =  <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    				AND company_id = <cfqueryparam value="#REQUEST.Scookie.COID#" cfsqltype="CF_SQL_VARCHAR">
    			</cfquery>
    			<!--- Delete EVALGen --->
    			
    			<!---Delete EvalKPI by org unit reviewee_id--->
	            <cfquery name="local.qGetOrgUnit" datasource="#request.sdsn#">
	                SELECT dept_id FROM TEOMPOSITION
	                WHERE position_id = <cfqueryparam value="#qGetPerfEvalH.reviewee_posid#" cfsqltype="cf_sql_integer">
	                    AND company_id = <cfqueryparam value="#REQUEST.Scookie.COID#" cfsqltype="CF_SQL_VARCHAR">
					GROUP BY dept_id
	            </cfquery>
	            <cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
	                SELECT orgunit_id FROM TPMDPERFORMANCE_EVALKPI
	                WHERE orgunit_id = <cfqueryparam value="#qGetOrgUnit.dept_id#" cfsqltype="cf_sql_integer">
	                    AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="cf_sql_varchar">
	                    AND period_code = <cfqueryparam value="#qGetPerfEvalH.period_code#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            <cfif qGetLibraryDetails.recordcount neq 0>
    				<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">	
    					DELETE FROM TPMDPERFORMANCE_EVALKPI
    					WHERE  orgunit_id = <cfqueryparam value="#qGetOrgUnit.dept_id#" cfsqltype="cf_sql_integer">
	                    AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="cf_sql_varchar">
	                    AND period_code = <cfqueryparam value="#qGetPerfEvalH.period_code#" cfsqltype="cf_sql_varchar">
    				</cfquery>
	            </cfif>
    			<!---Delete EvalKPI by org unit reviewee_id--->
    			
			</cfloop>
			<!--- Start delete all Request from this plan no--->
		    <!--- Get all req No from planH--->
		
		
    		<cfquery name="LOCAL.qDelPerfEvalNote" datasource="#REQUEST.SDSN#">
    			DELETE FROM TPMDPERFORMANCE_EVALNOTE
    			WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    			AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
    		</cfquery>
    		
    		<cfquery name="LOCAL.qDelPerfEvalD" datasource="#REQUEST.SDSN#">
    			DELETE FROM TPMDPERFORMANCE_EVALD
    			WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    			AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
    		</cfquery>
	
    		<cfquery name="LOCAL.qDelPerfEvalH" datasource="#REQUEST.SDSN#">
    			DELETE FROM TPMDPERFORMANCE_EVALH
    			WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    			AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
    		</cfquery>
    		
    		<cfquery name="LOCAL.qDelPerfFINAL" datasource="#REQUEST.SDSN#">
    			DELETE FROM TPMDPERFORMANCE_FINAL
    			WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    			AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
    		</cfquery>
    		<!---Additional deduction--->
    		<cfquery name="LOCAL.qDelPerfAttCompPoint" datasource="#REQUEST.SDSN#">
    			DELETE FROM TPMDEVALD_COMPPOINT
    			WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    		</cfquery>
		
			<!--- Delete Attachment --->
            <cfquery name="LOCAL.qGetExistingEvalTech" datasource="#request.sdsn#">
                SELECT form_no, file_attachment
                FROM TPMDPERF_EVALATTACHMENT 
                WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar"> 
                    AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
            </cfquery>
            
            <cfloop query="qGetExistingEvalTech">
                <CF_SFUPLOAD ACTION="DELETE" CODE="evalattachment" FILENAME="#qGetExistingEvalTech.file_attachment#" output="xlsuploadedDelete">
            </cfloop>

            <cfquery name="LOCAL.qDeleteAttachment" datasource="#request.sdsn#">
                DELETE FROM TPMDPERF_EVALATTACHMENT 
                WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar"> 
                    AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
            </cfquery>
			<!--- Delete Attachment --->
    		
			<cfset LOCAL.retVarReturn=true>
			<cfcatch>
			    <cfset LOCAL.retVarReturn=false>
			</cfcatch>
        </cftry>
        
        <cfreturn retVarReturn>
	    
	</cffunction>
	</cfcomponent>

