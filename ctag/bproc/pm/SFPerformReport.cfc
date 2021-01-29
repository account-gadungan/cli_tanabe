<cfcomponent displayname="SFPerformReport" hint="SunFish Performance Report Business Process Object" extends="sfcomp.bproc.pm.SFPerformReport">

	<!--- Start custom Marc --->
	<cffunction name="MBOReport">
    	<cfsetting showdebugoutput="yes" enablecfoutputonly="Yes">

    	<cfparam name="inp_perform_period" default="">
    	<cfparam name="hdnSelectedinp_period_code" default="">

    	<cfparam name="inp_emp" default="">
    	<cfparam name="unselinp_emp_id" default="">
		<cfparam name="hdnSelectedinp_emp_id" default="">


		<cfset local.FORMMLANG="PeriodCode|PeriodName|ReferenceDate|EmployeeNo|EmployeeName|No|Objective|WeightPercent|Criteria|Target|HowToAchieve|SchedulePlan">
        <cfset FORMMLANG &= "|ActionResult|ScoreAssessee|Score1stAssesor|Score2stAssesor|TargetScoreCriteria|NoRecords">
		<cfset REQUEST.SFMLANG=Application.SFParser.TransMLang(listAppend("Test",(isdefined("FORMMLANG")?FORMMLANG:""),"|"))>

		<!--- Marc : inp_perform_periode adalah checkbox yang memberikan nilai Y apabila di centang --->
		<cfif inp_perform_period eq ''>
			<cfset local.pperiod = ListQualify(hdnSelectedinp_period_code,"'")>
		</cfif>

		<!--- Marc : inp_emp adalah checkbox yang memberikan nilai Y apabila di centang --->
    	<cfif inp_emp eq ''>
    	    <cfset local.employee_id = ListQualify(hdnSelectedinp_emp_id,"'")>
		</cfif>

		<cfif inp_stage neq 'planning'>
			<cfquery name="local.qResult" datasource="#request.sdsn#">
				select
				p.period_code ,
				p.period_name_en,
				p.reference_date ,
				(select emp_no from view_employee where emp_id = f.reviewee_empid) as NIK,
				(select full_name from teomemppersonal where emp_id = f.reviewee_empid) as Nama,
				d.lib_name_en as libname,
				d.weight,
				d.criteria,
				d.target,
				d.initiative,
				d.scheduleplan,
				ed.actionresult,
				(
					select format(score,1) from tpmdperformance_evalh
					where form_no = f.form_no
					and reviewee_empid = f.reviewee_empid
					and review_step = (
						select max(review_step)-2 from tpmdperformance_evalh
						where form_no = f.form_no
						and reviewee_empid = f.reviewee_empid
					)
				) as 'ScoreAssessee',
				(
					select format(score,1) from tpmdperformance_evalh
					where form_no = f.form_no
					and reviewee_empid = f.reviewee_empid
					and review_step =
					(
						select max(review_step)-1 from tpmdperformance_evalh
						where form_no = f.form_no
						and reviewee_empid = f.reviewee_empid
					)
				) as 'Score1stAssesor',
				(
					select format(score,1) from tpmdperformance_evalh
					where form_no = f.form_no
					and reviewee_empid = f.reviewee_empid
					and review_step =
					(
						select max(review_step) from tpmdperformance_evalh
						where form_no = f.form_no
						and reviewee_empid = f.reviewee_empid
					)
				) as 'Score2ndAssesor'
				,d.pointscriteria as 'targetscorecriteria'
				,d.lib_code as libcode
				-- PLD.lib_order
				,d.form_no
				,f.period_code
				-- *
				from tpmdperformance_final f
				inner join tpmdperformance_planh h on f.form_no = h.form_no
				inner join tpmdperformance_pland d on h.request_no = d.request_no
					and h.isfinal = 1
					and h.reviewer_empid = d.reviewer_empid
				inner join tpmmperiod p on p.period_code = f.period_code
				inner join tpmdperformance_evalh eh on f.form_no = eh.form_no and eh.isfinal = 1
				inner join tpmdperformance_evald ed on eh.form_no = ed.form_no
					and eh.isfinal = 1
					and eh.reviewer_empid = ed.reviewer_empid
					and ed.lib_type = 'perskpi'
					and d.lib_code = ed.lib_code
				where 1=1
				<cfif inp_perform_period eq ''>
					AND f.period_code in (#PreserveSingleQuotes(local.pperiod)#)
				</cfif>
				<cfif inp_emp eq ''>
					AND f.reviewee_empid in (#PreserveSingleQuotes(employee_id)#)
				</cfif>
			</cfquery>
			<cfoutput>
				<strong>Stage:</strong> Evaluation<br><br>
				<table width="100%" cellspacing="1" cellpadding="1" border="1">
					<tbody>
						<cfif qResult.recordcount neq 0>
							<tr>
								<td><strong>#REQUEST.SFMLANG['PeriodCode']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['PeriodName']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['ReferenceDate']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['EmployeeNo']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['EmployeeName']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['No']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['Objective']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['WeightPercent']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['Criteria']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['Target']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['HowToAchieve']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['SchedulePlan']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['ActionResult']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['ScoreAssessee']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['Score1stAssesor']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['Score2stAssesor']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['TargetScoreCriteria']#</strong></td>
							</tr>

							<cfset calcSpan = 0>
							<cfset cntspan = 0>

							<cfloop query="qResult">

								<!--- Setting initial data untuk baris pertama --->
								<cfif currentrow eq 1>
									<cfset currNIK = qResult.NIK>
									<cfset objNo = 1>
									<!--- masuk1 : #currentrow#; --->
								<cfelse>
									<cfif qResult.NIK EQ currNIK>
										<!--- masuk2 : #currentrow#; --->
										<cfif len(libname) gt 0>
											<!--- masuk3 : #currentrow#; --->
											<cfset objNo++>
										</cfif>
									<cfelse>
										<!--- masuk4 : #currentrow#; --->
										<cfset objNo = 1>
										<cfset currNIK = qResult.NIK>
									</cfif>
								</cfif>

								<!--- Untuk menghitung jumlah span per objective,
									kalau obj nya kosong atau '' maka tambah rowspan --->
								<cfif len(libname) gt 0>
									<cfset calcSpan = 1>
									<cfset cntspan = 1> <!--- rowspan dimulai dari angka satu karena termasuk dengan baris sebelum dimulai pengecekan --->
								<cfelse>
									<cfset calcSpan++>
								</cfif>

								<!--- Kalau calcSpan sudah di reset menjadi 1 baru dilakukan perhitungan jumlah span yang dibutuhkan --->
								<cfif calcSpan eq 1>
									<!--- Mengecek rowspan yang dibutuhkan hingga objective berikutnya, dimulai dari baris selanjutnya --->
									<cfloop query="qResult" startrow="#currentrow+1#" endrow="#recordcount#">
										<cfif len(libname) gt 0>
											<cfbreak>
										<cfelse>
											<cfset cntspan++>
										</cfif>
									</cfloop>
								</cfif>

								<tr>
									<!--- row span untuk kolom NIK sampai Target --->
									<!--- Apabila ada objective yang mempunyai initiative --->
									<cfif calcSpan eq 1 and cntspan gt 1>
										<td rowspan="#cntspan#" align="center">#period_code#</td>
										<td rowspan="#cntspan#" align="center">#period_name_en#</td>
										<td rowspan="#cntspan#" align="center">#dateFormat(reference_date,application.config.date_output_format)#</td>
										<td rowspan="#cntspan#" align="center">#NIK#</td>
										<td rowspan="#cntspan#">#htmleditformat(nama)#</td>
										<td rowspan="#cntspan#" align="center">#objNo#</td>
										<td rowspan="#cntspan#">#libname#</td>
										<td rowspan="#cntspan#" align="center">#weight#%</td>
										<td rowspan="#cntspan#">#criteria#</td>
										<td rowspan="#cntspan#">#target#</td>

									<!--- Apabila ada objective yang tidak mempunyai initiative --->
									<cfelseif calcSpan eq 1 and cntspan eq 1>
										<td align="center">#period_code#</td>
										<td align="center">#period_name_en#</td>
										<td align="center">#dateFormat(reference_date,application.config.date_output_format)#</td>
										<td align="center">#NIK#</td>
										<td>#htmleditformat(nama)#</td>
										<td align="center">#objNo#</td>
										<td>#libname#</td>
										<td align="center">#weight#%</td>
										<td>#criteria#</td>
										<td>#target#</td>
									<cfelse><!--- tidak perlu membuat <td> apabila bukan header objective --->
									</cfif>

									<!--- kolom HowToAchieve, SchedulePlan dan ActionResult yang tidak membutuhkan rowspan --->
									<td>#initiative#</td>
									<td align="center">#scheduleplan#</td>
									<td align="center">#actionresult#</td>

									<!--- row span untuk kolom NIK sampai Target --->
									<!--- Apabila ada objective yang mempunyai initiative --->
									<cfif calcSpan eq 1 and cntspan gt 1>
										<td rowspan="#cntspan#" align="center">#ScoreAssessee#</td>
										<td rowspan="#cntspan#" align="center">#Score1stAssesor#</td>
										<td rowspan="#cntspan#" align="center">#Score2ndAssesor#</td>
										<td rowspan="#cntspan#">#TargetScoreCriteria#</td>
									<!--- Apabila ada objective yang tidak mempunyai initiative --->
									<cfelseif calcSpan eq 1 and cntspan eq 1>
										<td align="center">#ScoreAssessee#</td>
										<td align="center">#Score1stAssesor#</td>
										<td align="center">#Score2ndAssesor#</td>
										<td>#TargetScoreCriteria#</td>
									<cfelse><!--- tidak perlu membuat <td> apabila bukan header objective --->
									</cfif>
								</tr>
							</cfloop>
						<cfelse>
						<tr>
							<td align="center">----- #REQUEST.SFMLANG['NoRecords']# ----</td>
						<tr>
						</cfif>
					</tbody>
				</table>
			</cfoutput>
		<!--- <cfdump var='#local.qResult#' label='local.qResult' expand='yes'> --->
		<cfelse>
			<!--- Muadz : query buat planning --->
			<cfquery name="local.qGetFinal" datasource="#request.sdsn#">
				<!---select distinct 
					ph.request_no, 
					ph.form_no,
					ph.isfinal,
					ph.isfinal_requestno 
				from tpmdperformance_planh ph 
				where 
				ph.isfinal = 1 
				-- and ph.isfinal_requestno = 1
				-- 1=1
				<cfif inp_perform_period eq ''>
					and ph.period_code in (#PreserveSingleQuotes(local.pperiod)#)
				</cfif>
				<cfif inp_emp eq ''>
					and ph.reviewee_empid in (#PreserveSingleQuotes(employee_id)#)
				</cfif>--->
				select distinct
					TPMDPERFORMANCE_PLANH.reviewee_empid
					,TPMDPERFORMANCE_PLANH.form_no as form_no
					,TPMDPERFORMANCE_PLANH.period_code as period_code
					,TEODEMPCOMPANY.emp_no as emp_no
					,TEOMEMPPERSONAL.full_name as full_name
					,TEODEMPCOMPANY.start_date as joindate
					,TEOMPOSITION.pos_name_#request.scookie.lang# as pos
					,TEOMPOSITION.parent_path
					,TEOMPOSITION.DEPT_ID
					,DEPT.pos_name_#request.scookie.lang# as deptname
					,TEOMEMPLOYMENTSTATUS.employmentstatus_name_#request.scookie.lang# as empstatus
					,GRD.grade_name as empgrade
				from TPMDPERFORMANCE_PLANH 
				
				LEFT join TEOMEMPPERSONAL on TEOMEMPPERSONAL.emp_id=TPMDPERFORMANCE_PLANH.reviewee_empid
				LEFT join TEODEMPCOMPANY on TEODEMPCOMPANY.emp_id=TPMDPERFORMANCE_PLANH.reviewee_empid
				LEFT join TEOMPOSITION on TPMDPERFORMANCE_PLANH.reviewee_posid=TEOMPOSITION.position_id
				LEFT join TEOMPOSITION DEPT on TEOMPOSITION.DEPT_ID = DEPT.position_id
				LEFT join TEOMEMPLOYMENTSTATUS on TPMDPERFORMANCE_PLANH.reviewee_employcode=TEOMEMPLOYMENTSTATUS.employmentstatus_code
				LEFT JOIN TEOMJOBGRADE GRD 
				ON (GRD.grade_code = TPMDPERFORMANCE_PLANH.reviewee_grade AND  GRD.company_id  = TEODEMPCOMPANY.company_id )
				WHERE TEODEMPCOMPANY.COMPANY_ID = <cfqueryparam value="#request.scookie.COID#" cfsqltype="cf_sql_varchar">
					<cfif inp_perform_period eq ''>
						and TPMDPERFORMANCE_PLANH.period_code in (#PreserveSingleQuotes(local.pperiod)#)
					</cfif>
					<cfif inp_emp eq ''>
						and TPMDPERFORMANCE_PLANH.reviewee_empid in (#PreserveSingleQuotes(employee_id)#)
					</cfif>
					
					<!---<cfif inp_viewpoint eq 1>
						<cfif inp_incld_draft eq "N">
						AND TPMDPERFORMANCE_PLANH.isfinal = 1 
						<cfelse>
						and (TPMDPERFORMANCE_PLANH.isfinal = 1 or treq.status = 1)
						</cfif>
					<cfelse>
						<cfif inp_incld_draft neq "Y">
							
							AND TPMDPERFORMANCE_PLANH.head_status = 1
						</cfif>
					</cfif>--->
				ORDER BY full_name
			</cfquery>
			<cfoutput>
				<strong>Stage:</strong> Planning<br><br>
				<table width="100%" cellspacing="1" cellpadding="1" border="1">
					<tbody>
						<cfif qGetFinal.recordcount neq 0>
							<tr>
								<td><strong>#REQUEST.SFMLANG['PeriodCode']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['PeriodName']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['ReferenceDate']#</strong></td>
								<td><strong>FormNo</strong></td>
								<td><strong>#REQUEST.SFMLANG['EmployeeNo']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['EmployeeName']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['No']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['Objective']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['WeightPercent']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['Criteria']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['Target']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['HowToAchieve']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['SchedulePlan']#</strong></td>
								<td><strong>#REQUEST.SFMLANG['TargetScoreCriteria']#</strong></td>
							</tr>

							<cfset calcSpan = 0>
							<cfset cntspan = 0>

							<!---Muadz: Loop formno dan requestno --->
							<cfloop query="qGetFinal">
								<!---Muadz: Query bakal cari reviewer terakhir query asli by dev--->
								<cfquery name="local.qGetLastRvr" datasource="#request.sdsn#">
									SELECT modified_date,created_by,reviewer_empid,review_step,form_no,company_code
									FROM TPMDPERFORMANCE_PLANH 
									where form_no = '#form_no#'
									ORDER BY modified_date DESC LIMIT 1
								</cfquery>

								<!---Muadz: Query Planning Utama --->
								<cfquery name="local.qResultPlan" datasource="#request.sdsn#">
									select distinct 	
										pd.form_no,
										ph.period_code,
										p.period_name_en,
										ph.reference_date,
										(select emp_no from view_employee where emp_id = ph.reviewee_empid) as NIK,
										(select full_name from teomemppersonal where emp_id = ph.reviewee_empid) as Nama,
										pd.lib_name_en as libname,
										pd.lib_order,
										pd.weight,
										pd.criteria,
										pd.target,
										pd.initiative,
										pd.scheduleplan,
										pd.pointscriteria as 'targetscorecriteria'
									from tpmdperformance_pland pd
									inner join tpmdperformance_planh ph on
										ph.form_no = pd.form_no 
									inner join tpmmperiod p on p.period_code = ph.period_code
									where 1=1
									and pd.form_no = '#form_no#'
									<!--- and pd.request_no = '#request_no#' --->
									and pd.reviewer_empid = '#qGetLastRvr.reviewer_empid#'
								</cfquery>

								<cfloop query="qResultPlan">
								
									<!--- Setting initial data untuk baris pertama --->
									<cfif currentrow eq 1>
										<cfset currNIK = qResultPlan.NIK>
										<cfset objNo = 1>
										<!--- masuk1 : #currentrow#; --->
									<cfelse>
										<cfif qResultPlan.NIK EQ currNIK>
											<!--- masuk2 : #currentrow#; --->
											<cfif len(libname) gt 0>
												<!--- masuk3 : #currentrow#; --->
												<cfset objNo++>
											</cfif>
										<cfelse>
											<!--- masuk4 : #currentrow#; --->
											<cfset objNo = 1>
											<cfset currNIK = qResultPlan.NIK>
										</cfif>
									</cfif>

									<!--- Untuk menghitung jumlah span per objective,
										kalau obj nya kosong atau '' maka tambah rowspan --->
									<cfif len(libname) gt 0>
										<cfset calcSpan = 1>
										<cfset cntspan = 1> <!--- rowspan dimulai dari angka satu karena termasuk dengan baris sebelum dimulai pengecekan --->
									<cfelse>
										<cfset calcSpan++>
									</cfif>

									<!--- Kalau calcSpan sudah di reset menjadi 1 baru dilakukan perhitungan jumlah span yang dibutuhkan --->
									<cfif calcSpan eq 1>
										<!--- Mengecek rowspan yang dibutuhkan hingga objective berikutnya, dimulai dari baris selanjutnya --->
										<cfloop query="qResultPlan" startrow="#currentrow+1#" endrow="#recordcount#">
											<cfif len(libname) gt 0>
												<cfbreak>
											<cfelse>
												<cfset cntspan++>
											</cfif>
										</cfloop>
									</cfif>								
									<tr>
										<!--- row span untuk kolom NIK sampai Target --->
										<!--- Apabila ada objective yang mempunyai initiative --->
										<cfif calcSpan eq 1 and cntspan gt 1>
											<td rowspan="#cntspan#" align="center">#period_code#</td>
											<td rowspan="#cntspan#" align="center">#period_name_en#</td>
											<td rowspan="#cntspan#" align="center">#dateFormat(reference_date,application.config.date_output_format)#</td>
											<td rowspan="#cntspan#" align="center">#form_no#</td>
											<td rowspan="#cntspan#" align="center">#NIK#</td>
											<td rowspan="#cntspan#">#htmleditformat(nama)#</td>
											<td rowspan="#cntspan#" align="center">#objNo#</td>
											<td rowspan="#cntspan#">#libname#</td>
											<td rowspan="#cntspan#" align="center">#weight#%</td>
											<td rowspan="#cntspan#">#criteria#</td>
											<td rowspan="#cntspan#">#target#</td>

										<!--- Apabila ada objective yang tidak mempunyai initiative --->
										<cfelseif calcSpan eq 1 and cntspan eq 1>
											<td align="center">#period_code#</td>
											<td align="center">#period_name_en#</td>
											<td align="center">#dateFormat(reference_date,application.config.date_output_format)#</td>
											<td rowspan="#cntspan#" align="center">#form_no#</td>
											<td align="center">#NIK#</td>
											<td>#htmleditformat(nama)#</td>
											<td align="center">#objNo#</td>
											<td>#libname#</td>
											<td align="center">#weight#%</td>
											<td>#criteria#</td>
											<td>#target#</td>
										<cfelse><!--- tidak perlu membuat <td> apabila bukan header objective --->
										</cfif>

										<!--- kolom HowToAchieve, SchedulePlan dan ActionResult yang tidak membutuhkan rowspan --->
										<td>#initiative#</td>
										<td align="center">#scheduleplan#</td>

										<!--- row span untuk kolom NIK sampai Target --->
										<!--- Apabila ada objective yang mempunyai initiative --->
										<cfif calcSpan eq 1 and cntspan gt 1>
											<td rowspan="#cntspan#">#TargetScoreCriteria#</td>
										<!--- Apabila ada objective yang tidak mempunyai initiative --->
										<cfelseif calcSpan eq 1 and cntspan eq 1>
											<td>#TargetScoreCriteria#</td>
										<cfelse><!--- tidak perlu membuat <td> apabila bukan header objective --->
										</cfif>
									</tr>
								</cfloop>
							</cfloop>
						<cfelse>
						<tr>
							<td align="center">----- #REQUEST.SFMLANG['NoRecords']# ----</td>
						<tr>
						</cfif>
					</tbody>
				</table>
			</cfoutput>
		</cfif>
		

		
	</cffunction>
	<!--- End custom Marc --->
	<cffunction name="ObjectiveReport">
    	<cfsetting showdebugoutput="yes" enablecfoutputonly="Yes">
    	
    	<cfparam name="isajax" default="No">
    	<cfparam name="media" default="print">
	    <cfparam name="inp_startdt" default="">
    	<cfparam name="inp_stage" default="">
	    <cfparam name="inp_display1" default="">
	    <cfparam name="inp_kpitype" default="">
    	<cfparam name="inp_viewpoint" default="">
	    <cfparam name="inp_emp_id" default="">
    	<cfparam name="inp_emp" default="">
		<cfparam name="INP_ALLPERIOD" default="">
	    <cfparam name="cocode" default="#request.scookie.cocode#">
	    <cfparam name="inp_showverified" default="">
	    
	    <cfparam name="inp_incld_draft" default="N">
	    <cfparam name="inp_perform_period" default="N">
	    <cfparam name="inp_show_notes" default="N">


	    <cfset inp_viewpoint = 0 ><!---Sementara alv--->
	    
	    <cfif inp_perform_period eq "Y">
		    <cfset hdn_periodcode= inp_hdnListPerformPeriod>
		<cfelse>
		    <cfset hdn_periodcode= 'PERFPD20200300001'>
		</cfif>

	    <cfset local.FORMMLANG="No|Employee No|Employee Name|Join Date|Position|Organization Unit|Grade|Employment Status|Personal Objective|Organization Unit Objective">
        <cfset FORMMLANG &= "|Performance Period|Stage|Viewpoint|Target|FDAchievement|Weight|No Records|Objective Type|Objective|Yes|FDNo|Include Draft|Notes|Achievement">
		<cfset REQUEST.SFMLANG=Application.SFParser.TransMLang(listAppend("Test",(isdefined("FORMMLANG")?FORMMLANG:""),"|"))>
        
    	<cfif inp_emp eq 'Y'>
    	    <cfset local.employee_id= ListQualify(FORM.inp_hdnListEmp,"'")>
    	<cfelse>
    	    <cfset local.employee_id= ListQualify(FORM.hdnSelectedinp_emp_id,"'")>
    	</cfif>
    	<cfset local.kpicheck = ListQualify(FORM.inp_kpitype,"")>
		<cfset local.disp= ListQualify(FORM.inp_display1,"")>
    	<cfset local.totdisp=listLen(disp)>
    	<cfif inp_stage eq 'planning'>
	        <cfset local.pstage = 'Planning'>
    	<cfelseif inp_stage eq 'monitoring'>
    	    <cfset local.pstage = 'Monitoring'> 
		<cfelseif inp_stage eq 'evaluation'>
    	    <cfset local.pstage = 'Evaluation'>
    	</cfif>

	    <cfif inp_viewpoint eq 0>
    	    <cfset local.viewp= "Set by Me">
    	<cfelse>
    	    <cfset local.viewp= "Finalized">
    	</cfif>
		<cfset local.idxperiodcode = "">
		<cfloop list="#hdn_periodcode#" index="idxperiodcode">
				<cfquery name="local.getPeriodName" datasource="#request.sdsn#">
					select period_name_#request.scookie.lang#  periodname from TPMMPERIOD where period_code = <cfqueryparam value="#idxperiodcode#" cfsqltype="cf_sql_varchar">
				</cfquery>
			
					<!--- ambil komponen apa yang digunakan pada period ini, apa perskpi/orgkpi/keduanya --->
				<cfquery name="local.qGetPeriodComponent" datasource="#request.sdsn#">
					SELECT component_code
					FROM TPMDPERIODCOMPONENT
					WHERE period_code = <cfqueryparam value="#idxperiodcode#" cfsqltype="cf_sql_varchar">
						AND company_code =<cfqueryparam value="#cocode#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset local.lstPerComp = valuelist(qGetPeriodComponent.component_code)>

				<cfoutput>
					<br />
					<!---<div align="center" style="margin-bottom: 5px" class="titleReport"><span style="font-size: larger;"><strong> </strong><span style="font-size: medium;"><strong>Objective Report</strong></span></span></div>--->

					<div style="text-align: left; margin-bottom:10px;">
						<div><strong>#REQUEST.SFMLANG['PerformancePeriod']# : </strong>#HTMLEditFormat(getPeriodName.periodname)#</div>
						<div><strong>#REQUEST.SFMLANG['Stage']# : </strong>#HTMLEditFormat(pstage)#</div>
						<!--- <cfif inp_stage neq 'monitoring'> <div><strong>#REQUEST.SFMLANG['Viewpoint']# : </strong></strong>#HTMLEditFormat(viewp)#</div></cfif> --->
					    <cfif inp_incld_draft eq 'Y'> <div><strong>#REQUEST.SFMLANG['IncludeDraft']# </strong>: Yes </div> </cfif>
					</div>

					<cfif UCASE(inp_stage) eq 'EVALUATION'>
					    
						<cfset local.qDataEmpAuth = getAllEmployeeBasedOnDataAuth(period_code=idxperiodcode)>
						<cfif qDataEmpAuth.recordcount gt 0>
							<cfset local.lstEmpAuth = ValueList(qDataEmpAuth.emp_id)>
						<cfelse>
							<cfset local.lstEmpAuth = "">
						</cfif>
								
						<cfquery name="local.qEmpReview" datasource="#REQUEST.SDSN#">
							select distinct
								TPMDPERFORMANCE_EVALH.reviewee_empid as reviewee_empid
								,TPMDPERFORMANCE_EVALH.form_no as form_no
								,TPMDPERFORMANCE_EVALH.period_code as period_code
								,TEODEMPCOMPANY.emp_no as emp_no
								,TEOMEMPPERSONAL.full_name as full_name
								,TEODEMPCOMPANY.start_date as joindate
								,TEOMPOSITION.pos_name_#request.scookie.lang# as pos
								,TEOMPOSITION.parent_path
								,TEOMPOSITION.DEPT_ID
								,DEPT.pos_name_#request.scookie.lang# as deptname
								,TEOMEMPLOYMENTSTATUS.employmentstatus_name_#request.scookie.lang# as empstatus
								,GRD.grade_name as empgrade
							from TPMDPERFORMANCE_EVALH 
							<!---<cfif inp_incld_draft eq "Y">--->
							    join tcltrequest treq on TPMDPERFORMANCE_EVALH.request_no = treq.req_no
							<!---</cfif>--->
							left join TEOMEMPPERSONAL on TEOMEMPPERSONAL.emp_id=TPMDPERFORMANCE_EVALH.reviewee_empid
							left join TEODEMPCOMPANY on TEODEMPCOMPANY.emp_id=TPMDPERFORMANCE_EVALH.reviewee_empid
							left join TEOMPOSITION on TPMDPERFORMANCE_EVALH.reviewee_posid=TEOMPOSITION.position_id
							left join TEOMPOSITION DEPT on TEOMPOSITION.DEPT_ID = DEPT.position_id
							left join TEOMEMPLOYMENTSTATUS on TPMDPERFORMANCE_EVALH.reviewee_employcode=TEOMEMPLOYMENTSTATUS.employmentstatus_code
							LEFT JOIN TEOMJOBGRADE GRD 
							ON (GRD.grade_code = TPMDPERFORMANCE_EVALH.reviewee_grade AND  GRD.company_id  = TEODEMPCOMPANY.company_id)
							WHERE 
								TEODEMPCOMPANY.COMPANY_ID =<cfqueryparam value="#request.scookie.COID#" cfsqltype="cf_sql_varchar">
								AND TPMDPERFORMANCE_EVALH.period_code = <cfqueryparam value="#idxperiodcode#" cfsqltype="cf_sql_varchar">
								<cfif employee_id neq "">
									AND TPMDPERFORMANCE_EVALH.reviewee_empid in (#PreserveSingleQuotes(employee_id)#) 
								<cfelse>
									<cfif qDataEmpAuth.recordcount gt 0 AND lstEmpAuth neq "">
										AND TPMDPERFORMANCE_EVALH.reviewee_empid in (#PreserveSingleQuotes(lstEmpAuth)#) 
									<cfelse>
										AND 1 =0
									</cfif>
								</cfif>
								<cfif inp_viewpoint eq 1>
								    <cfif inp_incld_draft eq "N">
								        AND TPMDPERFORMANCE_EVALH.isfinal = 1
								    <cfelse>
    								    AND (TPMDPERFORMANCE_EVALH.isfinal = 1 or treq.status = 1)
								    </cfif>
								<cfelse>
								    <cfif inp_incld_draft Neq "Y">
								        <!--- or treq.status = 1 --->
	                                    AND TPMDPERFORMANCE_EVALH.head_status = 1
								    </cfif>
								</cfif>
							 AND reviewee_empid NOT IN (select reviewee_empid FROM TPMDPERFORMANCE_FINAL 
                                 WHERE reviewee_empid = (select reviewee_empid) 
                                 AND period_code =  <cfqueryparam value="#idxperiodcode#" cfsqltype="cf_sql_varchar"> and is_upload = 'Y')	
							ORDER BY full_name
						</cfquery>
						<cfif qEmpReview.recordcount gt 0>
							<cfset local.POformno= ListQualify(qEmpReview.form_no,"'")>
						<cfelse>
							<cfset local.POformno= "">
						</cfif>
						
						<cfquery name="local.qGetLastRvr" datasource="#request.sdsn#">
							SELECT DISTINCT reviewer_empid FROM TPMDPERFORMANCE_EVALH
							WHERE isfinal = 1
							<cfif POformno neq "">
								AND form_no in (#PreserveSingleQuotes(POformno)#) 
							<cfelse>
								 AND 1 = 0
							</cfif>
						</cfquery>

						<cfset local.rvridQ=  ValueList(qGetLastRvr.reviewer_empid,",")>
						<cfset rvrid=  local.rvridQ>
						
						
						<table width="100%" cellspacing="1" cellpadding="1" border="1">
						<tbody>
							<cfif qEmpReview.recordcount neq 0>

								<!--- BUG50518-92358  <cfset POformno= ListQualify(qEmpReview.form_no,"'")> --->
								<cfset local.POformnoQ= ValueList(qEmpReview.form_no,",")>
								<cfset POformno= ListQualify(POformnoQ,"'")> 
								
								<cfif listfindnocase(lstPerComp,"PERSKPI")>
									<cfquery name="local.qPOname" datasource="#REQUEST.SDSN#">
										
										SELECT DISTINCT ED.lib_code, ED.lib_name_#request.scookie.lang# as kpiname
										FROM TPMDPERFORMANCE_EVALD ED
										INNER JOIN TPMDPERFORMANCE_EVALH EH 
											ON EH.form_no = ED.form_no
											AND EH.reviewer_empid = ED.reviewer_empid
										
										WHERE 
											<cfif POformno neq "">
												EH.form_no in (#PreserveSingleQuotes(POformno)#) 
											<cfelse>
												 1 = 0
											</cfif>
										
										AND ED.lib_type = 'PERSKPI' AND (ED.iscategory = 'N' OR ED.iscategory IS NULL)
									</cfquery>
									<cfset local.totPOspan = qPOname.recordcount*totdisp>
								<cfelse>
									<cfset local.totPOspan = 1>
								</cfif>
					
								<cfif listfindnocase(lstPerComp,"ORGKPI")>
									<cfquery name="local.qORname" datasource="#REQUEST.SDSN#">
										select distinct lib_code, lib_name_#request.scookie.lang# AS lib_name from TPMDPERFORMANCE_EVALKPI
										where period_code ='#qEmpReview.period_code#' AND ISCATEGORY='N'
									</cfquery>
									<cfset local.totORspan = qORname.recordcount*totdisp>
								<cfelse>
									<cfset local.totORspan = 1>
								</cfif>
			
								<cfif totPOspan eq 0>
									<cfset local.totPOspan = 1>
								</cfif>
								<cfif totORspan eq 0>
									<cfset local.totORspan = 1>
								</cfif>
								<tr>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['No']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['EmployeeNo']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['EmployeeName']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['JoinDate']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['Position']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['OrganizationUnit']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['Grade']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['EmploymentStatus']#</strong></td>
									<cfif listFindNoCase (kpicheck, 1) neq 0>
									   <td <cfif not listfindnocase(lstPerComp,"PERSKPI")>rowspan="3"</cfif> colspan="#totPOspan#" align="center"><strong>#REQUEST.SFMLANG['PersonalObjective']#</strong></td>
									</cfif>
									<cfif listFindNoCase (kpicheck, 2) neq 0>
										<td <cfif not listfindnocase(lstPerComp,"ORGKPI")>rowspan="3"</cfif> colspan="#totORspan#" align="center"><strong>#REQUEST.SFMLANG['OrganizationUnitObjective']#</strong></td>
									</cfif>
								</tr>
					
								<tr>
								<cfif listFindNoCase(kpicheck, 1) neq 0 and listfindnocase(lstPerComp,"PERSKPI")>
									<cfif qPOname.recordcount neq 0>
										<cfloop query="qPOname">
											<td colspan="#totdisp#" align="center">
											    <cfif len(kpiname) lte 150>
    												#htmleditformat(kpiname)#
    											<cfelse>
    												<cfset local.xv = 1>
													<cfset local.idx = "">
    												<cfloop from="1" to="#len(kpiname)/150#" index="idx">
    											        #HTMLEDITFORMAT(evaluate("MID(kpiname,#xv#,150)"))#<br/>
    													<cfset xv = xv + 150>
    												</cfloop>
    											</cfif>
											</td><!---(#lib_code#)&nbsp;--->
										</cfloop>
									<cfelse>
									   <td align="center"> - </td>
									</cfif>
								</cfif>

								<cfif listFindNoCase(kpicheck, 2) neq 0 and listfindnocase(lstPerComp,"ORGKPI")>
									<cfif qORname.recordcount neq 0>
										<cfloop query="qORname">
											<td colspan="#totdisp#"  align="center">
											    <cfif len(lib_name) lte 150>
    												#htmleditformat(lib_name)#
    											<cfelse>
    												<cfset local.xv = 1>
													<cfset local.idx = "">
    												<cfloop from="1" to="#len(lib_name)/150#" index="idx">
    											        #HTMLEDITFORMAT(evaluate("MID(lib_name,#xv#,150)"))#<br/>
    													<cfset xv = xv + 150>
    												</cfloop>
    											</cfif>
											</td><!---(#lib_code#)&nbsp;--->
										</cfloop>
									<cfelse>
										<td align="center"> - </td>
									</cfif>
								</cfif>
								</tr>

								<tr>
								<cfif listFindNoCase(kpicheck, 1) neq 0 and listfindnocase(lstPerComp,"PERSKPI")>
									<cfif qPOname.recordcount neq 0>
										<cfloop query="qPOname">
											<cfif listFindNoCase(disp, 1) neq 0>
											   <td>#REQUEST.SFMLANG['Target']#</td>
											</cfif>
											<cfif listFindNoCase(disp, 3) neq 0>
											   <td>#REQUEST.SFMLANG['FDAchievement']#</td>
											</cfif>
											<cfif listFindNoCase(disp, 2) neq 0>
											   <td>#REQUEST.SFMLANG['Weight']#</td>
										   </cfif>
										</cfloop>
									<cfelse>
										<td align="center"> - </td>
									</cfif> 
								</cfif>
				
								<cfif listFindNoCase(kpicheck, 2) neq 0 and listfindnocase(lstPerComp,"ORGKPI")>
									<cfif qORname.recordcount neq 0>
										<cfloop query="qORname">
											<cfif listFindNoCase(disp, 1) neq 0>
											   <td>#REQUEST.SFMLANG['Target']#</td>
											</cfif>
											<cfif listFindNoCase(disp, 3) neq 0>
											   <td>#REQUEST.SFMLANG['FDAchievement']#</td>
											</cfif>
											<cfif listFindNoCase(disp, 2) neq 0>
											   <td>#REQUEST.SFMLANG['Weight']#</td>
										   </cfif>
										</cfloop>
									<cfelse>
										<td align="center"> - </td>
									</cfif>
								</cfif>
								</tr>
								
								<cfloop query="qEmpReview">
								<tr>
								
    								<!---Enc Get Last reviewer--->
    								<cfquery name="LOCAL.qGetLastRvr" datasource="#request.sdsn#">
    									SELECT <cfif request.dbdriver eq "MSSQL">TOP 1</cfif> modified_date,created_by,reviewer_empid,review_step,form_no,company_code
    									FROM TPMDPERFORMANCE_EVALH 
    									where form_no = '#qEmpReview.form_no#'
    									ORDER BY modified_date DESC <cfif request.dbdriver eq "MYSQL">LIMIT 1</cfif>
    								</cfquery>
    								<cfset rvrid = qGetLastRvr.reviewer_empid>
    								<!---Enc Get Last reviewer--->		
								
									<td>#currentrow#</td>
									<td>#emp_no#</td>
									<td>#htmleditformat(full_name)#</td>
									<td>#dateFormat(joindate,application.config.date_output_format)#</td>
									<td>#htmleditformat(pos)#</td>
					
									<cfquery name="local.qORUNIT" datasource="#REQUEST.SDSN#">
										select pos_name_#request.scookie.lang# as orunit from TEOMPOSITION where position_id = '#qEmpReview.DEPT_ID#'
									</cfquery>
									<td>#htmleditformat(qORUNIT.orunit)#</td>
									
									<cfquery name="local.qGetGradeAndEmpStatus" datasource="#request.sdsn#">
										SELECT ES.employmentstatus_name_#request.scookie.lang# AS empstatus, GRD.grade_name AS empgrade
										FROM TEODEMPCOMPANY EC 
										INNER JOIN TEOMJOBGRADE GRD 
										ON (GRD.grade_code = EC.grade_code AND  GRD.company_id  = EC.company_id)
										INNER JOIN TEOMEMPLOYMENTSTATUS ES ON ES.employmentstatus_code = EC.employ_code
										WHERE EC.emp_no =  <cfqueryparam value="#emp_no#" cfsqltype="cf_sql_varchar">
										AND EC.company_id =  <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer">
									</cfquery>
									<cfif Len(trim(qEmpReview.empgrade)) eq 0>
										<cfset local.varempgrade = qGetGradeAndEmpStatus.empgrade>
									<cfelse>
										<cfset local.varempgrade = qEmpReview.empgrade>
									</cfif>
									<cfif Len(trim(qEmpReview.empstatus)) eq 0>
										<cfset local.varempstatus = qGetGradeAndEmpStatus.empstatus>
									<cfelse>
										<cfset local.varempstatus = qEmpReview.empstatus>
									</cfif>
									
									<td>#htmleditformat(varempgrade)#</td>
									<td>#htmleditformat(varempstatus)#</td>
					
									<cfif listFindNoCase(kpicheck, 1) neq 0 and listfindnocase(lstPerComp,"PERSKPI")>
										<cfif qPOname.recordcount neq 0>
											<cfloop query="qPOname">
											    <cfquery name="local.qValue1" datasource="#REQUEST.SDSN#">
													select DISTINCT TPMDPERFORMANCE_EVALD.target, TPMDPERFORMANCE_EVALD.achievement, TPMDPERFORMANCE_EVALD.weight
													from TPMDPERFORMANCE_EVALD
													left join TPMDPERFORMANCE_EVALH on TPMDPERFORMANCE_EVALH.form_no=TPMDPERFORMANCE_EVALD.form_no
													where TPMDPERFORMANCE_EVALD.form_no = '#qEmpReview.form_no#'
														and TPMDPERFORMANCE_EVALH.reviewee_empid= '#qEmpReview.reviewee_empid#'
														and TPMDPERFORMANCE_EVALD.lib_code= '#qPOname.lib_code#'
														
														<cfif int(inp_viewpoint) eq 1>
															
															and TPMDPERFORMANCE_EVALD.reviewer_empid in (select reviewer_empid from TPMDPERFORMANCE_EVALH  where form_no= '#qEmpReview.form_no#' and isfinal=1)
														<cfelse>
															and TPMDPERFORMANCE_EVALD.reviewer_empid= '#rvrid#'
														</cfif>
														AND TPMDPERFORMANCE_EVALD.lib_type = 'PERSKPI'
												</cfquery>
												
												<cfif listFindNoCase(disp, 1) neq 0>
													<td align="center">
														<cfif qValue1.target neq "">
															#HTMLEDITFORMAT(qValue1.target)# 
														<cfelse> - 
														</cfif> 
														<!--- <div style="display:none;"><cfdump var="#qValue1#"></div> --->
													</td>
												</cfif>
												<cfif listFindNoCase(disp, 3) neq 0>
													<td align="center">
														<cfif qValue1.achievement neq "">
															#qValue1.achievement#
														<cfelse> - 
														</cfif>
													 </td>
												</cfif>
												<cfif listFindNoCase(disp, 2) neq 0>
													<td align="center">
														<cfif qValue1.weight neq "">
															#APPLICATION.SFUTIL.SFNUM(qValue1.weight,'int')# 
														<cfelse> - 
														</cfif> 
													</td>
												</cfif>
											</cfloop>
										<cfelse>
											<td align="center"> - </td>
										</cfif>
                                    <cfelse>
                                        <cfif listFindNoCase(kpicheck, 1) neq 0><td align="center"> - </td></cfif>
									</cfif>
					
									<cfif listFindNoCase(kpicheck, 2) neq 0 and listfindnocase(lstPerComp,"ORGKPI")>
										<cfif qORname.recordcount neq 0>
											<cfloop query="qORname">
												<cfquery name="local.qValue2" datasource="#REQUEST.SDSN#">
													select DISTINCT TPMDPERFORMANCE_EVALKPI.target, TPMDPERFORMANCE_EVALKPI.achievement, TPMDPERFORMANCE_EVALKPI.weight
													from TPMDPERFORMANCE_EVALKPI 
													left join TPMDPERFORMANCE_EVALH on TPMDPERFORMANCE_EVALH.period_code=TPMDPERFORMANCE_EVALKPI.period_code
													where TPMDPERFORMANCE_EVALKPI.period_code = '#qEmpReview.period_code#'
														and TPMDPERFORMANCE_EVALH.reviewee_empid= '#qEmpReview.reviewee_empid#'
														and TPMDPERFORMANCE_EVALKPI.lib_code= '#qORname.lib_code#'
												</cfquery>

												<cfif listFindNoCase(disp, 1) neq 0>
													<td align="center">
														<cfif qValue2.target neq "">
															  #HTMLEDITFORMAT(qValue2.target)# 
														<cfelse> -
														</cfif> 
													</td>
												</cfif>
												<cfif listFindNoCase(disp, 3) neq 0>
													<td align="center"> 
														<cfif qValue2.achievement neq "">
															#qValue2.achievement# 
														<cfelse> - 
														</cfif> 
													</td>
												</cfif>
												<cfif listFindNoCase(disp, 2) neq 0>
													<td align="center">
														<cfif qValue2.weight neq "">
															#APPLICATION.SFUTIL.SFNUM(qValue2.weight,'int')# 
														<cfelse> - 
														</cfif> 
													</td>
												</cfif>
											</cfloop>
										<cfelse>
											<td align="center"> - </td>
										</cfif>
									<cfelse>
									    <cfif listFindNoCase(kpicheck, 2) neq 0><td align="center"> - </td></cfif>
									</cfif>
									
								</tr>
								</cfloop>
							<cfelse>
							<tr>
								<td align="center">----- #REQUEST.SFMLANG['NoRecords']# ----</td>
							<tr>   
							</cfif>
						</tbody>
						</table>
						
					<cfelseif inp_stage eq 'planning'>
					
						<cfquery name="local.qEmpReview" datasource="#REQUEST.SDSN#">
							<cfif request.scookie.cocode eq "issid">	
								SET STATEMENT max_statement_time=2500 FOR 
							</cfif>
							select distinct
								TPMDPERFORMANCE_PLANH.reviewee_empid
								,TPMDPERFORMANCE_PLANH.form_no as form_no
								,TPMDPERFORMANCE_PLANH.period_code as period_code
								,TEODEMPCOMPANY.emp_no as emp_no
								,TEOMEMPPERSONAL.full_name as full_name
								,TEODEMPCOMPANY.start_date as joindate
								,TEOMPOSITION.pos_name_#request.scookie.lang# as pos
								,TEOMPOSITION.parent_path
								,TEOMPOSITION.DEPT_ID
								,DEPT.pos_name_#request.scookie.lang# as deptname
								,TEOMEMPLOYMENTSTATUS.employmentstatus_name_#request.scookie.lang# as empstatus
								,GRD.grade_name as empgrade
							from TPMDPERFORMANCE_PLANH 
							LEFT join TEOMEMPPERSONAL on TEOMEMPPERSONAL.emp_id=TPMDPERFORMANCE_PLANH.reviewee_empid
							LEFT join TEODEMPCOMPANY on TEODEMPCOMPANY.emp_id=TPMDPERFORMANCE_PLANH.reviewee_empid
							LEFT join TEOMPOSITION on TPMDPERFORMANCE_PLANH.reviewee_posid=TEOMPOSITION.position_id
							LEFT join TEOMPOSITION DEPT on TEOMPOSITION.DEPT_ID = DEPT.position_id
							LEFT join TEOMEMPLOYMENTSTATUS on TPMDPERFORMANCE_PLANH.reviewee_employcode=TEOMEMPLOYMENTSTATUS.employmentstatus_code
							LEFT JOIN TEOMJOBGRADE GRD 
							ON (GRD.grade_code = TPMDPERFORMANCE_PLANH.reviewee_grade AND  GRD.company_id  = TEODEMPCOMPANY.company_id )
							WHERE TEODEMPCOMPANY.COMPANY_ID = <cfqueryparam value="#request.scookie.COID#" cfsqltype="cf_sql_varchar">
								AND TPMDPERFORMANCE_PLANH.period_code = <cfqueryparam value="#idxperiodcode#" cfsqltype="cf_sql_varchar">
								<cfif employee_id neq "">
									AND TPMDPERFORMANCE_PLANH.reviewee_empid in (#PreserveSingleQuotes(employee_id)#) 
								</cfif>
								
								<cfif inp_viewpoint eq 1>
									<cfif inp_incld_draft eq "N">
									AND TPMDPERFORMANCE_PLANH.isfinal = 1 
									<cfelse>
									and (TPMDPERFORMANCE_PLANH.isfinal = 1 or treq.status = 1)
									</cfif>
								<cfelse>
									<cfif inp_incld_draft neq "Y">
										
										AND TPMDPERFORMANCE_PLANH.head_status = 1
									</cfif>
								</cfif>
							ORDER BY full_name
						</cfquery>
						<!---<cfdump  var="#qEmpReview#" label='905'>--->
					
						<cfset local.POformnoQ= ValueList(qEmpReview.form_no,",")>
					
						<cfset POformno= ListQualify(POformnoQ,"'")> 

						<cfset local.deptidQ= ValueList(qEmpReview.dept_id,",")>
						<cfset local.deptider= ListQualify(deptidQ,"'")> 
						
				
						<cfset rvrid = ListQualify(request.scookie.user.empid,"'")>
							
						
						<table width="100%" cellspacing="1" cellpadding="1" border="1">
						<tbody>
							<cfif qEmpReview.recordcount gt 0>

								<!---Enc Get Last reviewer override diatas--->
								<cfquery name="LOCAL.qGetLastRvr" datasource="#request.sdsn#">
									SELECT <cfif request.dbdriver eq "MSSQL">TOP 1</cfif> modified_date,created_by,reviewer_empid,review_step,form_no,company_code
									FROM TPMDPERFORMANCE_PLANH 
									where form_no in (#PreserveSingleQuotes(POformno)#) 
									ORDER BY modified_date DESC <cfif request.dbdriver eq "MYSQL">LIMIT 1</cfif>
								</cfquery>
								<!---<cfdump  var="#qGetLastRvr#" label='929'>--->
								<cfset rvrid = ListQualify(qGetLastRvr.reviewer_empid,"'")>
								<!---Enc Get Last reviewer--->

								<cfset POformnoQ= ValueList(qEmpReview.form_no,",")>
								<cfset POformno= ListQualify(POformnoQ,"'")>  
								
								<cfif listfindnocase(lstPerComp,"PERSKPI")>                    
									<cfquery name="local.qPOname" datasource="#REQUEST.SDSN#">
										select distinct lib_code, lib_name_#request.scookie.lang# AS libname, lib_order from TPMDPERFORMANCE_PLAND
										WHERE 
											<cfif POformno neq "">
												form_no in (#PreserveSingleQuotes(POformno)#)
												<!--- form_no in (#ListQualify(POformno,"'",",")#)  --->
											<cfelse>
												1 = 0
											</cfif>
										
											AND iscategory='N'
											<cfif rvrid neq "">
											AND reviewer_empid IN (#PreserveSingleQuotes(rvrid)#)
											<!--- AND reviewer_empid IN (#ListQualify(rvrid,"'",",")#) --->
											</cfif>
											
										 ORDER BY lib_order ASC <!---hapus remark untuk TCK1909-0522548--->
									</cfquery>
									<!---<cfdump  var="#qPOname#" label='955'>--->
									
									
									<cfset totPOspan = qPOname.recordcount*totdisp>
								<cfelse>
									<cfset totPOspan = 1>
								</cfif>
								
								<cfif listfindnocase(lstPerComp,"ORGKPI") >
									<cfquery name="local.qORname" datasource="#REQUEST.SDSN#"> 
										select distinct lib_code, lib_name_#request.scookie.lang# AS libname from TPMDPERFORMANCE_PLANKPI
										where period_code ='#qEmpReview.period_code#' AND ISCATEGORY='N'
											<!--- Yan BUG50315-39678 --->
											AND orgunit_id IN (#PreserveSingleQuotes(deptider)#)
											<cfif POformno neq "">
												AND form_no in (#PreserveSingleQuotes(POformno)#) 
											<cfelse>
												AND	1 = 0
											</cfif>
											
									</cfquery>
									<!---<cfdump  var="#qORname#" label='974'>--->
									<cfset totORspan = qORname.recordcount*totdisp>
								<cfelse>
									<cfset totORspan = 1>
								</cfif>
							
								<tr>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['No']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['EmployeeNo']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['EmployeeName']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['JoinDate']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['Position']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['OrganizationUnit']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['Grade']#</strong></td>
									<td rowspan="3"><strong>#REQUEST.SFMLANG['EmploymentStatus']#</strong></td>
									<cfif listFindNoCase(kpicheck, 1) neq 0 and listfindnocase(lstPerComp,"PERSKPI")>
										<td colspan="#totPOspan#" align="center"><strong>#REQUEST.SFMLANG['PersonalObjective']#</strong></td>
									</cfif>
									<cfif listFindNoCase(kpicheck, 2) neq 0 and listfindnocase(lstPerComp,"ORGKPI")>
										<td colspan="#totORspan#" align="center"><strong>#REQUEST.SFMLANG['OrganizationUnitObjective']#</strong></td>
									</cfif>
								</tr>
								<tr>
									<cfif listFindNoCase(kpicheck, 1) neq 0 and listfindnocase(lstPerComp,"PERSKPI")>
										<cfif qPOname.recordcount neq 0>
											<cfloop query="qPOname">
												<td colspan="#totdisp#" align="center">
												    <cfif len(libname) lte 150>
    												    #htmleditformat(libname)#
    												<cfelse>
    												    <cfset local.xv = 1>
														<cfset local.idx = "">
    												    <cfloop from="1" to="#len(libname)/150#" index="idx">
    													    #HTMLEDITFORMAT(evaluate("MID(libname,#xv#,150)"))# <br/>
    														<cfset xv = xv + 150>
    													</cfloop>
    												</cfif>
												</td><!---(#libname#)&nbsp;--->
											</cfloop>
										<cfelse>
											<td align="center"> - </td>
										</cfif>
									</cfif>
									<cfif listFindNoCase(kpicheck, 2) neq 0 and listfindnocase(lstPerComp,"ORGKPI")>
										<cfif qORname.recordcount neq 0>
											<cfloop query="qORname">
												<td colspan="#totdisp#"  align="center">
												    <cfif len(libname) lte 150>
    												    #htmleditformat(libname)#
    												<cfelse>
    												    <cfset local.xv = 1>
														
														<cfset local.idx = "">
    												    <cfloop from="1" to="#len(libname)/150#" index="idx">
    													    #HTMLEDITFORMAT(evaluate("MID(libname,#xv#,150)"))#<br/>
    														<cfset xv = xv + 150>
    													</cfloop>
    												</cfif>
												</td><!---(#libname#)&nbsp;--->
											</cfloop>
										<cfelse>
											<td align="center"> - </td>
										</cfif>
									</cfif>
								</tr>
								<tr>
									<cfif listFindNoCase(kpicheck, 1) neq 0 and listfindnocase(lstPerComp,"PERSKPI")>
										<cfif qPOname.recordcount neq 0>
											<cfloop query="qPOname">
												<cfif listFindNoCase(disp, 1) neq 0>
													<td>#REQUEST.SFMLANG['Target']#</td>
												</cfif>
												<cfif listFindNoCase(disp, 2) neq 0>
													<td>#REQUEST.SFMLANG['Weight']#</td>
												</cfif>
											</cfloop>
										<cfelse>
											<td align="center"> - </td>
										</cfif>
									</cfif>
									<cfif listFindNoCase(kpicheck, 2) neq 0 and listfindnocase(lstPerComp,"ORGKPI")>
										<cfif qORname.recordcount neq 0>
											<cfloop query="qORname">
												<cfif listFindNoCase(disp, 1) neq 0>
												   <td>#REQUEST.SFMLANG['Target']#</td>
												</cfif>
												<cfif listFindNoCase(disp, 2) neq 0>
												   <td>#REQUEST.SFMLANG['Weight']#</td>
												</cfif>
											</cfloop>
										<cfelse>
											<td align="center"> - </td>
										</cfif>
									</cfif>
								</tr>
								<cfloop query="qEmpReview">
								<tr>
									<td>#currentrow#</td>
									<td>#emp_no#</td>
									<td>#htmleditformat(full_name)#</td>
									<td>#dateFormat(joindate,application.config.date_output_format)#</td>
									<td>#htmleditformat(pos)#</td>
									<cfquery name="local.qORUNIT" datasource="#REQUEST.SDSN#">
										select pos_name_#request.scookie.lang# as orunit from TEOMPOSITION where position_id = '#qEmpReview.DEPT_ID#'
									</cfquery>
									<td>#htmleditformat(qORUNIT.orunit)#</td>
									<cfquery name="local.qGetGradeAndEmpStatus" datasource="#request.sdsn#">
										SELECT ES.employmentstatus_name_#request.scookie.lang# AS empstatus, GRD.grade_name AS empgrade
										FROM TEODEMPCOMPANY EC 
										INNER JOIN TEOMJOBGRADE GRD 
										ON (GRD.grade_code = EC.grade_code AND  GRD.company_id  = EC.company_id)
										INNER JOIN TEOMEMPLOYMENTSTATUS ES ON ES.employmentstatus_code = EC.employ_code
										WHERE EC.emp_no =  <cfqueryparam value="#emp_no#" cfsqltype="cf_sql_varchar">
										AND EC.company_id =  <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer">
									</cfquery>
									<cfif Len(trim(qEmpReview.empgrade)) eq 0>
										<cfset local.varempgrade = qGetGradeAndEmpStatus.empgrade>
									<cfelse>
										<cfset local.varempgrade = qEmpReview.empgrade>
									</cfif>
									<cfif Len(trim(qEmpReview.empstatus)) eq 0>
										<cfset local.varempstatus = qGetGradeAndEmpStatus.empstatus>
									<cfelse>
										<cfset local.varempstatus = qEmpReview.empstatus>
									</cfif>
									<td>#htmleditformat(varempgrade)#</td>
									<td>#htmleditformat(varempstatus)#</td>
									<!---Enc Get Last reviewer--->
									<cfquery name="LOCAL.qGetLastRvr" datasource="#request.sdsn#">
										SELECT <cfif request.dbdriver eq "MSSQL">TOP 1</cfif> modified_date,created_by,reviewer_empid,review_step,form_no,company_code
										FROM TPMDPERFORMANCE_PLANH 
										where form_no in (#PreserveSingleQuotes(POformno)#) 
										and TPMDPERFORMANCE_PLANH.reviewee_empid= '#qEmpReview.reviewee_empid#'
										ORDER BY modified_date DESC <cfif request.dbdriver eq "MYSQL">LIMIT 1</cfif>
									</cfquery>
									
									<cfset rvrid = qGetLastRvr.reviewer_empid>
									<!---Enc Get Last reviewer--->
									<cfif listFindNoCase(kpicheck, 1) neq 0 and listfindnocase(lstPerComp,"PERSKPI")>
										<cfif qPOname.recordcount neq 0>
											<cfloop query="qPOname">
												
												<cfquery name="local.qValue1" datasource="#REQUEST.SDSN#">
													select DISTINCT TPMDPERFORMANCE_PLAND.target, TPMDPERFORMANCE_PLAND.weight
													from TPMDPERFORMANCE_PLAND 
													left join TPMDPERFORMANCE_PLANH on TPMDPERFORMANCE_PLANH.form_no=TPMDPERFORMANCE_PLAND.form_no
													where TPMDPERFORMANCE_PLAND.form_no = '#qEmpReview.form_no#'
														and TPMDPERFORMANCE_PLANH.reviewee_empid= '#qEmpReview.reviewee_empid#'
														and TPMDPERFORMANCE_PLAND.lib_code= '#qPOname.lib_code#'
														and TPMDPERFORMANCE_PLAND.reviewer_empid= '#rvrid#'
												</cfquery>
												<!---<cfdump  var="#qValue1#" label='1127'>--->
												
												<cfif listFindNoCase(disp, 1) neq 0>
													<td align="center">
														<cfif qValue1.target neq "">
															#HTMLEDITFORMAT(qValue1.target)#
														<cfelse> - 
														</cfif>
													</td>
												</cfif>
												<cfif listFindNoCase(disp, 2) neq 0>
													<td align="center">
														<cfif qValue1.weight neq "">
															#APPLICATION.SFUTIL.SFNUM(qValue1.weight,'int')#
														<cfelse>
														</cfif> 
													</td>
												</cfif>
											</cfloop>
										<cfelse>
											<td align="center"> - </td>
										</cfif>
									</cfif>

									<cfif listFindNoCase(kpicheck, 2) neq 0 and listfindnocase(lstPerComp,"ORGKPI")>
										<cfif qORname.recordcount neq 0>
											<cfloop query="qORname">
												<cfquery name="local.qValue2" datasource="#REQUEST.SDSN#"> 
													select DISTINCT TPMDPERFORMANCE_PLANKPI.target, TPMDPERFORMANCE_PLANKPI.weight
													from TPMDPERFORMANCE_PLANKPI 
													left join TPMDPERFORMANCE_PLANH on TPMDPERFORMANCE_PLANH.form_no=TPMDPERFORMANCE_PLANKPI.form_no
													where TPMDPERFORMANCE_PLANKPI.form_no = '#qEmpReview.form_no#'
														and TPMDPERFORMANCE_PLANH.reviewee_empid= '#qEmpReview.reviewee_empid#'
														and TPMDPERFORMANCE_PLANKPI.lib_code= '#qORname.lib_code#'
												</cfquery>
												<cfif listFindNoCase(disp, 1) neq 0>
													<td align="center"> 
														<cfif qValue2.target neq "">
															#HTMLEDITFORMAT(qValue2.target)# 
														<cfelse> - 
														</cfif> 
													</td>
												</cfif>
												<cfif listFindNoCase(disp, 2) neq 0>
													<td align="center">
														<cfif qValue2.weight neq "">
															#APPLICATION.SFUTIL.SFNUM(qValue2.weight,'int')# 
														<cfelse> - 
														</cfif> 
													</td>
												</cfif>
											</cfloop>
										<cfelse>
											<td align="center"> - </td>
										</cfif>
									</cfif>
								</tr>
								</cfloop>
							<cfelse>
								<tr>
									<td align="center">----- #REQUEST.SFMLANG['NoRecords']# ----</td>
								<tr>   
							</cfif>
						</tbody>
						</table>
					
					
					<cfelseif ucase(inp_stage) eq 'MONITORING'> <!---start : maghdalenasp ENC51015-79814---> 
						<cfset local.RVRID  = request.scookie.user.empid>
						<cfset local.qDataEmpAuth = getAllEmployeeBasedOnDataAuth(period_code=idxperiodcode)>
						<cfif qDataEmpAuth.recordcount gt 0>
							<cfset local.lstEmpAuth = ValueList(qDataEmpAuth.emp_id)>
						<cfelse>
							<cfset local.lstEmpAuth = "">
						</cfif>
						
						<cfquery name="local.qEmpReview" datasource="#REQUEST.SDSN#">
							<cfif request.scookie.cocode eq "issid">	
								SET STATEMENT max_statement_time=2500 FOR 
							</cfif>
							select 
								TPMDPERFORMANCE_PLANH.reviewee_empid
								,TPMDPERFORMANCE_PLANH.form_no as form_no
								,TPMDPERFORMANCE_PLANH.period_code as period_code
								,TEODEMPCOMPANY.emp_no as emp_no
								,TEOMEMPPERSONAL.full_name as full_name
								,TEODEMPCOMPANY.start_date as joindate
								,TEOMPOSITION.pos_name_#request.scookie.lang# as pos
								,TEOMPOSITION.parent_path
								,TEOMPOSITION.DEPT_ID
                                ,DEPT.pos_name_#request.scookie.lang# as deptname
								,TEOMEMPLOYMENTSTATUS.employmentstatus_name_#request.scookie.lang# as empstatus
								,GRD.grade_name as empgrade
							from TPMDPERFORMANCE_PLANH 
							INNER join TEOMEMPPERSONAL on TEOMEMPPERSONAL.emp_id=TPMDPERFORMANCE_PLANH.reviewee_empid
							INNER join TEODEMPCOMPANY on TEODEMPCOMPANY.emp_id=TPMDPERFORMANCE_PLANH.reviewee_empid
							INNER join TEOMPOSITION on TPMDPERFORMANCE_PLANH.reviewee_posid=TEOMPOSITION.position_id
	                        INNER join TEOMPOSITION DEPT on TEOMPOSITION.DEPT_ID = DEPT.position_id
							INNER join TEOMEMPLOYMENTSTATUS on TPMDPERFORMANCE_PLANH.reviewee_employcode=TEOMEMPLOYMENTSTATUS.employmentstatus_code
							INNER JOIN TEOMJOBGRADE GRD 
							ON (GRD.grade_code = TPMDPERFORMANCE_PLANH.reviewee_grade AND  GRD.company_id  = TEODEMPCOMPANY.company_id)
							LEFT join TPMDPERFORMANCE_MIDH on (TPMDPERFORMANCE_MIDH.form_no = TPMDPERFORMANCE_PLANH.form_no 
							AND TPMDPERFORMANCE_MIDH.company_code = TPMDPERFORMANCE_PLANH.company_code)
							
							WHERE TEODEMPCOMPANY.COMPANY_ID = <cfqueryparam value="#request.scookie.COID#" cfsqltype="cf_sql_varchar"> 
								AND TPMDPERFORMANCE_PLANH.period_code = <cfqueryparam value="#idxperiodcode#" cfsqltype="cf_sql_varchar">
								<cfif employee_id neq "">
									AND TPMDPERFORMANCE_PLANH.reviewee_empid in (#PreserveSingleQuotes(employee_id)#) 
								<cfelse>
									<cfif qDataEmpAuth.recordcount gt 0 AND lstEmpAuth neq "">
										AND TPMDPERFORMANCE_PLANH.reviewee_empid in (#PreserveSingleQuotes(lstEmpAuth)#) 
									<cfelse>
										AND 1 =0
									</cfif>
								</cfif>
							 AND TPMDPERFORMANCE_PLANH.isfinal=1	 
							GROUP BY TPMDPERFORMANCE_PLANH.reviewee_empid
								,TPMDPERFORMANCE_PLANH.form_no 
								,TPMDPERFORMANCE_PLANH.period_code 
								,TEODEMPCOMPANY.emp_no
								,TEOMEMPPERSONAL.full_name 
								,TEODEMPCOMPANY.start_date 
								,TEOMPOSITION.pos_name_#request.scookie.lang# 
								,TEOMPOSITION.parent_path
								,TEOMPOSITION.DEPT_ID
                                ,DEPT.pos_name_#request.scookie.lang# 
								,TEOMEMPLOYMENTSTATUS.employmentstatus_name_#request.scookie.lang# 
								,GRD.grade_name 
							ORDER BY full_name	
						</cfquery>
						
							<table width="100%" cellspacing="1" cellpadding="1" border="1">
							<tbody>
								<cfif qEmpReview.recordcount neq 0>
									<cfset local.POformno= "">
									<cfset local.lstorgunit_id = "">
									<cfloop query="qEmpReview">
										<cfif ListfindNoCase(POformno,qEmpReview.form_no) eq 0>
											<cfset POformno = ListAppend(POformno,qEmpReview.form_no)>
										</cfif>
										<cfif ListfindNoCase(lstorgunit_id,qEmpReview.dept_id) eq 0>
											<cfset lstorgunit_id = ListAppend(lstorgunit_id,qEmpReview.dept_id)>
										</cfif>
									</cfloop>
									<cfset local.POformno= ListQualify(POformno,"'")> 
									
									<cfquery name="local.qGetListMonthMonitoring" datasource="#REQUEST.SDSN#">
									select  monitoring_date,monitoring_period from 
									TPMDPERFORMANCE_MIDD where form_no in (#PreserveSingleQuotes(POformno)#) 
									group by monitoring_date,monitoring_period
									order by monitoring_date
									</cfquery>
								
									<cfif qGetListMonthMonitoring.recordcount gt 0 AND (ValueList(qGetListMonthMonitoring.monitoring_date,"~") neq "" AND ValueList(qGetListMonthMonitoring.monitoring_date,"~") neq "0")>
										<cfset local.listMthMonitoring = ValueList(qGetListMonthMonitoring.monitoring_date,"~")>
									<cfelse>
										<cfset local.listMthMonitoring = "">
									</cfif>
									<cfset local.typeMonitoring = UCASE(qGetListMonthMonitoring.monitoring_period)>
									<cfset local.lstorgunit_id= ListQualify(lstorgunit_id,"'")> 
									
									<cfif listfindnocase(lstPerComp,"PERSKPI")>                    
										<cfquery name="local.qPOname" datasource="#REQUEST.SDSN#">
											select distinct PLD.lib_code, PLD.lib_name_#request.scookie.lang# AS libname ,PLD.lib_depth, PLD.lib_name_#request.scookie.lang#,PLD.lib_order from TPMDPERFORMANCE_PLAND PLD LEFT JOIN TPMDPERFORMANCE_MIDD MIDD
											ON (PLD.form_no = MIDD.form_no AND  PLD.company_code = MIDD.company_code AND  PLD.lib_code = MIDD.lib_code AND  MIDD.lib_type = 'PERSKPI' )
											WHERE 
											<cfif POformno neq "">
												PLD.form_no in (#PreserveSingleQuotes(POformno)#) 
											<cfelse>
												1 =0
											</cfif>
											
												AND PLD.iscategory='N'
											ORDER BY PLD.lib_order,PLD.lib_depth, PLD.lib_name_#request.scookie.lang# 
										</cfquery>
										
										
										<cfset local.totPOspan = qPOname.recordcount*totdisp>
									<cfelse>
										<cfset local.totPOspan = 1>
									</cfif>
									
									<cfif listfindnocase(lstPerComp,"ORGKPI") gt 0 >
									
										<cfquery name="qORname" datasource="#REQUEST.SDSN#"> 
											select distinct PKPI.lib_code, PKPI.lib_name_#request.scookie.lang# AS libname ,PKPI.lib_depth, PKPI.lib_name_#request.scookie.lang#,PKPI.lib_order  from TPMDPERFORMANCE_PLANKPI PKPI LEFT JOIN TPMDPERFORMANCE_MIDD MIDD
											ON (PKPI.company_code = MIDD.company_code AND  PKPI.lib_code = MIDD.lib_code AND  MIDD.lib_type = 'ORGKPI')
											where PKPI.period_code IN (select period_code from TPMDPERFORMANCE_PLANH where 
											<cfif POformno neq "">
												form_no in (#PreserveSingleQuotes(POformno)#))
											<cfelse>
												1=0
											</cfif>
											
											AND PKPI.ISCATEGORY='N' 
											<cfif lstorgunit_id neq "">
												AND PKPI.orgunit_id IN (#PreserveSingleQuotes(lstorgunit_id)#)
											</cfif>
											ORDER BY PKPI.lib_order,PKPI.lib_depth, PKPI.lib_name_#request.scookie.lang# 
										 
										</cfquery>
										
										<cfset local.totORspan = qORname.recordcount*totdisp> 
										
									<cfelse>
										<cfset local.totORspan = 1>
									</cfif>
									
									<cfset local.tempRowSpan = 1>
									<cfif listFindNoCase(disp, 3) neq 0 AND listMthMonitoring neq ''> <!--- TCK0918-196891  --->
								        <cfif inp_showverified neq "Y">
								             <cfset tempRowSpan = 3>
								        <cfelse>
								            <cfset tempRowSpan = 2>
								       </cfif>
									</cfif>
									<!---tanpa tab achievement--->
									<cfif listFindNoCase(disp, 3) eq 0 AND ( listfindnocase(lstPerComp,"PERSKPI") OR listfindnocase(lstPerComp,"ORGKPI") )>
									    <cfset tempRowSpan = 3>
									</cfif>
									<!---tanpa tab achievement--->
									
									<tr>
									    <cfif listFindNoCase(disp, 3) eq 0> <!---format tab menampilkan achievement--->
									        <td rowspan="3"><strong>#REQUEST.SFMLANG['No']#</strong></td>
									    </cfif>
										<td rowspan="#tempRowSpan#"><strong>#REQUEST.SFMLANG['EmployeeNo']#</strong></td>
										<td rowspan="#tempRowSpan#"><strong>#REQUEST.SFMLANG['EmployeeName']#</strong></td>
										<td rowspan="#tempRowSpan#"><strong>#REQUEST.SFMLANG['JoinDate']#</strong></td>
										<td rowspan="#tempRowSpan#"><strong>#REQUEST.SFMLANG['Position']#</strong></td>
										<td rowspan="#tempRowSpan#"><strong>#REQUEST.SFMLANG['OrganizationUnit']#</strong></td>
										<td rowspan="#tempRowSpan#"><strong>#REQUEST.SFMLANG['Grade']#</strong></td>
										<td rowspan="#tempRowSpan#"><strong>#REQUEST.SFMLANG['EmploymentStatus']#</strong></td>
										
										<cfif listFindNoCase(disp, 3) neq 0> <!---format tab menampilkan achievement--->
    										<td rowspan="#tempRowSpan#"><strong>#REQUEST.SFMLANG['ObjectiveType']#</strong></td>
    										<td rowspan="#tempRowSpan#"><strong>#REQUEST.SFMLANG['Objective']#</strong></td>
    										<cfif listFindNoCase(disp, 1) neq 0><td rowspan="#tempRowSpan#"><strong>#REQUEST.SFMLANG['Target']#</strong></td></cfif>
    										<cfif listFindNoCase(disp, 2) neq 0><td rowspan="#tempRowSpan#"><strong>#REQUEST.SFMLANG['Weight']#</strong></td></cfif>
    										<td  <cfif inp_showverified neq "Y">colspan="#val(ListLen(listMthMonitoring,"~")*2)#"<cfelse>colspan="#ListLen(listMthMonitoring,"~")#"</cfif> align="center"><strong>#REQUEST.SFMLANG['FDAchievement']#</strong></td>
										<cfelse> <!---tanpa menampilkan achievement--->
        									<cfif listFindNoCase(kpicheck, 1) neq 0 and listfindnocase(lstPerComp,"PERSKPI")>
        										<td colspan="#totPOspan#" align="center"><strong>#REQUEST.SFMLANG['PersonalObjective']#</strong></td>
        									</cfif>
        									<cfif listFindNoCase(kpicheck, 2) neq 0 and listfindnocase(lstPerComp,"ORGKPI")>
        										<td colspan="#totORspan#" align="center"><strong>#REQUEST.SFMLANG['OrganizationUnitObjective']#</strong></td>
        									</cfif>
										</cfif>
									</tr>
									<cfif listFindNoCase(disp, 3) neq 0>
										<cfif listMthMonitoring neq "">
											<tr>
												<cfset local.tempCtr = 0>
												<cfset local.idxloop = "">
												<cfloop list="#listMthMonitoring#" index="idxloop" delimiters="~">
													<td nowrap="nowrap"  <cfif inp_showverified neq "Y">colspan="2"</cfif>>
														<cfset tempCtr = tempCtr + 1>
														<cfif typeMonitoring neq "">
															<strong>#Left(typeMonitoring,1)##tempCtr##DateFormat(idxloop,"yyyy")# (#DateFormat(idxloop,"mmm")# #DateFormat(idxloop,"yyyy")#)</strong>
														<cfelse>
															<strong>#DateFormat(idxloop,"mmm")# #DateFormat(idxloop,"yyyy")#</strong>
														</cfif>
													</td>
												</cfloop>
											</tr>
											<cfif inp_showverified neq "Y">
											    <tr>
												<cfset local.tempCtr = 0>
												<cfset local.idxloop = "">
												<cfloop list="#listMthMonitoring#" index="idxloop" delimiters="~">
													<td nowrap="nowrap">
													    Achievement
													</td>
													<td nowrap="nowrap">
													    Verified
													</td>
												</cfloop>
											</tr>
											</cfif>
										<cfelse>
									
										</cfif>
										
										
									<cfelse> <!---Tanpa tab achievement--->
        								<tr>
        									<cfif listFindNoCase(kpicheck, 1) neq 0 and listfindnocase(lstPerComp,"PERSKPI")>
        										<cfif qPOname.recordcount neq 0>
        											<cfloop query="qPOname">
        												<td colspan="#totdisp#" align="center">
        												    <cfif len(libname) lte 150>
            												    #htmleditformat(libname)#
            												<cfelse>
            												    <cfset local.xv = 1>
        														<cfset local.idx = "">
            												    <cfloop from="1" to="#len(libname)/150#" index="idx">
            													    #HTMLEDITFORMAT(evaluate("MID(libname,#xv#,150)"))#<br/>
            														<cfset xv = xv + 150>
            													</cfloop>
            												</cfif>
        												</td>
        											</cfloop>
        										<cfelse>
        											<td align="center"> - </td>
        										</cfif>
        									</cfif>
        									<cfif listFindNoCase(kpicheck, 2) neq 0 and listfindnocase(lstPerComp,"ORGKPI")>
        										<cfif qORname.recordcount neq 0>
        											<cfloop query="qORname">
        												<td colspan="#totdisp#"  align="center">
        												    <cfif len(libname) lte 150>
            												    #htmleditformat(libname)#
            												<cfelse>
            												    <cfset local.xv = 1>
        														
        														<cfset local.idx = "">
            												    <cfloop from="1" to="#len(libname)/150#" index="idx">
            													    #HTMLEDITFORMAT(evaluate("MID(libname,#xv#,150)"))#<br/>
            														<cfset xv = xv + 150>
            													</cfloop>
            												</cfif>
        												</td>
        											</cfloop>
        										<cfelse>
        											<td align="center"> - </td>
        										</cfif>
        									</cfif>
        								</tr>
        								<tr>
        									<cfif listFindNoCase(kpicheck, 1) neq 0 and listfindnocase(lstPerComp,"PERSKPI")>
        										<cfif qPOname.recordcount neq 0>
        											<cfloop query="qPOname">
        												<cfif listFindNoCase(disp, 1) neq 0>
        													<td>#REQUEST.SFMLANG['Target']#</td>
        												</cfif>
        												<cfif listFindNoCase(disp, 2) neq 0>
        													<td>#REQUEST.SFMLANG['Weight']#</td>
        												</cfif>
        											</cfloop>
        										<cfelse>
        											<td align="center"> - </td>
        										</cfif>
        									</cfif>
        									<cfif listFindNoCase(kpicheck, 2) neq 0 and listfindnocase(lstPerComp,"ORGKPI")>
        										<cfif qORname.recordcount neq 0>
        											<cfloop query="qORname">
        												<cfif listFindNoCase(disp, 1) neq 0>
        												   <td>#REQUEST.SFMLANG['Target']#</td>
        												</cfif>
        												<cfif listFindNoCase(disp, 2) neq 0>
        												   <td>#REQUEST.SFMLANG['Weight']#</td>
        												</cfif>
        											</cfloop>
        										<cfelse>
        											<td align="center"> - </td>
        										</cfif>
        									</cfif>
        								</tr>
									</cfif>
								
								
							
							
									<cfquery name="local.qValueAll" datasource="#REQUEST.SDSN#">
									
									
									
										
										<cfif request.scookie.cocode eq "issid">	
											SET STATEMENT max_statement_time=2500 FOR 
										</cfif>
										select TPMDPERFORMANCE_PLAND.target, TPMDPERFORMANCE_PLAND.weight, TPMDPERFORMANCE_MIDD.monitoring_achievement,
										TPMDPERFORMANCE_PLAND.form_no,TPMDPERFORMANCE_PLANH.reviewee_empid,TPMDPERFORMANCE_PLAND.lib_code,monitoring_date,MONTH(monitoring_date) mthMonDate,YEAR(monitoring_date) yearMonDate,
										TPMDPERFORMANCE_MIDD.lib_type
										from TPMDPERFORMANCE_PLAND 
										left join TPMDPERFORMANCE_PLANH on TPMDPERFORMANCE_PLANH.form_no=TPMDPERFORMANCE_PLAND.form_no
										left join TPMDPERFORMANCE_MIDD on (TPMDPERFORMANCE_PLAND.form_no=TPMDPERFORMANCE_MIDD.form_no
										AND TPMDPERFORMANCE_PLAND.lib_code = TPMDPERFORMANCE_MIDD.lib_code  
										AND TPMDPERFORMANCE_PLAND.company_code = TPMDPERFORMANCE_MIDD.company_code) 
										where TPMDPERFORMANCE_PLANH.period_code = <cfqueryparam value="#idxperiodcode#" cfsqltype="cf_sql_varchar">
										AND TPMDPERFORMANCE_PLAND.iscategory <> 'Y'
										GROUP BY TPMDPERFORMANCE_PLAND.target, TPMDPERFORMANCE_PLAND.weight, TPMDPERFORMANCE_MIDD.monitoring_achievement,
										TPMDPERFORMANCE_PLAND.form_no,TPMDPERFORMANCE_PLANH.reviewee_empid,TPMDPERFORMANCE_PLAND.lib_code,monitoring_date,monitoring_date,monitoring_date,
										TPMDPERFORMANCE_MIDD.lib_type
					
									</cfquery>
									<!----<cfif request.scookie.cocode eq "issid" and qEmpReview.form_no eq "PEF-2007-0031">
										<cf_sfwritelog dump="qValueAll,idxperiodcode,qEmpReview" ext="html" prefix="Nonotes#qEmpReview.form_no#_">
									</cfif>  ----->
									
									
									<cfquery name="local.qValueAllOrgKPI" datasource="#REQUEST.SDSN#">
											select TPMDPERFORMANCE_PLANKPI.orgunit_id,TPMDPERFORMANCE_PLANKPI.target, TPMDPERFORMANCE_PLANKPI.weight, TPMDPERFORMANCE_MIDD.monitoring_achievement,MONTH(monitoring_date) mthMonDate,YEAR(monitoring_date) yearMonDate,
											TPMDPERFORMANCE_MIDD.form_no,TPMDPERFORMANCE_PLANH.reviewee_empid,TPMDPERFORMANCE_PLANKPI.lib_code,monitoring_date,
											TPMDPERFORMANCE_MIDD.lib_type
											from TPMDPERFORMANCE_PLANKPI
											left join TPMDPERFORMANCE_PLANH on TPMDPERFORMANCE_PLANH.form_no=TPMDPERFORMANCE_PLANKPI.form_no 
											left join TPMDPERFORMANCE_MIDD on (TPMDPERFORMANCE_PLANKPI.lib_code = TPMDPERFORMANCE_MIDD.lib_code  
											AND TPMDPERFORMANCE_PLANKPI.company_code = TPMDPERFORMANCE_MIDD.company_code) 
											where TPMDPERFORMANCE_PLANH.period_code = <cfqueryparam value="#idxperiodcode#" cfsqltype="cf_sql_varchar">
											AND TPMDPERFORMANCE_PLANKPI.iscategory <> 'Y'
											GROUP BY TPMDPERFORMANCE_PLANKPI.orgunit_id,TPMDPERFORMANCE_PLANKPI.target, TPMDPERFORMANCE_PLANKPI.weight, TPMDPERFORMANCE_MIDD.monitoring_achievement,monitoring_date,monitoring_date,
											TPMDPERFORMANCE_MIDD.form_no,TPMDPERFORMANCE_PLANH.reviewee_empid,TPMDPERFORMANCE_PLANKPI.lib_code,monitoring_date,
											TPMDPERFORMANCE_MIDD.lib_type
									</cfquery>
									

								<cfif listFindNoCase(disp, 3) neq 0>
									
									<cfif ListLen(kpicheck) gt 0>
											<cfset local.idxloop = "">
											<cfloop from="1" to="#ListLen(kpicheck)#" index="idxLoop">
												<cfif idxLoop eq 1> <!---- tampil KPI personal ---->
													
													<cfloop query="qEmpReview">
														
														<tr>
															<td rowspan="#qPOname.recordcount NEQ 0 ? qPOname.recordcount : 1#">#emp_no#</td> <!--- TCK0918-196891 | qPOname.recordcount --->
															<td rowspan="#qPOname.recordcount NEQ 0 ? qPOname.recordcount : 1#">#HTMLEDITFORMAT(full_name)#</td>
															<td rowspan="#qPOname.recordcount NEQ 0 ? qPOname.recordcount : 1#">#dateFormat(joindate,application.config.date_output_format)#</td>
															<td rowspan="#qPOname.recordcount NEQ 0 ? qPOname.recordcount : 1#">#HTMLEDITFORMAT(pos)#</td>
															<cfquery name="local.qORUNIT" datasource="#REQUEST.SDSN#">
																select pos_name_#request.scookie.lang# as orunit from TEOMPOSITION where position_id = '#qEmpReview.DEPT_ID#'
															</cfquery>
															<td rowspan="#qPOname.recordcount NEQ 0 ? qPOname.recordcount : 1#">#HTMLEDITFORMAT(qORUNIT.orunit)#</td>
															<cfquery name="local.qGetGradeAndEmpStatus" datasource="#request.sdsn#">
																SELECT ES.employmentstatus_name_#request.scookie.lang# AS empstatus, GRD.grade_name AS empgrade
																FROM TEODEMPCOMPANY EC 
																INNER JOIN TEOMJOBGRADE GRD 
																ON (GRD.grade_code = EC.grade_code AND  GRD.company_id  = EC.company_id)
																INNER JOIN TEOMEMPLOYMENTSTATUS ES ON ES.employmentstatus_code = EC.employ_code
																WHERE EC.emp_no =  <cfqueryparam value="#emp_no#" cfsqltype="cf_sql_varchar">
																AND EC.company_id =  <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer">
															</cfquery>
															<cfif Len(trim(qEmpReview.empgrade)) eq 0>
																<cfset local.varempgrade = qGetGradeAndEmpStatus.empgrade>
															<cfelse>
																<cfset local.varempgrade = qEmpReview.empgrade>
															</cfif>
															<cfif Len(trim(qEmpReview.empstatus)) eq 0>
																<cfset local.varempstatus = qGetGradeAndEmpStatus.empstatus>
															<cfelse>
																<cfset local.varempstatus = qEmpReview.empstatus>
															</cfif>
															
															
															<td rowspan="#qPOname.recordcount NEQ 0 ? qPOname.recordcount : 1#">#HTMLEDITFORMAT(varempgrade)#</td>
															<td rowspan="#qPOname.recordcount NEQ 0 ? qPOname.recordcount : 1#">#HTMLEDITFORMAT(varempstatus)#</td>
															
															<!---<cfquery name="local.qTargetWeight1" dbtype="query">
																select DISTINCT <cfif listFindNoCase(disp, 1) neq 0>target,</cfif>weight
																from qValueAll
																where form_no = '#qEmpReview.form_no#'
																and reviewee_empid= '#qEmpReview.reviewee_empid#'
																and lib_code= '#qPOname.lib_code[1]#'
																and lib_type = 'PERSKPI'
																
															</cfquery> --->
															
															<cfquery name="LOCAL.qTargetWeight1" datasource="#REQUEST.SDSN#">
																<cfif request.scookie.cocode eq "issid">	
																	SET STATEMENT max_statement_time=2500 FOR 
																</cfif>
																SELECT
																	<cfif listFindNoCase(disp, 1) neq 0>TPMDPERFORMANCE_PLAND.target,</cfif>
																		TPMDPERFORMANCE_PLAND.weight
																		FROM TPMDPERFORMANCE_PLANH
																		INNER JOIN TPMDPERFORMANCE_PLAND
																		ON TPMDPERFORMANCE_PLAND.form_no = TPMDPERFORMANCE_PLANH.form_no
																		AND TPMDPERFORMANCE_PLAND.reviewer_empid = TPMDPERFORMANCE_PLANH.reviewer_empid
																		and lib_type = 'PERSKPI'
																		WHERE TPMDPERFORMANCE_PLANH.form_no = <cfqueryparam value="#qEmpReview.form_no#" cfsqltype="cf_sql_varchar">
																		 AND lib_code= '#qPOname.lib_code[1]#'
																		AND TPMDPERFORMANCE_PLANH.isfinal = 1
																		AND TPMDPERFORMANCE_PLANH.isfinal_requestno = 1
															</cfquery>
														
															<td rowspan="#qPOname.recordcount NEQ 0 ? qPOname.recordcount : 1#">#REQUEST.SFMLANG['PersonalObjective']#</td>
															<td>
															
															    <cfif len(qPoName.libname[1]) lte 150>
																    #HTMLEDITFORMAT(qPoName.libname[1])#
																<cfelse>
																    <cfset local.xv = 1>
																	<cfset local.idx = "">
																    <cfloop from="1" to="#len(qPoName.libname[1])/150#" index="idx">
																        #HTMLEDITFORMAT(evaluate("MID(qPoName.libname[1],#xv#,150)"))#<br/>
																        <cfset xv = xv + 150>
																    </cfloop>
																</cfif>
															</td>
															
															<cfif listFindNoCase(disp, 1) neq 0><td align="right"><cfif qTargetWeight1.target neq "">#HTMLEDITFORMAT(qTargetWeight1.target)#<cfelse>-</cfif></td></cfif>
															<cfif listFindNoCase(disp, 2) neq 0><td align="right"><cfif qTargetWeight1.weight neq "">#APPLICATION.SFUTIL.SFNUM(qTargetWeight1.weight,'int')#<cfelse>-</cfif></td></cfif>
															<cfif listFindNoCase(disp, 3) neq 0>
																<cfset local.loopMon = "">
																<cfloop list="#listMthMonitoring#" index="loopMon" delimiters="~">
																
																<cfquery name="LOCAL.qValue1" datasource="#REQUEST.SDSN#">
																		<cfif request.scookie.cocode eq "issid">	
																		SET STATEMENT max_statement_time=2500 FOR 
																		</cfif>
																		SELECT monitoring_achievement
																		FROM TPMDPERFORMANCE_MIDD
																		WHERE form_no = '#qEmpReview.form_no#'
																		and lib_code= '#qPOname.lib_code[1]#' 
																		and month(monitoring_date) =  <cfqueryparam value="#DateFormat(loopMon,"mm")#" cfsqltype="cf_sql_integer">
																		and year(monitoring_date) = <cfqueryparam value="#DateFormat(loopMon,"yyyy")#" cfsqltype="cf_sql_integer">
																		and lib_type = 'PERSKPI' 
																</cfquery>
																	
															
																	<cfquery name="local.qMidV" datasource="#request.sdsn#">
    																	select is_verified
    																	from TPMDPERFORMANCE_MIDV
    																	where form_no = '#qEmpReview.form_no#'
																		and month(monitoring_date) =  <cfqueryparam value="#DateFormat(loopMon,"mm")#" cfsqltype="cf_sql_integer">
																		and year(monitoring_date) = <cfqueryparam value="#DateFormat(loopMon,"yyyy")#" cfsqltype="cf_sql_integer">
																		and lib_type = 'PERSKPI'
																		<cfif inp_showverified eq "Y">and is_verified ='Y'
																		</cfif>
																	</cfquery>
																	<!---end NF--->
																	<td align="right">
																		<cfif inp_showverified eq "Y">
																			<cfif qMidV.is_verified eq "Y">
																				<cfif qValue1.monitoring_achievement neq "">
																					#qValue1.monitoring_achievement#  
																				<cfelse>
																				  - 
																				</cfif>
																			<cfelse>
																				-
																			</cfif>
																			
																		<cfelse>
																			<cfif qValue1.monitoring_achievement neq "">
																				#qValue1.monitoring_achievement#   
																			<cfelse>
																			  - 
																			</cfif>
																		</cfif>
															          </td>
															          <cfif inp_showverified neq "Y">
															              <td align="center">
															                <cfif local.qMidV.is_Verified eq "Y">
															                        #REQUEST.SFMLANG['Yes']#
															                <cfelseif qValue1.monitoring_achievement neq "">
															                         #REQUEST.SFMLANG['FDNo']#
															                <cfelse>
															                        -
															                </cfif>
															              </td>
															          </cfif>
																</cfloop>
															</cfif>
														</tr>
														
													<cfif qPOname.recordcount gte 2>
														<cfset local.objLoop = "">
														<cfloop from="2" to="#qPOname.recordcount#" index="objLoop">
														<tr>
																
																<cfquery name="LOCAL.qTargetWeight2" datasource="#REQUEST.SDSN#">
																	<cfif request.scookie.cocode eq "issid">	
																		SET STATEMENT max_statement_time=2500 FOR 
																	</cfif>
																	SELECT
																		<cfif listFindNoCase(disp, 1) neq 0>TPMDPERFORMANCE_PLAND.target,</cfif>
																			TPMDPERFORMANCE_PLAND.weight
																			FROM TPMDPERFORMANCE_PLANH
																			INNER JOIN TPMDPERFORMANCE_PLAND
																			ON TPMDPERFORMANCE_PLAND.form_no = TPMDPERFORMANCE_PLANH.form_no
																			AND TPMDPERFORMANCE_PLAND.reviewer_empid = TPMDPERFORMANCE_PLANH.reviewer_empid
																			and lib_type = 'PERSKPI'
																			WHERE TPMDPERFORMANCE_PLANH.form_no = <cfqueryparam value="#qEmpReview.form_no#" cfsqltype="cf_sql_varchar">
																			 AND lib_code= '#qPOname.lib_code[objLoop]#'
																			AND TPMDPERFORMANCE_PLANH.isfinal = 1
																			AND TPMDPERFORMANCE_PLANH.isfinal_requestno = 1
																</cfquery>
																
																<td>
																    <cfif len(qPOname.libname[objLoop]) lte 150>
																        #HTMLEDITFORMAT(qPOname.libname[objLoop])#
																    <cfelse>
																        <cfset local.xv = 1>
																		<cfset local.idx = "">
																        <cfloop from="1" to="#len(qPOname.libname[objLoop])/150#" index="idx">
																            #HTMLEDITFORMAT(evaluate("MID(qPOname.libname[objLoop],#xv#,150)"))#<br/>
																            <cfset xv = xv + 150>
																        </cfloop>
																    </cfif>
																</td>
																
																<cfif listFindNoCase(disp, 1) neq 0><td align="right"><cfif qTargetWeight2.target neq "">#HTMLEDITFORMAT(qTargetWeight2.target)#<cfelse>-</cfif></td></cfif>
																<cfif listFindNoCase(disp, 2) neq 0><td align="right"><cfif qTargetWeight2.weight neq "">#APPLICATION.SFUTIL.SFNUM(qTargetWeight2.weight,'int')#<cfelse>-</cfif></td></cfif>
																<cfif listFindNoCase(disp, 3) neq 0>
																	<cfset local.loopMon = "">
																	<cfloop list="#listMthMonitoring#" index="loopMon" delimiters="~">
																	
																		<cfquery name="LOCAL.qValue2" datasource="#REQUEST.SDSN#">
																			<cfif request.scookie.cocode eq "issid">	
																			SET STATEMENT max_statement_time=2500 FOR 
																			</cfif>
																			SELECT monitoring_achievement
																			FROM TPMDPERFORMANCE_MIDD
																			WHERE form_no = '#qEmpReview.form_no#'
																			and lib_code= '#qPOname.lib_code[objLoop]#' 
																			and month(monitoring_date) =  <cfqueryparam value="#DateFormat(loopMon,"mm")#" cfsqltype="cf_sql_integer">
																			and year(monitoring_date) = <cfqueryparam value="#DateFormat(loopMon,"yyyy")#" cfsqltype="cf_sql_integer">
																			and lib_type = 'PERSKPI' 
																		</cfquery>
																		
																		
																		
																		
																		<!---add by NF--->
    																	<cfquery name="local.qMidV2" datasource="#request.sdsn#">
        																	select is_verified
        																	from TPMDPERFORMANCE_MIDV
        																	where form_no = '#qEmpReview.form_no#'
    																		and month(monitoring_date) =  <cfqueryparam value="#DateFormat(loopMon,"mm")#" cfsqltype="cf_sql_integer">
    																		and year(monitoring_date) = <cfqueryparam value="#DateFormat(loopMon,"yyyy")#" cfsqltype="cf_sql_integer">
    																		and lib_type = 'PERSKPI'
    																		<cfif inp_showverified eq "Y">and is_verified ='Y'
    																		</cfif>
    																	</cfquery>
    																	<!---end NF--->
																	<td align="right">
																	
																	
																		<cfif inp_showverified eq "Y">
																			<cfif qMidV2.is_verified eq "Y">
																				<cfif qValue2.monitoring_achievement neq "">
																					#qValue2.monitoring_achievement#  
																				<cfelse>
																				  - 
																				</cfif>
																			<cfelse>
																				-
																			</cfif>
																			
																		<cfelse>
																			<cfif qValue2.monitoring_achievement neq "">
																				#qValue2.monitoring_achievement#   
																			<cfelse>
																			  - 
																			</cfif>
																		</cfif>
															          </td>
															          <cfif inp_showverified neq "Y">
															              <td align="center">
															                <cfif local.qMidV2.is_Verified eq "Y">
															                         #REQUEST.SFMLANG['Yes']#
															                <cfelseif qValue2.monitoring_achievement neq "">
															                         #REQUEST.SFMLANG['FDNo']#
															                <cfelse>
															                        -
															                </cfif>
															              </td>
															          </cfif>
																	</cfloop>
																</cfif>
																
														</tr>
														</cfloop>
													
													</cfif>
												</cfloop>
													
												<cfelseif idxLoop eq 2>
													
												<cfloop query="qEmpReview">
														
														<cfif listfindnocase(lstPerComp,"ORGKPI") gt 0 >
														
														<tr>
															<td rowspan="#qORname.recordcount NEQ 0 ? qORname.recordcount : 1#">#emp_no#</td>
															
															<td rowspan="#qORname.recordcount NEQ 0 ? qORname.recordcount : 1#">#HTMLEDITFORMAT(full_name)#</td>
															<td rowspan="#qORname.recordcount NEQ 0 ? qORname.recordcount : 1#">#dateFormat(joindate,application.config.date_output_format)#</td>
															<td rowspan="#qORname.recordcount NEQ 0 ? qORname.recordcount : 1#">#HTMLEDITFORMAT(pos)#</td>
															<cfquery name="local.qORUNIT" datasource="#REQUEST.SDSN#">
																select pos_name_#request.scookie.lang# as orunit from TEOMPOSITION 
																where position_id =  <cfqueryparam value="#qEmpReview.DEPT_ID#" cfsqltype="cf_sql_integer">
																and company_id =  <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer">
															</cfquery>
															<td rowspan="#qORname.recordcount NEQ 0 ? qORname.recordcount : 1#">#HTMLEDITFORMAT(qORUNIT.orunit)#</td>
															<cfquery name="local.qGetGradeAndEmpStatus" datasource="#request.sdsn#">
																SELECT ES.employmentstatus_name_#request.scookie.lang# AS empstatus, GRD.grade_name AS empgrade
																FROM TEODEMPCOMPANY EC 
																INNER JOIN TEOMJOBGRADE GRD 
																ON (GRD.grade_code = EC.grade_code AND  GRD.company_id  = EC.company_id)
																INNER JOIN TEOMEMPLOYMENTSTATUS ES ON ES.employmentstatus_code = EC.employ_code
																WHERE EC.emp_no =  <cfqueryparam value="#emp_no#" cfsqltype="cf_sql_varchar">
																AND EC.company_id =  <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer">
															</cfquery>
															<cfif Len(trim(qEmpReview.empgrade)) eq 0>
																<cfset local.varempgrade = qGetGradeAndEmpStatus.empgrade>
															<cfelse>
																<cfset local.varempgrade = qEmpReview.empgrade>
															</cfif>
															<cfif Len(trim(qEmpReview.empstatus)) eq 0>
																<cfset local.varempstatus = qGetGradeAndEmpStatus.empstatus>
															<cfelse>
																<cfset local.varempstatus = qEmpReview.empstatus>
															</cfif>
															<td rowspan="#qORname.recordcount NEQ 0 ? qORname.recordcount : 1#">#HTMLEDITFORMAT(varempgrade)#</td>
															<td rowspan="#qORname.recordcount NEQ 0 ? qORname.recordcount : 1#">#HTMLEDITFORMAT(varempstatus)#</td>
															<cfquery name="local.qTargetWeight1" dbtype="query">
																select DISTINCT <cfif listFindNoCase(disp, 1) neq 0>target,</cfif>weight
																from qValueAllOrgKPI
																where orgunit_id = <cfqueryparam value="#qEmpReview.dept_id#" cfsqltype="cf_sql_integer">
																and lib_code= '#qORname.lib_code[1]#' 
																and lib_type = 'ORGKPI'
																and form_no = '#qEmpReview.form_no#'
																and reviewee_empid= '#qEmpReview.reviewee_empid#'
															</cfquery>
															
															<td rowspan="#qORname.recordcount NEQ 0 ? qORname.recordcount : 1#">#REQUEST.SFMLANG['OrganizationUnitObjective']#</td>
															<td>
															    <cfif len(qORname.libname[1]) lte 150>
																    #HTMLEDITFORMAT(qORname.libname[1])#
																<cfelse>
																    <cfset local.xv = 1>
																	<cfset local.idx = "">
																    <cfloop from="1" to="#len(qORname.libname[1])/150#" index="idx">
																        #HTMLEDITFORMAT(evaluate("MID(qORname.libname[1],#xv#,150)"))#<br/>
																        <cfset xv = xv + 150>
																    </cfloop>
																</cfif>
															</td>
															
															<cfif listFindNoCase(disp, 1) neq 0><td align="right"><cfif qTargetWeight1.target neq "">#HTMLEDITFORMAT(qTargetWeight1.target)#<cfelse>-</cfif></td></cfif>
															<cfif listFindNoCase(disp, 2) neq 0><td align="right"><cfif qTargetWeight1.weight neq "">#APPLICATION.SFUTIL.SFNUM(qTargetWeight1.weight,'int')#<cfelse>-</cfif>
															</td></cfif>
															<cfif listFindNoCase(disp, 3) neq 0>
																<cfset local.loopMon = "">
																<cfloop list="#listMthMonitoring#" index="loopMon" delimiters="~">
																	<cfquery name="local.qValue1" dbtype="query">
																	select monitoring_achievement
																	from qValueAllOrgKPI
																	where orgunit_id = <cfqueryparam value="#qEmpReview.dept_id#" cfsqltype="cf_sql_integer">
																		and lib_code= '#qORname.lib_code[1]#' 
																		and mthMonDate = <cfqueryparam value="#DateFormat(loopMon,"mm")#" cfsqltype="cf_sql_integer">
																		and yearMonDate = <cfqueryparam value="#DateFormat(loopMon,"yyyy")#" cfsqltype="cf_sql_integer">
																		and lib_type = 'ORGKPI'
																		and form_no = '#qEmpReview.form_no#'
																		and reviewee_empid= '#qEmpReview.reviewee_empid#'
																	</cfquery>
																	<!---add by NF--->
																	<cfquery name="local.qMidV" datasource="#request.sdsn#">
    																	select is_verified
    																	from TPMDPERFORMANCE_MIDV
    																	where form_no = '#qEmpReview.form_no#'
																		and month(monitoring_date) =  <cfqueryparam value="#DateFormat(loopMon,"mm")#" cfsqltype="cf_sql_integer">
																		and year(monitoring_date) = <cfqueryparam value="#DateFormat(loopMon,"yyyy")#" cfsqltype="cf_sql_integer">
																		and UPPER(lib_type) = 'ORGKPI'
																		<cfif inp_showverified eq "Y">and is_verified ='Y'</cfif>
																	</cfquery>
																	<!---end NF--->
																	<td align="right">
																	<cfif qValue1.monitoring_achievement neq "">
														                #qValue1.monitoring_achievement#
														            <cfelse>
														              -
														            </cfif>
														          </td>
														          <cfif inp_showverified neq "Y">
														              <td align="center">
														                <cfif local.qMidV.is_Verified eq "Y">
														                        #REQUEST.SFMLANG['Yes']#
														                <cfelseif qValue1.monitoring_achievement neq "">
														                        #REQUEST.SFMLANG['FDNo']#
														                <cfelse>
														                        -
														                </cfif>
														              </td>
														          </cfif>
																</cfloop>
															</cfif>
														</tr>
														
														
														
														
													<cfif qORname.recordcount gte 2>
														<cfset local.objLoop = "">
														<cfloop from="2" to="#qORname.recordcount#" index="objLoop">
														<tr>
																
																<cfquery name="local.qTargetWeight2" dbtype="query">
																	select DISTINCT <cfif listFindNoCase(disp, 1) neq 0>target,</cfif>weight
																	from qValueAllOrgKPI
																	where orgunit_id = <cfqueryparam value="#qEmpReview.dept_id#" cfsqltype="cf_sql_integer">
																	and lib_code= '#qORname.lib_code[objLoop]#' 
																	and lib_type = 'ORGKPI'
																	and form_no = '#qEmpReview.form_no#'
																	and reviewee_empid= '#qEmpReview.reviewee_empid#'
																</cfquery>
																
																<td>
																    <cfif len(qORname.libname[1]) lte 150>
    																    #HTMLEDITFORMAT(qORname.libname[objLoop])#
    																<cfelse>
    																    <cfset local.xv = 1>
																		<cfset local.idx = "">
    																    <cfloop from="1" to="#len(qORname.libname[objLoop])/150#" index="idx">
    																        #HTMLEDITFORMAT(evaluate("MID(qORname.libname[objLoop],#xv#,150)"))#<br/>
    																        <cfset xv = xv + 150>
    																    </cfloop>
    																</cfif>
																</td>
																
																
																<cfif listFindNoCase(disp, 1) neq 0><td align="right"><cfif qTargetWeight2.target neq "">#HTMLEDITFORMAT(qTargetWeight2.target)#<cfelse>-</cfif></td></cfif>
																<cfif listFindNoCase(disp, 2) neq 0><td align="right"><cfif qTargetWeight2.weight neq "">#APPLICATION.SFUTIL.SFNUM(qTargetWeight2.weight,'int')#<cfelse>-</cfif></td></cfif>
																<cfif listFindNoCase(disp, 3) neq 0>
																	<cfset local.loopMon = "">
																	<cfloop list="#listMthMonitoring#" index="loopMon" delimiters="~">
																		<cfquery name="local.qValue2" dbtype="query">
																		select monitoring_achievement
																		from qValueAllOrgKPI
																		where orgunit_id = <cfqueryparam value="#qEmpReview.dept_id#" cfsqltype="cf_sql_integer">
																			and lib_code= '#qORname.lib_code[objLoop]#' 
																			and mthMonDate = <cfqueryparam value="#DateFormat(loopMon,"mm")#" cfsqltype="cf_sql_integer">
																			and yearMonDate = <cfqueryparam value="#DateFormat(loopMon,"yyyy")#" cfsqltype="cf_sql_integer">
																			and lib_type = 'ORGKPI'
																			and form_no = '#qEmpReview.form_no#'
																			and reviewee_empid= '#qEmpReview.reviewee_empid#'
																		</cfquery>
																		<!---add by NF--->
        																<cfquery name="local.qMidV2" datasource="#request.sdsn#">
        																	select is_verified
        																	from TPMDPERFORMANCE_MIDV
        																	where form_no = '#qEmpReview.form_no#'
        																	and month(monitoring_date) =  <cfqueryparam value="#DateFormat(loopMon,"mm")#" cfsqltype="cf_sql_integer">
        																	and year(monitoring_date) = <cfqueryparam value="#DateFormat(loopMon,"yyyy")#" cfsqltype="cf_sql_integer">
        																	and lib_type = 'ORGKPI'
        																	<cfif inp_showverified eq "Y">and is_verified ='Y'
        																	</cfif>
        																</cfquery>
        																<!---end NF--->
																	<td align="right">
																	<cfif qValue2.monitoring_achievement neq "">
														                <cfif local.qMidV2.recordcount>
														                    #qValue2.monitoring_achievement#
														                <cfelse>
														                    -
														                </cfif>
														            <cfelse>
														              -
														            </cfif>
														          </td>
														          <cfif inp_showverified neq "Y">
														              <td align="center">
														                <cfif local.qMidV2.is_Verified eq "Y">
														                        #REQUEST.SFMLANG['Yes']#
														                <cfelseif qValue2.monitoring_achievement neq "">
														                        #REQUEST.SFMLANG['FDNo']#
														                <cfelse>
														                        -
														                </cfif>
														              </td>
														          </cfif>
																	</cfloop>
																</cfif>
														</tr>
													    </cfloop>
													</cfif>
														
														
														</cfif>
														
												</cfloop>	
												
												</cfif>
												
											</cfloop>
									</cfif>

								<cfelse> <!---Tanpa tab achievemnt monitoring--->
									<cfloop query="qEmpReview">
									<tr>
									    <td>#currentrow#</td>
										<td>#emp_no#</td>
										<td>#htmleditformat(full_name)#</td>
										<td>#dateFormat(joindate,application.config.date_output_format)#</td>
										<td>#htmleditformat(pos)#</td>
										<cfquery name="local.qORUNIT" datasource="#REQUEST.SDSN#">
											select pos_name_#request.scookie.lang# as orunit from TEOMPOSITION where position_id = '#qEmpReview.DEPT_ID#'
										</cfquery>
										<td>#htmleditformat(qORUNIT.orunit)#</td>
										<cfquery name="local.qGetGradeAndEmpStatus" datasource="#request.sdsn#">
											SELECT ES.employmentstatus_name_#request.scookie.lang# AS empstatus, GRD.grade_name AS empgrade
											FROM TEODEMPCOMPANY EC 
											INNER JOIN TEOMJOBGRADE GRD 
											ON (GRD.grade_code = EC.grade_code AND  GRD.company_id  = EC.company_id)
											INNER JOIN TEOMEMPLOYMENTSTATUS ES ON ES.employmentstatus_code = EC.employ_code
											WHERE EC.emp_no =  <cfqueryparam value="#emp_no#" cfsqltype="cf_sql_varchar">
											AND EC.company_id =  <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer">
										</cfquery>
										<cfif Len(trim(qEmpReview.empgrade)) eq 0>
											<cfset local.varempgrade = qGetGradeAndEmpStatus.empgrade>
										<cfelse>
											<cfset local.varempgrade = qEmpReview.empgrade>
										</cfif>
										<cfif Len(trim(qEmpReview.empstatus)) eq 0>
											<cfset local.varempstatus = qGetGradeAndEmpStatus.empstatus>
										<cfelse>
											<cfset local.varempstatus = qEmpReview.empstatus>
										</cfif>
										<td>#htmleditformat(varempgrade)#</td>
										<td>#htmleditformat(varempstatus)#</td>
										<cfquery name="local.cekrevieweridform" datasource="#REQUEST.SDSN#">
											SELECT DISTINCT reviewer_empid FROM TPMDPERFORMANCE_PLANH
											WHERE isfinal = 1
											AND form_no =  '#qEmpReview.form_no#'
										</cfquery>
										<cfif inp_viewpoint eq 0>
											 <cfset rvrid = request.scookie.user.empid> 
										<cfelse>
											<cfset rvrid = cekrevieweridform.reviewer_empid>
										</cfif>
										<cfif listFindNoCase(kpicheck, 1) neq 0 and listfindnocase(lstPerComp,"PERSKPI")>
											<cfif qPOname.recordcount neq 0>
												<cfloop query="qPOname">
			
													<cfquery name="local.qTargetWeight1" dbtype="query">
														select DISTINCT <cfif listFindNoCase(disp, 1) neq 0>target,</cfif>weight
														from qValueAll
														where form_no = '#qEmpReview.form_no#'
														and reviewee_empid= '#qEmpReview.reviewee_empid#'
														and lib_code= '#qPOname.lib_code#'
														and lib_type = 'PERSKPI'
													</cfquery>


													<cfif listFindNoCase(disp, 1) neq 0>
														<td align="center">
															<cfif qTargetWeight1.target neq "">
																#HTMLEDITFORMAT(qTargetWeight1.target)# 
															<cfelse> - 
															</cfif>
														</td>
													</cfif>
													<cfif listFindNoCase(disp, 2) neq 0>
														<td align="center">
															<cfif qTargetWeight1.weight neq "">
																#APPLICATION.SFUTIL.SFNUM(qTargetWeight1.weight,'int')#
															<cfelse>
															</cfif> 
														</td>
													</cfif>
												</cfloop>
											<cfelse>
												<td align="center"> - </td>
											</cfif>
										</cfif>

										<cfif listFindNoCase(kpicheck, 2) neq 0 and listfindnocase(lstPerComp,"ORGKPI")>
											<cfif qORname.recordcount neq 0>
												<cfloop query="qORname">

													<cfquery name="local.qTargetWeight2" dbtype="query">
														select DISTINCT <cfif listFindNoCase(disp, 1) neq 0>target,</cfif>weight
														from qValueAllOrgKPI
														where orgunit_id = <cfqueryparam value="#qEmpReview.dept_id#" cfsqltype="cf_sql_integer">
														and lib_code= '#qORname.lib_code#' 
														and lib_type = 'ORGKPI'
														and form_no = '#qEmpReview.form_no#'
														and reviewee_empid= '#qEmpReview.reviewee_empid#'
													</cfquery>

													<cfif listFindNoCase(disp, 1) neq 0>
														<td align="center"> 
															<cfif qTargetWeight2.target neq "">
																#HTMLEDITFORMAT(qTargetWeight2.target)# 
															<cfelse> - 
															</cfif> 
														</td>
													</cfif>
													<cfif listFindNoCase(disp, 2) neq 0>
														<td align="center">
															<cfif qTargetWeight2.weight neq "">
																#APPLICATION.SFUTIL.SFNUM(qTargetWeight2.weight,'int')# 
															<cfelse> - 
															</cfif> 
														</td>
													</cfif>
												</cfloop>
											<cfelse>
												<td align="center"> - </td>
											</cfif>
										</cfif>
									</tr>
									</cfloop>
								</cfif>


								<cfelse>
									<tr>
										<td align="center">----- #REQUEST.SFMLANG['NoRecords']# ----</td>
									<tr>   
								</cfif>
							</tbody>
							</table>
						<!---end : maghdalenasp ENC51015-79814--->
					</cfif>
				</cfoutput>
		</cfloop>
	</cffunction>

</cfcomponent>
