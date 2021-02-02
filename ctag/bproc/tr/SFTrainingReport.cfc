<cfcomponent displayname="SFTrainingReport" hint="SunFish Training Report Business Process Object" extends="sfcomp.bproc.pm.SFPerformReport">

	
	<cffunction name="filterCourseForEventReport">
		<cfparam name = "cal_enddate" default="">
		<cfparam name = "cal_startdate" default="">
		<cfparam name = "startdate" default="">
		<cfparam name = "enddate" default="">
		<cfparam name = "nametype" default="">
		<cfparam name = "trnevent_sts" default="">
		
		<cfparam name="search" default="">
		<cfparam name="nrow" default="0">
		<cfparam name="REQUEST.KeyFields" default="">
		<cfif val(nrow) eq "0">
			<cfset nrow="50">
		</cfif>
		<cfset LOCAL.searchText=trim(search)>
		
		<cfquery name="qGetAllCourse" datasource="#REQUEST.SDSN#">
			SELECT distinct ttrdtrainevent.trncourse_code,trncourse_name_#REQUEST.SCookie.LANG# trncourse_name
			from ttrdtrainevent inner join TTRDTRAINCOURSE ON  ttrdtrainevent.trncourse_code = TTRDTRAINCOURSE.trncourse_code 
			where 
			<!---(trnevent_startdate BETWEEN #createODBCDate(startdate)# AND #createODBCDate(enddate)#
			OR trnevent_enddate BETWEEN #createODBCDate(startdate)# AND #createODBCDate(enddate)#)---->
			(trnevent_startdate >= '#DateFormat(startdate,'yyyy-mm-dd')#' AND trnevent_enddate <= '#DateFormat(enddate,'yyyy-mm-dd')#') 
			
		    <cfif len(searchText)>
			    AND (ttrdtrainevent.trncourse_code LIKE <cfqueryparam value="%#searchText#%" cfsqltype="CF_SQL_VARCHAR">  OR trncourse_name_#REQUEST.SCookie.LANG# LIKE <cfqueryparam value="%#searchText#%" cfsqltype="CF_SQL_VARCHAR">)
			</cfif>
			<cfif trnevent_sts neq "">
			    AND ttrdtrainevent.trnevent_sts = #trnevent_sts#    
			</cfif>
			<cfif nametype neq "">
			AND (UPPER(ttrdtrainevent.trnevent_type) = '#UCASE(nametype)#')
			</cfif>
			
		</cfquery>
		
		<!---<cf_sfwritelog folder="TrnReqData" dump="qGetAllCourse" prefix="qGetAllCourse"> ---->
		<cfset lstallcourse = "">
		
		<cfif qGetAllCourse.recordcount neq 0>
			<cfset lstallcourse = valuelist(qGetAllCourse.trncourse_code)>
		</cfif>
		<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("FDTrainingCourse",true,"+")>
		<cfset LOCAL.vResult="">
		<cfloop query="qGetAllCourse">
			<cfset vResult=vResult & "arrEntryList[#currentrow-1#]=""#JSStringFormat(trncourse_code & "=" & "[#trncourse_code#]"&" "&"#trncourse_name#")#"";">
		</cfloop>
		<cfset tempLabel = SFLANG & " (#qGetAllCourse.recordcount#)">
		
		<cfoutput>
		<script>
				try {
						
						if($sf("lbl_inp_allcourse")) {
							$sf("lbl_inp_allcourse").innerHTML = "#tempLabel# <span class=\"required\">*</span>";
						}
						if($sf("lbl_inp_course")) {
							$sf("lbl_inp_course").innerHTML = "";
						}
						if($sf("inp_coursesel")) { 
							$sf("inp_coursesel").value = "#lstallcourse#";
						}
						
				}
				catch(err) {

				}
			arrEntryList=new Array();
			#vResult#
		</script>
		</cfoutput>
	</cffunction>

	<!--- yang dipakai cuma func rptTrainingEventCustom dan yang filterEventForEventReport--->
	<cffunction name="rptTrainingEventCustom">
		<cfparam name="inp_startdate" default="">
		<cfparam name="inp_enddate" default="">
		<cfparam name="inp_nametype" default="">
		<cfparam name="inp_trnevent_sts" default="">
		<!--- muadz param untuk event code--->
		<cfparam name="hdnSelectedinp_course" default="">
		<!--- muadz param untuk event code--->
		<cfparam name="inp_allcourse" default="">
		
		<cfset local.FORMMLANG="Notitik|StartDate|EndDate|Days|Hours|Participants|Positions|Departments|FDTotParticipantPerDept|FDTrainingDate|JSTo|FDProviderType|FDTrainingEventStatus|FDTotParticipant|FDCapacity|FDSubject|FDTopic|FDProvider|FDVenue|FDTrainingCost">
		<cfset REQUEST.SFMLANG=Application.SFParser.TransMLang(listAppend("Training Course",(isdefined("FORMMLANG")?FORMMLANG:""),"|"))>
		
		<cfoutput>
			<cfloop list="#hdnSelectedinp_course#" item="item">
				<cfquery name="qTrainingEvent" datasource="#request.sdsn#">		
					select
					a.trnevent_code,a.trnevent_topic,d.trncourse_name_#REQUEST.SCookie.LANG# course_name,a.trnevent_startdate,a.trnevent_enddate, 
					<!--- muadz nambahin background, obj, remark, target --->
					(select name_en from ttrmtype where code=d.type_code) type_name, n.acceptcriteria, o.trnevent_enablecertified, p.cert_attach, n.trnevent_bckground,n.trnevent_obj,n.trnevent_remark,n.trnevent_target, n.delivmethod, n.evalmethod, 
					REPLACE(REPLACE(n.material, CHAR(13),'<br/>'),'  ', '&nbsp;nbsp;') material, r.score, a.request_no,
					<!--- muadz nambahin background, obj, remark, target --->
					(
					select
						count(trnevent_code) as day
					from
						TTRRTRAINEVENTACTIVITY
					where
						trnevent_code = a.trnevent_code
						and company_code = a.company_code ) as day,
					(
					-- muadz biar ambil dari tr att
					select
						count(distinct t.emp_id)
					from
						ttrdtrainattmember t
					join TEOMEMPPERSONAL c on
						t.emp_id = c.emp_id
					join TEODEMPCOMPANY d on
						c.emp_id = d.emp_id
					join ttrrtraineventactivitytime e on
						e.trneventactivity_code = t.trneventactivity_code 
						where
						e.trnevent_code = a.trnevent_code
						and flag_present = 'Y'
						and t.company_code = a.company_code ) as total,
					(
						-- muadz biar ambil dari tr att
					select
						count(distinct e.position_id)
					from
						ttrdtrainattmember b
					join TEOMEMPPERSONAL c on
						b.emp_id = c.emp_id
					join TEODEMPCOMPANY d on
						c.emp_id = d.emp_id
						and d.company_id = 13852
					join TEOMPOSITION e on
						d.position_id = e.position_id
						left join TEOMPOSITION f on
						f.position_id = e.dept_id
						and f.company_id = 13852
					join ttrrtraineventactivitytime g on
						g.trneventactivity_code = b.trneventactivity_code 
						where
						flag_present = 'Y' and
						trnevent_code = a.trnevent_code
						and b.company_code = a.company_code
						and e.dept_id = i.dept_id
						and e.position_id =
						(case
						when i.dept_id = 0 then i.position_id
						else e.position_id
						end) ) as totalPerDept,
					(
					select
						count(d.position_id)
					from
						TTRRTRAINEVENTMEMBER b
					join TEOMEMPPERSONAL c on
						b.emp_id = c.emp_id
					join TEODEMPCOMPANY d on
						c.emp_id = d.emp_id
						and d.company_id = #REQUEST.SCookie.coid#
					where
						trnevent_code = a.trnevent_code
						and company_code = a.company_code
						and d.position_id = 0 ) as totalPerDeptZero,
					a.trnevent_capacity,
					<cfif request.dbdriver eq "MSSQL">
						case
							when cast(coalesce(sum(b.trnevent_totalhour),
							0) as integer)% 60 = 0 then cast(coalesce(sum(b.trnevent_totalhour)/ 60,0) as varchar(max))
						else 
							cast(cast(coalesce(sum(b.trnevent_totalhour),0)/ 60 as integer) as varchar(max)) + cast(substring(cast(ROUND(cast(coalesce(sum(b.trnevent_totalhour), 0) as float)/ 60, 2) as varchar), CHARINDEX('.', ROUND(cast(coalesce(sum(b.trnevent_totalhour), 0) as float)/ 60, 2)), 3) as varchar(max)) END
					<cfelse>
						case
							when cast(coalesce(sum(b.trnevent_totalhour),0) as integer)% 60 = 0 then cast(coalesce(sum(b.trnevent_totalhour)/ 60,0) as char(20))
						else cast(cast(coalesce(sum(b.trnevent_totalhour),0)/ 60 as integer) as char(20)) || substring(cast(ROUND(coalesce(sum(b.trnevent_totalhour), 0)/ 60, 2) as char(50)), SUBSTRING_INDEX(ROUND(coalesce(sum(b.trnevent_totalhour), 0)/ 60, 2), '.', 1), 3) end
					</cfif>
					hour, e.provider_name,
					f.venue_name,
					j.name room_name,
					d.currency_cost,
					d.trncourse_cost,
					case
						when len(k.Full_Name) >= 0 then 
						<cfif request.dbdriver eq "MSSQL" >
							k.Full_Name + ' (' + h.emp_no + ')' 
						<cfelseif request.dbdriver eq "MYSQL">
							CONCAT(k.Full_Name,' (',h.emp_no,')') 
						</cfif>
					else 'No Participant Joined / Assigned'
					end Full_name,
					i.pos_name_#REQUEST.SCookie.LANG# posit,
					case
					when i.dept_id <> 0
					and i.dept_id is not null
					and m.pos_name_#REQUEST.SCookie.LANG# is not null then m.pos_name_#REQUEST.SCookie.LANG#
					else i.pos_name_#REQUEST.SCookie.LANG#
					end as dept,
					<cfif request.dbdriver eq "MSSQL">
						a.trnevent_code + (case when i.dept_id <> 0
							and i.dept_id is not null
							and m.pos_name_#REQUEST.SCookie.LANG# is not null then m.pos_name_#REQUEST.SCookie.LANG#
							else i.pos_name_#REQUEST.SCookie.LANG#
							end) as deptUnique 
					<CFELSEIF request.dbdriver eq "MYSQL">
						CONCAT(a.trnevent_code , (case when i.dept_id <> 0 and i.dept_id is not null and m.pos_name_#REQUEST.SCookie.LANG# is not null then m.pos_name_#REQUEST.SCookie.LANG#
						else i.pos_name_#REQUEST.SCookie.LANG#
						end)) as deptUnique
					</CFIF>
					from
					TTRDTRAINEVENT a
					left join TTRRTRAINEVENTACTIVITY b on
					a.trnevent_code = b.trnevent_code
					and a.company_code = b.company_code
					left join ttrrtraineventactivitytime q on
					-- q.trneventactivity_code = g.trneventactivity_code and
					q.trnevent_code = a.trnevent_code 
					left join TTRRTRAINEVENTVENUE c on
					a.trnevent_code = c.trnevent_code
					and a.company_code = c.company_code
					left join TTRDTRAINCOURSE d on
					a.trncourse_code = d.trncourse_code
					and a.company_code = d.company_code
					left join TTRMPROVIDER e on
					c.provider_code = e.provider_code
					and c.company_code = e.company_code
					left join TTRMVENUE f on
					c.venue_code = f.venue_code
					and c.company_code = f.company_code
					left join ttrdtrainattmember g on
					g.trneventactivity_code = q.trneventactivity_code 
					and a.company_code = g.company_code
					and flag_present = 'Y'
					/*left join TTRRTRAINEVENTMEMBER g on
					a.trnevent_code = g.trnevent_code
					and a.company_code = g.company_code*/
					left join TEODEMPCOMPANY h on
					g.emp_id = h.emp_id
					and h.company_id = #REQUEST.SCookie.COID#
					left join TEOMPOSITION i on
					h.position_id = i.position_id
					left join TTRMROOMTYPE j on
					c.room_code = j.code
					and j.venue_code = c.venue_code
					left join TEOMEMPPERSONAL k on
					h.emp_id = k.emp_id
					left join TEOMPOSITION l on
					h.position_id = l.position_id
					and h.company_id = l.company_id
					left join TEOMPOSITION m on
					m.position_id = i.dept_id
					and m.company_id = i.company_id
					<!--- muadz nambahin join tiga lagi --->
					left join ttrrtraineventinfo n on
					n.trnevent_code = a.trnevent_code
					left join ttrrtraineventother o on
					o.trnevent_code = a.trnevent_code
					left join TEODEMPCERTIFICATION p on
					p.flag_training = a.trnevent_code and
					p.emp_id = h.emp_id 
					left join ttrdmemberevaluatedet r on
					r.trnevent_code = a.trnevent_code and
					r.emp_id = g.emp_id
					where
					a.company_code = '#REQUEST.SCookie.COCODE#'
					and a.trnevent_startdate >= #createODBCDate(inp_startdate)#
					and a.trnevent_enddate <= #createODBCDate(inp_enddate)#
						<CFIF inp_allcourse NEQ '1' >
							and a.trnevent_code in ('#item#')
						</CFIF>
						<CFIF inp_trnevent_sts neq ''>
							AND a.trnevent_sts = '#inp_trnevent_sts#' 
						</CFIF>
					AND a.trnevent_type = '#inp_nametype#'
					group by
					a. trnevent_code,
					a.company_code,
					a.trnevent_topic,
					d.trncourse_name_#REQUEST.SCookie.LANG#,
					a.trnevent_startdate,
					a.trnevent_enddate,
					e.provider_name,
					f.venue_name,
					d.currency_cost,
					d.trncourse_cost,
					k.Full_name,
					i.pos_name_#REQUEST.SCookie.LANG#,
					i.position_id,
					h.position_id,
					m.pos_name_#REQUEST.SCookie.LANG# ,
					l.position_id,
					l.parent_id,
					i.parent_id,
					l.pos_name_#REQUEST.SCookie.LANG# ,
					i.dept_id,
					m.position_id,
					m.pos_name_#REQUEST.SCookie.LANG# ,
					a.trnevent_capacity,
					g.emp_id,
					h.emp_no,
					j.name
					order by
					trnevent_startdate asc,
					a.trnevent_code,
					dept asc,
					full_name asc
				</cfquery>
				<!---<cfdump  var="#qTrainingEvent#">--->

				<cfif qTrainingEvent.delivmethod neq ''>
					<cfquery name="qHeaderDeliv" datasource="#request.sdsn#">
						select name_en from tctmdelivmethod where code in 
						(#listqualify(preservesinglequotes(qTrainingEvent.delivmethod),"'")#)
					</cfquery>
				</cfif>

				<cfif qTrainingEvent.evalmethod neq ''>
					<cfquery name="qHeaderEval" datasource="#request.sdsn#">
						select name_en from tctmevalmethod where code in (#listqualify(preservesinglequotes(qTrainingEvent.evalmethod),"'")#)
					</cfquery>
				</cfif>

				<cfquery name="qInstructor" datasource="#request.sdsn#">
					select trnevent_code,instructor_code,trnevent_type 
					from ttrrtraineventinstructor t 
					where trnevent_code = '#item#'
				</cfquery>


				<div style="text-align: justify;"></div>
				<!---muadz table header--->
				<table width="100%">
					<tr>
						<td colspan="2" style="text-align: center; font-size: 18px;"><strong>SUBJECT: BEHAVIOR EVENT INTERVIEW</strong></td>
					</tr>
					<tr>
						<td>&nbsp;</td>
					</tr>
					<tr>
						<td><strong>BACKGROUND: </strong>#qTrainingEvent.trnevent_bckground#</td>
					</tr>
					<tr>
						<td><strong>OBJECTIVE: </strong>#qTrainingEvent.trnevent_obj#</td>
					</tr>
					<tr>
						<td><strong>TARGET PARTICIPANTS: </strong>#qTrainingEvent.trnevent_target#</td>
					</tr>
					<tr>
						<td><strong>TOPIC: </strong>#qTrainingEvent.trnevent_topic#</td>
					</tr>
					<tr>
						<td><strong>PROVIDER: </strong>#qTrainingEvent.provider_name#</td>
					</tr>
					<tr>
						<td><strong>VENUE: </strong>#qTrainingEvent.venue_name#</td>
					</tr>
					<tr>
						<td style="text-align:center; font-size:18px" colspan="2"><strong>METHOD</strong></td>
					</tr>
					<tr>
						<td>&nbsp;</td>
					</tr>
					<tr>
						<td><strong>Training Type: </strong></td>
						<td><strong>Delivery Method: </strong></td>
					</tr>
					<tr>
						<td width="50%">#qTrainingEvent.type_name#</td>
						<td width="50%">
						<cfif isDefined("qHeaderDeliv")>
							<cfloop query="qHeaderDeliv">
								<cfif queryRecordCount(qHeaderDeliv) eq queryCurrentRow(qHeaderDeliv)>
									#name_en#
								<cfelse>
									#name_en#,
								</cfif>
							</cfloop>
						<cfelse>
							Not Available
						</cfif>
						</td>
					</tr>
					<tr>
						<td><strong>Evaluation: </strong></td>
						<td><strong>Evaluation Method: </strong></td>
					</tr>
					<tr>
						<td>#(qTrainingEvent.evalmethod neq 'NOTAVAIL' ? 'Available' : 'Not Available')#</td>
						<td>#isDefined("qHeaderEval") ? qHeaderEval.name_en: 'Not Available'#</td>
					</tr>
					<tr>
						<td><strong>Acceptance Criteria:</strong></td>
						<td><strong>Certificate: </strong></td>
					</tr>
					<tr>
						<td>#qTrainingEvent.evalmethod neq '' and qTrainingEvent.evalmethod neq 'NOTAVAIL' ? qTrainingEvent.acceptcriteria : 'Not Available'#</td>
						<td>#(qTrainingEvent.trnevent_enablecertified eq 'Y' ? 'Available' : 'Not Available')#</td>
					</tr>
					<tr>
						<td>&nbsp;</td>
					</tr>
					<tr>
						<td colspan="2"><strong>Material/Content: </strong>#qTrainingEvent.material#</td>
					</tr>
					<tr>
						<td>
							<strong>
								#REQUEST.SFMLANG["FDTrainingDate"]# :
							</strong>
							#dateFormat(inp_startdate,REQUEST.config.DATE_OUTPUT_FORMAT)# 
							<strong>
								#REQUEST.SFMLANG["JSTo"]# 
							</strong>
							#dateFormat(inp_enddate,REQUEST.config.DATE_OUTPUT_FORMAT)#
						</td>
					</tr>
					<tr>
						<td>
							<strong>#REQUEST.SFMLANG["FDProviderType"]# : </strong> 
							<CFIF inp_nametype eq 'INTERNAL'> 
									Internal
							<CFELSE>
									External
							</CFIF>
						</td>
					</tr>
					<tr>
						<td>
							<strong>#REQUEST.SFMLANG["FDTrainingEventStatus"]# : </strong> 
							<cfif inp_trnevent_sts eq ''>
								All
							<cfelseif inp_trnevent_sts eq '1'>
								Draft 
							<cfelseif inp_trnevent_sts eq '2'>
								Open for Registration 
							<cfelseif inp_trnevent_sts eq '3'>
								Closed Registration 
							<cfelseif inp_trnevent_sts eq '4'> 
								Concluded 
							<cfelse> 
								Cancelled 
							</cfif>
						</td>
					</tr>
				</table>

				<!---
					<div style="text-align: left;">
						<strong>BACKGROUND: </strong>#qTrainingEvent.trnevent_bckground#
					</div>
					<div style="text-align: left;">
						<br><strong>OBJECTIVE: </strong>#qTrainingEvent.trnevent_obj#
					</div>
					<div style="text-align: left;">
						<br><strong>TARGET PARTICIPANTS: </strong>#qTrainingEvent.trnevent_target#
					</div>
					<div style="text-align: left;">
						<br><strong>TOPIC: </strong>#qTrainingEvent.trnevent_topic#
					</div>				
					<div style="text-align: left;">
						<br><strong>PROVIDER: </strong>#qTrainingEvent.provider_name#
					</div>
					<div style="text-align: left;">
						<br><strong>VENUE: </strong>#qTrainingEvent.venue_name#
					</div>
					<div style="text-align: center; font-size: 18px;">
						<br><strong>METHOD</strong>
					</div>
					<div style="text-align: left; display:inline-block; width:50%;"><br><br><strong>Training Type: </strong><br>#qTrainingEvent.type_name#</div><cfif qTrainingEvent.delivmethod neq ''><div style="text-align: left; display:inline-block; width:50%;"><br><br><strong>Delivery Method: </strong><br>
							<cfloop query="qHeaderDeliv">
								<cfif queryRecordCount(qHeaderDeliv) eq queryCurrentRow(qHeaderDeliv)>
									#name_en#
								<cfelse>
									#name_en#,
								</cfif>
							</cfloop></div></cfif>
					<cfif qTrainingEvent.evalmethod neq ''>
						<div style="text-align: left; display:inline-block; width:50%;"><br><br><strong>Evaluation: </strong><br>#(qTrainingEvent.evalmethod neq 'NOTAVAIL' ? 'Available' : 'Not Available')#</div><div style="text-align: left; display:inline-block; width:50%;"><br><br><strong>Evaluation Method: </strong><br>#qHeaderEval.name_en#</div>
					</cfif>
					<div style="text-align: left; display:inline-block; width:50%;"><br><strong>Acceptance Criteria: </strong><br>#qTrainingEvent.acceptcriteria#</div><div style="text-align: left; display:inline-block; width:50%;"><br><strong>Certificate: </strong><br>#(qTrainingEvent.trnevent_enablecertified eq 'Y' ? 'Available' : 'Not Available')#</div>
					<div style="text-align: left;">
						<br><strong>Material/Content: </strong>
						#qTrainingEvent.material#
					</div>
					<div style="text-align: left;">
						<br>
						<strong>
							#REQUEST.SFMLANG["FDTrainingDate"]# :
						</strong>
						#dateFormat(inp_startdate,REQUEST.config.DATE_OUTPUT_FORMAT)# 
						<strong>
							#REQUEST.SFMLANG["JSTo"]# 
						</strong>
						#dateFormat(inp_enddate,REQUEST.config.DATE_OUTPUT_FORMAT)#
					</div>
					<div style="text-align: left;">
						<strong>#REQUEST.SFMLANG["FDProviderType"]# : </strong> 
						<CFIF inp_nametype eq 'INTERNAL'> 
								Internal
						<CFELSE>
								External
						</CFIF>
					</div>
					<div style="text-align: left;">
						<strong>#REQUEST.SFMLANG["FDTrainingEventStatus"]# : </strong> 
							<cfif inp_trnevent_sts eq ''>
								All
							<cfelseif inp_trnevent_sts eq '1'>
								Draft 
							<cfelseif inp_trnevent_sts eq '2'>
								Open for Registration 
							<cfelseif inp_trnevent_sts eq '3'>
								Closed Registration 
							<cfelseif inp_trnevent_sts eq '4'> 
								Concluded 
							<cfelse> 
								Cancelled 
							</cfif>
					</div>
				--->

				<br>
				<!---muadz table absen dll--->
				<table width="100%" cellspacing="1" cellpadding="1" border="1">
					<tbody>
						<!---header table --->
						<tr>
							<td align="center"><strong>#REQUEST.SFMLANG["Notitik"]#</strong></td>
							<td width="40" align="center"><strong>#REQUEST.SFMLANG["StartDate"]#</strong></td>
							<td width="40" align="center"><strong>#REQUEST.SFMLANG["EndDate"]#</strong></td>
							<td align="center"><strong>#REQUEST.SFMLANG["Days"]#</strong></td>
							<!---<td align="center"><strong>#REQUEST.SFMLANG["Hours"]#</strong></td>--->
							<td nowrap="" align="center"><strong>#REQUEST.SFMLANG["Participants"]#</strong></td>
							<td style="text-align: center;"><strong>Score</strong></td>
							<td style="text-align: center;"><strong>Status</strong></td>
							<td nowrap="" align="center"><strong>#REQUEST.SFMLANG["Positions"]#</strong></td>
							<td nowrap="" align="center"><strong>#REQUEST.SFMLANG["Departments"]#</strong></td>
							<td align="center"><strong>Tot. Participant(s)</strong></td>
							<!---<td align="center"><strong>#REQUEST.SFMLANG["FDTotParticipant"]#</strong></td>
							<td align="center"><strong>#REQUEST.SFMLANG["FDCapacity"]#</strong></td>
							<td nowrap="" align="center"><strong>#REQUEST.SFMLANG["FDSubject"]#</strong></td>--->
							<td nowrap="" align="center"><strong>Instructor</strong></td>
							<!---<td nowrap="" align="center"><strong>#REQUEST.SFMLANG["FDTopic"]#</strong></td>
							muadz nambahin td baru bg, obj, target, remark
							<td nowrap="" align="center"><strong>Background</strong></td>
							<td nowrap="" align="center"><strong>Objective</strong></td>
							<td nowrap="" align="center"><strong>Target</strong></td>
							<td nowrap="" align="center"><strong>Remark</strong></td>
							muadz nambahin td baru bg, obj, target, remark
							<td align="center"><strong>#REQUEST.SFMLANG["FDProvider"]#</strong></td>
							<td align="center"><strong>#REQUEST.SFMLANG["FDVenue"]#</strong></td>
							<td style="text-align: center;" colspan="2"><strong>#REQUEST.SFMLANG["FDTrainingCost"]#</strong></td>--->
							<td width="40" style="text-align: center;"><strong>Certificate</strong></td>
						</tr>
						<cfset counterzz = 0>
						<CFSET FLAG = 0>
						<CFSET oldTrnEvent = "">
						<cfset oldTrnDept = ''>
						<CFSET countNo = 0>
						<cfloop query="qTrainingEvent">
							<cfset rowspan2 = qTrainingEvent.recordcount>
							<cfset rowspan3 = qTrainingEvent.total>
							<cfquery name="qGetSumCost" datasource="#request.sdsn#">
								SELECT currency_code,totalevent_cost FROM TTRDEVENTSUMCOST WHERE trnevent_code = '#qTrainingEvent.trnevent_code#'
							</cfquery>
							<cfif qTrainingEvent.total lt qGetSumCost.recordcount>
								<cfset counterzz++>
								<cfif counterzz lt qTrainingEvent.total>
									<cfset rowspan4 = 1>
								<cfelseif qTrainingEvent.total eq 1>
									<cfset rowspan4 = 1>
									<cfset counterzz = 0>
								<cfelse>
									<cfset rowspan4 = val(qGetSumCost.recordcount - counterzz) >
									<cfset counterzz = 0>
								</cfif>
							<cfelse>
								<cfset rowspan4 = 1>
							</cfif>
							
							<CFIF qGetSumCost.recordcount neq 0>
								<CFSET ROWSPAN = 1>
								<CFSET FLAG = 1>
							<CFELSE>
								<CFSET ROWSPAN = qTrainingEvent.total>
								<CFSET FLAG ++ >
							</CFIF>
							
							<TR>
								<CFIF oldTrnEvent NEQ qTrainingEvent.trnevent_code>
									<CFSET countNo++>
									<td align="center" rowspan="#(rowspan3 eq 0 ? 1 : rowspan3)#">
										#countNo#
									</td>
								</CFIF>
								
								<cfif oldTrnEvent neq qTrainingEvent.trnevent_code> 
									<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="center">
										#DATEFORMAT(qTrainingEvent.trnevent_startdate,REQUEST.CONFIG.DATE_INPUT_FORMAT)# 
									</td>
								</cfif>
								
								<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
									<td rowspan="#(rowspan3 eq 0 ? 1 : rowspan3)#" align="center">
										#DATEFORMAT(qTrainingEvent.trnevent_enddate,REQUEST.CONFIG.DATE_INPUT_FORMAT)#
									</td>
								</CFIF>
								
								<cfif oldTrnEvent neq qTrainingEvent.trnevent_code>
									<td rowspan="#(rowspan3 eq 0 ? 1 : rowspan3)#" align="right">
										#qTrainingEvent.day#
									</td>
								</cfif>
								
								<!---<cfif oldTrnEvent neq qTrainingEvent.trnevent_code>
									<td rowspan="#(rowspan3 eq 0 ? 1 : rowspan3)#" align="right">
										#qTrainingEvent.HOUR#
									</td>
								</cfif>--->
								
								<td rowspan="#(rowspan4 eq 0 ? 1 : rowspan4) #" nowrap="">#HTMLEDITFORMAT(qTrainingEvent.full_name)#</td>
								<td rowspan="#(rowspan4 eq 0 ? 1 : rowspan4) #" nowrap="" align="right">#HTMLEDITFORMAT(qTrainingEvent.score)#</td>
								<td rowspan="#(rowspan4 eq 0 ? 1 : rowspan4) #" nowrap="" align="right">#(qTrainingEvent.score gte qTrainingEvent.acceptcriteria ? 'Pass' : 'Fail')#</td>
								<td rowspan="#(rowspan4 eq 0 ? 1 : rowspan4)#" nowrap="">#HTMLEDITFORMAT((len(qTrainingEvent.posit) eq 0 ? '-' : qTrainingEvent.posit ))#</td>
								<td rowspan="#(rowspan4 eq 0 ? 1 : rowspan4)#" nowrap="">#HTMLEDITFORMAT((len(qTrainingEvent.dept) eq 0 ? '-' : qTrainingEvent.dept))#</td>
								
								<!---<cfif len(qTrainingEvent.deptUnique) eq 0 or oldTrnDept neq qTrainingEvent.deptUnique>
									<td rowspan="#((qTrainingEvent.totalPerDept NEQ 0 ? qTrainingEvent.totalPerDept : qTrainingEvent.totalPerDeptZero)) eq 0 ? 1 : (qTrainingEvent.totalPerDept NEQ 0 ? qTrainingEvent.totalPerDept : qTrainingEvent.totalPerDeptZero)#" align="right">
										#qTrainingEvent.totalPerDept#
									</td>
								</cfif>--->
								
								<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
									<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
										#qTrainingEvent.total#
									</td>
								</CFIF>
								
								<!---<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
									<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
										#qTrainingEvent.trnevent_capacity#
									</td>
								</CFIF>
								
								<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
									<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
										#qTrainingEvent.course_name#
									</td>
								</CFIF>
								
								<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
									<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
										#qTrainingEvent.trnevent_topic#
									</td>
								</CFIF>--->
								
								<!---muadz instructor--->
								<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
									<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="left">
										<cfloop query="qInstructor">
											<cfquery name="qGetInstructor" datasource="#request.sdsn#">
												<cfif qInstructor.trnevent_type eq 'I'>
													select Full_Name fn, 'Internal' as type from view_employee where emp_id = '#instructor_code#'
												<cfelse>
													select instructor_name fn, 'External' as type from ttrminstructor where instructor_code = '#instructor_code#'
												</cfif>
											</cfquery>
											<cfif queryRecordCount(qInstructor) eq queryCurrentRow(qInstructor)>
												#qGetInstructor.fn# (#qGetInstructor.type#)
											<cfelse>
												#qGetInstructor.fn# (#qGetInstructor.type#),<br>
											</cfif>
										</cfloop>
									</td>
								</CFIF>

								<!---<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
									<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
										#qTrainingEvent.provider_name#
									</td>
								</CFIF>
								
								<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
									<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
										#qTrainingEvent.venue_name#
									</td>
								</CFIF>
								
								<cfif oldTrnEvent neq qTrainingEvent.trnevent_code>
									<td colspan="2" rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#">
										<table>
											<tbody>
												<cfloop query="qGetSumCost">
													<tr>
														<td>#qGetSumCost.currency_code#</td>
														<td>#qGetSumCost.totalevent_cost#</td>
													</tr>
												</cfloop>
											</tbody>
										</table>
									</td>
								</cfif>--->
								<!---muadz tak tau ini buat apa, tapi kalau dihapus tablenya jadi ngaco, dibiarkan sajalah--->
								<cfset oldTrnEvent =qTrainingEvent.trnevent_code>
								<cfset oldTrnDept = qTrainingEvent.deptUnique>
								<!---<cfif qTrainingEvent.currentrow+1 lte qTrainingEvent.recordcount>
									<cfif qTrainingEvent.total[qTrainingEvent.currentrow] neq qTrainingEvent.total[qTrainingEvent.currentrow+1]>
										<cfquery name="qGetSumCost" datasource="#request.sdsn#">
											SELECT currency_code,totalevent_cost 
											FROM TTRDEVENTSUMCOST 
											WHERE trnevent_code = '#qTrainingEvent.trnevent_code[qTrainingEvent.currentrow+1]#'
										</cfquery>
										<cfif qGetSumCost.recordcount gt qTrainingEvent.total[qTrainingEvent.currentrow+1]>
											<cfset rowspan3 = qTrainingEvent.total[qTrainingEvent.currentrow+1]>
										<cfelse>
											<cfset rowspan3 = qTrainingEvent.total[qTrainingEvent.currentrow+1]>
										</cfif>
									</cfif>
								</cfif>--->
								<td rowspan="#(rowspan4 eq 0 ? 1 : rowspan4) #" nowrap="">
									<cfif qTrainingEvent.cert_attach neq ''>
										<!---<a href="https://sf.plne.co.id/sf6/index.cfm?sfid=sys.util.getfile&download=true&code=empcertificate&fname=#qTrainingEvent.cert_attach#">Download</a>--->
										<a href="?sfid=sys.util.getfile&download=true&code=empcertificate&fname=#qTrainingEvent.cert_attach#">Download</a>
									<cfelse>
										-
									</cfif>
								</td>								
							</TR>
						</cfloop>
					</tbody>
				</table>

				<!---muadz bikin query biar approver yang tampil urutannya sama kayak yang diinput (kalau pakai cfquery aja order by emp_id)--->
				<cfset qGetApprover = queryNew("full_name,dept_name","varchar,varchar")>	

				<cfif inp_empid4 neq '' and inp_empid3 neq '' and inp_empid2 neq '' and inp_empid1 neq ''>
					<cfset empidApproverList = "#hdn_empid1#,#hdn_empid2#,#hdn_empid3#,#hdn_empid4#">
				<cfelseif inp_empid3 neq '' and inp_empid2 neq '' and inp_empid1 neq ''>
					<cfset empidApproverList = "#hdn_empid1#,#hdn_empid2#,#hdn_empid3#">
				<cfelseif inp_empid2 neq '' and inp_empid1 neq ''>
					<cfset empidApproverList = "#hdn_empid1#,#hdn_empid2#">
				<cfelseif inp_empid1 neq ''>
					<cfset empidApproverList = "#hdn_empid1#">
				<cfelse>
					<cfset empidApproverList = "">
				</cfif>

				<cfloop list="#empidApproverList#" item="item">
					<cfquery name="qGetAppr" datasource="#request.sdsn#">
						select Full_Name,(select pos_name_en from teomposition where ve.pos_code=pos_code) dept_name from view_employee ve where emp_id = '#item#'
					</cfquery>
					<cfset addRow = queryAddRow(qGetApprover,{full_name=qGetAppr.full_name,dept_name=qGetAppr.dept_name})>	
				</cfloop>

				<!---<cfquery name="qGetApprover" datasource="#request.sdsn#">
					select Full_Name,(select pos_name_en from teomposition where ve.pos_code=pos_code) dept_name from view_employee ve where emp_id in ( '#(inp_empid1 neq ''?hdn_empid1:'')#', '#(inp_empid2 neq ''?hdn_empid2:'')#', '#(inp_empid3 neq ''?hdn_empid3:'')#', '#(inp_empid4 neq ''?hdn_empid4:'')#' )
				</cfquery>--->
				<!---<cfdump  var="#qGetApprover#">--->
				
				<!---hardcode posid ke head of tnd--->
				<cfquery name="qGetVerify" datasource="#request.sdsn#">
					select Full_Name,(select pos_name_en from teomposition where ve.pos_code=pos_code) dept_name from view_employee ve
					where position_id = '372'
				</cfquery>
				<cfquery name="qGetInitiator" datasource="#request.sdsn#">
					select Full_Name,(select pos_name_en from teomposition where ve.pos_code=pos_code) dept_name from view_employee ve
					where emp_id = (select reqemp from tcltrequest t where req_no = <cfqueryparam value="#qTrainingEvent.request_no#" cfsqltype="CF_SQL_VARCHAR">)
				</cfquery>

				<!---
					<cfif isDefined("hdn_empid4")>
						<cfloop index="index" from="1" to="4">
							<div style="text-align: center; padding-top: 20%; display:inline-block; width:19%;">Approver</div>
						</cfloop>
						<div style="text-align: center; padding-top: 20%; float:right; display:inline-block; width:19%;">Verify</div>
						<br><br><br><br><br><br><br><br>
						<cfloop query="qGetApprover">
							<div style="text-align: center; display:inline-block; width:19%;"><u>#qGetApprover.Full_Name#</u><br>#qGetApprover.dept_name#</div>
						</cfloop>
						<div style="text-align: center; float:right; display:inline-block; width:19%;"><u>#qGetVerify.Full_Name#</u><br>#qGetVerify.dept_name#</div>
					<cfelseif isDefined("hdn_empid3")>
						<cfloop index="index" from="1" to="3">
							<div style="text-align: center; display:inline-block; width:26%;">Approver</div>
						</cfloop>
						<div style="text-align: center; float:right; display:inline-block; width:19%;">Verify</div>
						<br><br><br><br><br><br><br><br>
						<cfloop query="qGetApprover">
							<div style="text-align: center; display:inline-block; width:26%;"><u>#qGetApprover.Full_Name#</u><br>#qGetApprover.dept_name#</div>
						</cfloop>
						<div style="text-align: center; float:right; display:inline-block; width:19%;"><u>#qGetVerify.Full_Name#</u><br>#qGetVerify.dept_name#</div>
					<cfelseif isDefined("hdn_empid2")>
						<cfloop index="index" from="1" to="2">
							<div style="text-align: center; display:inline-block; width:40%;">Approver</div>
						</cfloop>
						<div style="text-align: center; float:right; display:inline-block; width:19%;">Verify</div>
						<br><br><br><br><br><br><br><br>
						<cfloop query="qGetApprover">
							<div style="text-align: center; display:inline-block; width:40%;"><u>#qGetApprover.Full_Name#</u><br>#qGetApprover.dept_name#</div>
						</cfloop>
						<div style="text-align: center; float:right; display:inline-block; width:20%;"><u>#qGetVerify.Full_Name#</u><br>#qGetVerify.dept_name#</div>
					<cfelseif isDefined("hdn_empid1")>
						<div style="text-align: center; display:inline-block; width:80%;">Approver</div><div style="text-align: center; float:right; display:inline-block; width:19%;">Verify</div><br><br><br><br><br><br><br><br>
						<div style="text-align: center; display:inline-block; width:80%;"><u>#qGetApprover.Full_Name#</u><br>#qGetApprover.dept_name#</div>
						<div style="text-align: center; float:right; display:inline-block; width:19%;"><u>#qGetVerify.Full_Name#</u><br>#qGetVerify.dept_name#</div>
					<cfelse>
					<div style="text-align: center; float:right; display:inline-block; width:19%;">Verify</div><br><br><br><br><br><br><br><br>
					<div style="text-align: center; float:right; display:inline-block; width:19%;"><u>#qGetVerify.Full_Name#</u><br>#qGetVerify.dept_name#</div>
					</cfif>
				--->

				<!---muadz biar ada space antara ttd dan table--->
				<div style="padding-top: 10%;">&nbsp;</div>
				<!---muadz table ttd--->
				<table width="100%">
					<tr>
						<td style="text-align: center; width:16%;">Initiator</td>
						<cfif inp_empid4 neq '' and inp_empid3 neq '' and inp_empid2 neq '' and inp_empid1 neq ''>
							<cfset lastRow = 4>
							<cfloop index="index" from="1" to="4">
								<td style="text-align: center; width:16%;">Approver</td>
							</cfloop>
						<cfelseif inp_empid3 neq '' and inp_empid2 neq '' and inp_empid1 neq ''>
							<cfset lastRow = 3>
							<cfloop index="index" from="1" to="3">
								<td style="text-align: center; width:19%;">Approver</td>
							</cfloop>
						<cfelseif inp_empid2 neq '' and inp_empid1 neq ''>
							<cfset lastRow = 2>
							<cfloop index="index" from="1" to="2">
								<td style="text-align: center; width:26%;">Approver</td>
							</cfloop>
						<cfelseif inp_empid1 neq ''>
							<cfset lastRow = 1>
							<td style="text-align: center; width:39%;">Approver</td>
						<cfelse>
						</cfif>
						<td style="text-align: center; width:16%;">Verify</td>
					</tr>
					<tr><td>&nbsp;</td></tr><tr><td>&nbsp;</td></tr><tr><td>&nbsp;</td></tr><tr><td>&nbsp;</td></tr>
					<tr>
						<td style="text-align: center;"><u>#qGetInitiator.Full_Name#</u><br>#qGetInitiator.dept_name#</td>
						<cfif isDefined("lastRow")>
							<cfloop query="qGetApprover" startrow="1" endrow=#lastRow#>
								<td style="text-align: center;"><u>#qGetApprover.Full_Name#</u><br>#qGetApprover.dept_name#</td>
							</cfloop>
						</cfif>
						<td style="text-align: center;"><u>#qGetVerify.Full_Name#</u><br>#qGetVerify.dept_name#</td>
					</tr>
				</table>

				<div style="page-break-after:always;"> </div>  				
			</cfloop>
		</cfoutput>
	</cffunction>

	<cffunction name="filterEventForEventReport">
		<cfparam name = "cal_enddate" default="">
		<cfparam name = "cal_startdate" default="">
		<cfparam name = "startdate" default="">
		<cfparam name = "enddate" default="">
		<cfparam name = "nametype" default="">
		<cfparam name = "trnevent_sts" default="">
		
		<cfparam name="search" default="">
		<cfparam name="nrow" default="0">
		<cfparam name="REQUEST.KeyFields" default="">
		<cfif val(nrow) eq "0">
			<cfset nrow="50">
		</cfif>
		<cfset LOCAL.searchText=trim(search)>
		
		<cfquery name="qGetAllEvent" datasource="#REQUEST.SDSN#">
			SELECT distinct trnevent_code, ttrdtrainevent.trnevent_topic,ttrdtrainevent.trncourse_code, trncourse_name_en trncourse_name
			from ttrdtrainevent inner join TTRDTRAINCOURSE ON  ttrdtrainevent.trncourse_code = TTRDTRAINCOURSE.trncourse_code
			where 
			(trnevent_startdate >= '#DateFormat(startdate,'yyyy-mm-dd')#' AND trnevent_enddate <= '#DateFormat(enddate,'yyyy-mm-dd')#') 
			
		    <cfif len(searchText)>
			    AND (trncourse_code LIKE <cfqueryparam value="%#searchText#%" cfsqltype="CF_SQL_VARCHAR">  OR trncourse_name_en LIKE <cfqueryparam value="%#searchText#%" cfsqltype="CF_SQL_VARCHAR">)
			</cfif>
			<cfif trnevent_sts neq "">
			    AND trnevent_sts = #trnevent_sts#    
			</cfif>
			<cfif nametype neq "">
			AND (UPPER(trnevent_type) = '#UCASE(nametype)#')
			</cfif>
			
		</cfquery>
		
		<!---<cf_sfwritelog folder="TrnReqData" dump="qGetAllEvent" prefix="qGetAllEvent"> ---->
		<cfset lstallcourse = "">
		
		<cfif qGetAllEvent.recordcount neq 0>
			<cfset lstallcourse = valuelist(qGetAllEvent.trncourse_name)>
		</cfif>
		<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("FDTrainingCourse",true,"+")>
		<cfset LOCAL.vResult="">
		<cfloop query="qGetAllEvent">
			<cfset vResult=vResult & "arrEntryList[#currentrow-1#]=""#JSStringFormat(trnevent_code & "=" & "#trnevent_topic#"&" - "&"#trncourse_name#")#"";">
		</cfloop>
		<cfset tempLabel = SFLANG & " (#qGetAllEvent.recordcount#)">
		
		<cfoutput>
		<script>
				try {
						
						if($sf("lbl_inp_allcourse")) {
							$sf("lbl_inp_allcourse").innerHTML = "#tempLabel# <span class=\"required\">*</span>";
						}
						if($sf("lbl_inp_course")) {
							$sf("lbl_inp_course").innerHTML = "";
						}
						if($sf("inp_coursesel")) { 
							$sf("inp_coursesel").value = "#lstallcourse#";
						}
						
				}
				catch(err) {

				}
			arrEntryList=new Array();
			#vResult#
		</script>
		</cfoutput>
	</cffunction>

	<cffunction name="rptTrainingEvent">
		<cfparam name="inp_startdate" default="">
		<cfparam name="inp_enddate" default="">
		<cfparam name="inp_nametype" default="">
		<cfparam name="inp_trnevent_sts" default="">
		<cfparam name="hdnSelectedinp_course" default="">
		<cfparam name="inp_allcourse" default="">
		
		<cfset local.FORMMLANG="Notitik|StartDate|EndDate|Days|Hours|Participants|Positions|Departments|FDTotParticipantPerDept|FDTrainingDate|JSTo|FDProviderType|FDTrainingEventStatus|FDTotParticipant|FDCapacity|FDSubject|FDTopic|FDProvider|FDVenue|FDTrainingCost">
		<cfset REQUEST.SFMLANG=Application.SFParser.TransMLang(listAppend("Training Course",(isdefined("FORMMLANG")?FORMMLANG:""),"|"))>
		
		<cfoutput>
			
			<div style="text-align: justify;"></div>
			<div style="text-align: left;">
				<strong>
					#REQUEST.SFMLANG["FDTrainingDate"]# : 
				</strong>
				#dateFormat(inp_startdate,REQUEST.config.DATE_OUTPUT_FORMAT)# 
				<strong>
					#REQUEST.SFMLANG["JSTo"]# 
				</strong>
				#dateFormat(inp_enddate,REQUEST.config.DATE_OUTPUT_FORMAT)#
			</div>
			<div style="text-align: left;">
				<strong>#REQUEST.SFMLANG["FDProviderType"]# : </strong> 
				<CFIF inp_nametype eq 'INTERNAL'> 
						Internal 
				<CFELSE>
						External
				</CFIF>
			</div>
			<div style="text-align: left;">
				<strong>#REQUEST.SFMLANG["FDTrainingEventStatus"]# : </strong> 
					<cfif inp_trnevent_sts eq ''>
						All
					<cfelseif inp_trnevent_sts eq '1'>
						Draft 
					<cfelseif inp_trnevent_sts eq '2'>
						Open for Registration 
					<cfelseif inp_trnevent_sts eq '3'>
						Closed Registration 
					<cfelseif inp_trnevent_sts eq '4'> 
						Concluded 
					<cfelse> 
						Cancelled 
					</cfif>
			</div>
			
			<cfquery name="qTrainingEvent" datasource="#request.sdsn#">
			
				select
					a.trnevent_code,
					a.trnevent_topic,
					d.trncourse_name_#REQUEST.SCookie.LANG# course_name,
					a.trnevent_startdate,
					a.trnevent_enddate,
					(
					select
						count(trnevent_code) as day
					from
						TTRRTRAINEVENTACTIVITY
					where
						trnevent_code = a.trnevent_code
						and company_code = a.company_code ) as day,
					(
					select
						count(b.emp_id)
					from
						TTRRTRAINEVENTMEMBER b
					join TEOMEMPPERSONAL c on
						b.emp_id = c.emp_id
					join TEODEMPCOMPANY d on
						c.emp_id = d.emp_id
						and d.company_id = #REQUEST.SCookie.coid#
					where
						trnevent_code = a.trnevent_code
						and company_code = a.company_code ) as total,
					(
					select
						count(e.position_id)
					from
						TTRRTRAINEVENTMEMBER b
					join TEOMEMPPERSONAL c on
						b.emp_id = c.emp_id
					join TEODEMPCOMPANY d on
						c.emp_id = d.emp_id
						and d.company_id = #REQUEST.SCookie.coid#
					join TEOMPOSITION e on
						d.position_id = e.position_id
					left join TEOMPOSITION f on
						f.position_id = e.dept_id
						and f.company_id = #REQUEST.SCookie.coid#
					where
						trnevent_code = a.trnevent_code
						and company_code = a.company_code
						and e.dept_id = i.dept_id
						and e.position_id =
						(case
							when i.dept_id = 0 then i.position_id
							else e.position_id
						end) ) as totalPerDept,
					(
					select
						count(d.position_id)
					from
						TTRRTRAINEVENTMEMBER b
					join TEOMEMPPERSONAL c on
						b.emp_id = c.emp_id
					join TEODEMPCOMPANY d on
						c.emp_id = d.emp_id
						and d.company_id = #REQUEST.SCookie.coid#
					where
						trnevent_code = a.trnevent_code
						and company_code = a.company_code
						and d.position_id = 0 ) as totalPerDeptZero,
					a.trnevent_capacity,
					<cfif request.dbdriver eq "MSSQL">
						case
							when cast(coalesce(sum(b.trnevent_totalhour),
							0) as integer)% 60 = 0 then cast(coalesce(sum(b.trnevent_totalhour)/ 60,0) as varchar(max))
						else 
							cast(cast(coalesce(sum(b.trnevent_totalhour),0)/ 60 as integer) as varchar(max)) + cast(substring(cast(ROUND(cast(coalesce(sum(b.trnevent_totalhour), 0) as float)/ 60, 2) as varchar), CHARINDEX('.', ROUND(cast(coalesce(sum(b.trnevent_totalhour), 0) as float)/ 60, 2)), 3) as varchar(max)) END
					<cfelse>
						case
							when cast(coalesce(sum(b.trnevent_totalhour),0) as integer)% 60 = 0 then cast(coalesce(sum(b.trnevent_totalhour)/ 60,0) as char(20))
						else cast(cast(coalesce(sum(b.trnevent_totalhour),0)/ 60 as integer) as char(20)) || substring(cast(ROUND(coalesce(sum(b.trnevent_totalhour), 0)/ 60, 2) as char(50)), SUBSTRING_INDEX(ROUND(coalesce(sum(b.trnevent_totalhour), 0)/ 60, 2), '.', 1), 3) end
					</cfif>
					hour, e.provider_name,
					f.venue_name,
					j.name room_name,
					d.currency_cost,
					d.trncourse_cost,
					case
						when len(k.Full_Name) >= 0 then 
						<cfif request.dbdriver eq "MSSQL" >
							k.Full_Name + ' (' + h.emp_no + ')' 
						<cfelseif request.dbdriver eq "MYSQL">
							CONCAT(k.Full_Name,' (',h.emp_no,')') 
						</cfif>
					else 'No Participant Joined / Assigned'
					end Full_name,
					i.pos_name_#REQUEST.SCookie.LANG# posit,
					case
					when i.dept_id <> 0
					and i.dept_id is not null
					and m.pos_name_#REQUEST.SCookie.LANG# is not null then m.pos_name_#REQUEST.SCookie.LANG#
					else i.pos_name_#REQUEST.SCookie.LANG#
					end as dept,
					<cfif request.dbdriver eq "MSSQL">
						a.trnevent_code + (case when i.dept_id <> 0
							and i.dept_id is not null
							and m.pos_name_#REQUEST.SCookie.LANG# is not null then m.pos_name_#REQUEST.SCookie.LANG#
							else i.pos_name_#REQUEST.SCookie.LANG#
							end) as deptUnique 
					<CFELSEIF request.dbdriver eq "MYSQL">
						CONCAT(a.trnevent_code , (case when i.dept_id <> 0 and i.dept_id is not null and m.pos_name_#REQUEST.SCookie.LANG# is not null then m.pos_name_#REQUEST.SCookie.LANG#
						else i.pos_name_#REQUEST.SCookie.LANG#
						end)) as deptUnique
					</CFIF>
				from
				TTRDTRAINEVENT a
				left join TTRRTRAINEVENTACTIVITY b on
				a.trnevent_code = b.trnevent_code
				and a.company_code = b.company_code
				left join TTRRTRAINEVENTVENUE c on
				a.trnevent_code = c.trnevent_code
				and a.company_code = c.company_code
				left join TTRDTRAINCOURSE d on
				a.trncourse_code = d.trncourse_code
				and a.company_code = d.company_code
				left join TTRMPROVIDER e on
				c.provider_code = e.provider_code
				and c.company_code = e.company_code
				left join TTRMVENUE f on
				c.venue_code = f.venue_code
				and c.company_code = f.company_code
				left join TTRRTRAINEVENTMEMBER g on
				a.trnevent_code = g.trnevent_code
				and a.company_code = g.company_code
				left join TEODEMPCOMPANY h on
				g.emp_id = h.emp_id
				and h.company_id = #REQUEST.SCookie.COID#
				left join TEOMPOSITION i on
				h.position_id = i.position_id
				left join TTRMROOMTYPE j on
				c.room_code = j.code
				and j.venue_code = c.venue_code
				left join TEOMEMPPERSONAL k on
				h.emp_id = k.emp_id
				left join TEOMPOSITION l on
				h.position_id = l.position_id
				and h.company_id = l.company_id
				left join TEOMPOSITION m on
				m.position_id = i.dept_id
				and m.company_id = i.company_id
				where
				a.company_code = '#REQUEST.SCookie.COCODE#'
				and a.trnevent_startdate >= #createODBCDate(inp_startdate)#
				and a.trnevent_enddate <= #createODBCDate(inp_enddate)#
					<CFIF inp_allcourse NEQ '1' >
						and a.trncourse_code in (#listqualify(preservesinglequotes(hdnSelectedinp_course),"'")#)
					</CFIF>
					
					<CFIF inp_trnevent_sts neq ''>
						AND a.trnevent_sts = '#inp_trnevent_sts#' 
					</CFIF> 
				AND a.trnevent_type = '#inp_nametype#'
				group by
				a. trnevent_code,
				a.company_code,
				a.trnevent_topic,
				d.trncourse_name_#REQUEST.SCookie.LANG#,
				a.trnevent_startdate,
				a.trnevent_enddate,
				e.provider_name,
				f.venue_name,
				d.currency_cost,
				d.trncourse_cost,
				k.Full_name,
				i.pos_name_#REQUEST.SCookie.LANG#,
				i.position_id,
				h.position_id,
				m.pos_name_#REQUEST.SCookie.LANG# ,
				l.position_id,
				l.parent_id,
				i.parent_id,
				l.pos_name_#REQUEST.SCookie.LANG# ,
				i.dept_id,
				m.position_id,
				m.pos_name_#REQUEST.SCookie.LANG# ,
				a.trnevent_capacity,
				g.emp_id,
				h.emp_no,
				j.name
				order by
				trnevent_startdate asc,
				a.trnevent_code,
				dept asc,
				full_name asc
			</cfquery>
			
			
			<table width="100%" cellspacing="1" cellpadding="1" border="1">
				<tbody>
					<tr>
						<td align="center"><strong>#REQUEST.SFMLANG["Notitik"]#</strong></td>
						<td width="80" align="center"><strong>#REQUEST.SFMLANG["StartDate"]#</strong></td>
						<td width="80" align="center"><strong>#REQUEST.SFMLANG["EndDate"]#</strong></td>
						<td align="center"><strong>#REQUEST.SFMLANG["Days"]#</strong></td>
						<td align="center"><strong>#REQUEST.SFMLANG["Hours"]#</strong></td>
						<td nowrap="" align="center"><strong>#REQUEST.SFMLANG["Participants"]#</strong></td>
						<td nowrap="" align="center"><strong>#REQUEST.SFMLANG["Positions"]#</strong></td>
						<td nowrap="" align="center"><strong>#REQUEST.SFMLANG["Departments"]#</strong></td>
						<td align="center"><strong>#REQUEST.SFMLANG["FDTotParticipantPerDept"]#</strong></td>
						<td align="center"><strong>#REQUEST.SFMLANG["FDTotParticipant"]#</strong></td>
						<td align="center"><strong>#REQUEST.SFMLANG["FDCapacity"]#</strong></td>
						<td nowrap="" align="center"><strong>#REQUEST.SFMLANG["FDSubject"]#</strong></td>
						<td nowrap="" align="center"><strong>#REQUEST.SFMLANG["FDTopic"]#</strong></td>
						<td align="center"><strong>#REQUEST.SFMLANG["FDProvider"]#</strong></td>
						<td align="center"><strong>#REQUEST.SFMLANG["FDVenue"]#</strong></td>
						<td style="text-align: center;" colspan="2"><strong>#REQUEST.SFMLANG["FDTrainingCost"]#</strong></td>
					</tr>
					<cfset counterzz = 0>
					<CFSET FLAG = 0>
					<CFSET oldTrnEvent = "">
					<cfset oldTrnDept = ''>
					<CFSET countNo = 0>
					<cfloop query="qTrainingEvent">
						<cfset rowspan2 = qTrainingEvent.recordcount>
						<cfset rowspan3 = qTrainingEvent.total>
						<cfquery name="qGetSumCost" datasource="#request.sdsn#">
							SELECT currency_code,totalevent_cost FROM TTRDEVENTSUMCOST WHERE trnevent_code = '#qTrainingEvent.trnevent_code#'
						</cfquery>
						<cfif qTrainingEvent.total lt qGetSumCost.recordcount>
							<cfset counterzz++>
							<cfif counterzz lt qTrainingEvent.total>
								<cfset rowspan4 = 1>
							<cfelseif qTrainingEvent.total eq 1>
								<cfset rowspan4 = 1>
								<cfset counterzz = 0>
							<cfelse>
								<cfset rowspan4 = val(qGetSumCost.recordcount - counterzz) >
								<cfset counterzz = 0>
							</cfif>
						<cfelse>
							<cfset rowspan4 = 1>
						</cfif>
						
						<CFIF qGetSumCost.recordcount neq 0>
							<CFSET ROWSPAN = 1>
							<CFSET FLAG = 1>
						<CFELSE>
							<CFSET ROWSPAN = qTrainingEvent.total>
							<CFSET FLAG ++ >
						</CFIF>
						
						<TR>
							<CFIF oldTrnEvent NEQ qTrainingEvent.trnevent_code>
								<CFSET countNo++>
								<td align="center" rowspan="#(rowspan3 eq 0 ? 1 : rowspan3)#">
									#countNo#
								</td>
							</CFIF>
							
							<cfif oldTrnEvent neq qTrainingEvent.trnevent_code> 
								<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="center">
									#DATEFORMAT(qTrainingEvent.trnevent_startdate,REQUEST.CONFIG.DATE_INPUT_FORMAT)# 
								</td>
							</cfif>
							
							<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
								<td rowspan="#(rowspan3 eq 0 ? 1 : rowspan3)#" align="center">
									#DATEFORMAT(qTrainingEvent.trnevent_enddate,REQUEST.CONFIG.DATE_INPUT_FORMAT)#
								</td>
							</CFIF>
							
							<cfif oldTrnEvent neq qTrainingEvent.trnevent_code>
								<td rowspan="#(rowspan3 eq 0 ? 1 : rowspan3)#" align="right">
									#qTrainingEvent.day#
								</td>
							</cfif>
							
							<cfif oldTrnEvent neq qTrainingEvent.trnevent_code>
								<td rowspan="#(rowspan3 eq 0 ? 1 : rowspan3)#" align="right">
									#qTrainingEvent.HOUR#
								</td>
							</cfif>
							
							<td rowspan="#(rowspan4 eq 0 ? 1 : rowspan4) #" nowrap="">#HTMLEDITFORMAT(qTrainingEvent.full_name)#</td>
							<td rowspan="#(rowspan4 eq 0 ? 1 : rowspan4)#" nowrap="">#HTMLEDITFORMAT((len(qTrainingEvent.posit) eq 0 ? '-' : qTrainingEvent.posit ))#</td>
							<td rowspan="#(rowspan4 eq 0 ? 1 : rowspan4)#" nowrap="">#HTMLEDITFORMAT((len(qTrainingEvent.dept) eq 0 ? '-' : qTrainingEvent.dept))#</td>
							
							<cfif len(qTrainingEvent.deptUnique) eq 0 or oldTrnDept neq qTrainingEvent.deptUnique>
								<td rowspan="#((qTrainingEvent.totalPerDept NEQ 0 ? qTrainingEvent.totalPerDept : qTrainingEvent.totalPerDeptZero)) eq 0 ? 1 : (qTrainingEvent.totalPerDept NEQ 0 ? qTrainingEvent.totalPerDept : qTrainingEvent.totalPerDeptZero)#" align="right">
									#qTrainingEvent.totalPerDept#
								</td>
							</cfif>
							
							<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
								<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
									#qTrainingEvent.total#
								</td>
							</CFIF>
							
							<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
								<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
									#qTrainingEvent.trnevent_capacity#
								</td>
							</CFIF>
							
							<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
								<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
									#qTrainingEvent.course_name#
								</td>
							</CFIF>
							
							<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
								<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
									#qTrainingEvent.trnevent_topic#
								</td>
							</CFIF>
							
							<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
								<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
									#qTrainingEvent.provider_name#
								</td>
							</CFIF>
							
							<CFIF oldTrnEvent neq qTrainingEvent.trnevent_code>
								<td rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#" align="right">
									#qTrainingEvent.venue_name#
								</td>
							</CFIF>
							
							<cfif oldTrnEvent neq qTrainingEvent.trnevent_code>
								<td colspan="2" rowspan="#(qTrainingEvent.total eq 0 ? 1 : qTrainingEvent.total)#">
									<table>
										<tbody>
											<cfloop query="qGetSumCost">
												<tr>
													<td>#qGetSumCost.currency_code#</td>
													<td>#qGetSumCost.totalevent_cost#</td>
												</tr>
											</cfloop>
										</tbody>
									</table>
								</td>
							</cfif>
							<cfset oldTrnEvent =qTrainingEvent.trnevent_code>
							<cfset oldTrnDept = qTrainingEvent.deptUnique>
							<cfif qTrainingEvent.currentrow+1 lte qTrainingEvent.recordcount>
								<cfif qTrainingEvent.total[qTrainingEvent.currentrow] neq qTrainingEvent.total[qTrainingEvent.currentrow+1]>
									<cfquery name="qGetSumCost" datasource="#request.sdsn#">
										SELECT currency_code,totalevent_cost 
										FROM TTRDEVENTSUMCOST 
										WHERE trnevent_code = '#qTrainingEvent.trnevent_code[qTrainingEvent.currentrow+1]#'
									</cfquery>
									<cfif qGetSumCost.recordcount gt qTrainingEvent.total[qTrainingEvent.currentrow+1]>
										<cfset rowspan3 = qTrainingEvent.total[qTrainingEvent.currentrow+1]>
									<cfelse>
										<cfset rowspan3 = qTrainingEvent.total[qTrainingEvent.currentrow+1]>
									</cfif>
								</cfif>
							</cfif>
						</TR>  
					</cfloop>
				</tbody>
			</table>
			
		</cfoutput>
	</cffunction>
	
</cfcomponent>





















































































