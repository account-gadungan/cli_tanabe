<!--- 
sebelum apply kita bisa lihat dl scriptnya tambahin parameter alter=1
http://192.168.56.112/sf6/index.cfm?sfid=sys.sec.syncdb&alter=1&type=1

kalau udah fix tinggal masukkin alteryes
http://192.168.56.112/sf6/index.cfm?sfid=sys.sec.syncdb&alter=1&type=1&alteryes
--->

<cfsetting showdebugoutput="no">
<!--- <cfparam name="url.source" default="dbsf_enjiniring_secondary_training">
<cfparam name="url.target" default="dbsf_enjiniring_secondary_development">

<cfparam name="url.dbsrctype" default="MariaDB">
<cfparam name="url.dbdsttype" default="MariaDB">

<cfparam name="url.dbsrc" default="dbsf_nbc_enjiniring_training">
<cfparam name="url.dbdst" default="dbdev"> --->

<cfparam name="url.type" default="1">
<cfif url.type eq 1>

	<cfparam name="url.sourcedsn" default="dbsf6_saas">	
	<cfparam name="url.targetdsn" default="dbsf_mtindonesia">	
	<cfparam name="url.dbdsttype" default="MariaDB">	
	<cfparam name="url.dbsrctype" default="MariaDB">	
	<cfparam name="url.dbsrc" default="dbsf6_saas_mtindonesia">	
	<cfparam name="url.dbdst" default="dblive">
	
<cfelseif url.type eq 2>	

	<cfparam name="url.sourcedsn" default="dbsf6_saas">	
	<cfparam name="url.targetdsn" default="dbsf_mtindonesia_secondary_development">	
	<cfparam name="url.dbdsttype" default="MariaDB">	
	<cfparam name="url.dbsrctype" default="MariaDB">	
	<cfparam name="url.dbsrc" default="dbsf6_saas_mtindonesia">	
	<cfparam name="url.dbdst" default="dbdev">

</cfif>

<cfoutput>
	
url.sourcedsn = #url.sourcedsn# <br />
url.targetdsn = #url.targetdsn# <br />
url.dbdsttype = #url.dbdsttype# <br />
url.dbsrctype = #url.dbsrctype# <br />
url.dbsrc = #url.dbsrc# <br />
url.dbdst = #url.dbdst# <br />

<!--- target --->

<cfset TargetDSN= "#url.targetdsn#">
<!--- sources --->
<Cfset SourceDSN = "#url.sourcedsn#"> 

<cfset OraDataType = "DATE,VARCHAR2,NUMBER,CHAR,FLOAT,LONG,REAL,DECIMAL,REAL,CLOB,CLOB,NUMBER,NCHAR,SMALLINT">
<cfset SQLDataType = "DATETIME,VARCHAR,INT,CHAR,FLOAT,INT,MONEY,DECIMAL,REAL,TEXT,NTEXT,NUMERIC,CHAR,SMALLINT">
<cfset NonAtribut = "DATE,DATETIME,INT,LONG,REAL,FLOAT,MONEY,DECIMAL,NUMBER,CLOB,TEXT,NTEXT">

<cfflush interval=200>

<cfif UCase(url.dbsrctype) eq "ORACLE">
	<cfquery name="qTable1" datasource="#SourceDSN#">
		select table_name from user_tables
		where
		table_name not in (
			'THRMPOSITION2','ATTENDANCETEMP_xx','BOARD','BOARD_MAIN',
			'PERFORM_DETAIL','PERFORM_MASTER','PERFORM_PRIVILAGES','PERFORM_QUERY','PERFORM_USER'
		)
		and table_name not like '%_TEMP'
		and table_name not like '%_BACKUP'
		and table_name not like '%_ORIG'
		and table_name not like 'BIN%'		
		ORDER BY table_name
	</cfquery>
<cfelse><!--- if UCase(url.dbsrctype) eq "MSSQLSERVER" --->
	<cfquery name="qTable1" datasource="#SourceDSN#">
		SELECT * FROM Information_Schema.TABLES 
		where table_type = 'BASE TABLE' 
		and table_schema = '#url.dbsrc#'
		<!--- and table_name = 'bakup_config_21042020' --->
		and
		(
		table_name not like '%_2017%'
		or table_name not like '%_2018%'
		or table_name not like '%_dum%'
		or table_name not like '%_bck%'
		or table_name not like '%_bak%'
		or table_name not like '%_backup%'
		)

		<!---
		and table_name in (
		'TCLLAUTHSQL',
		'TCLLMOBILEHISTORY',
		'TCLLUSERSESSION',
		'TCLMUSER',
		'TCLRDATAACCESS',
		'TCLTAUTHREQUEST',
		'TCLTUSERSHARING',
		'TEODCOMPANYREG',
		'TSFCAPP',
		'TSFCMOBILESETTING',
		'TSFDAPP',
		'TSFLHOSTRESPOND',
		'TSFLPATCH',
		'TSFMDATAOBJECT',
		'TSFMHNODE',
		'TSFMHOST',
		'TSFMMOBILEWIFI',
		'TSFMMOBILEWIFIUSER',
		'TSFMPAGEADDR',
		'TSFMTEMPLATETABLE',
		'TSFMTICKET',
		'TSFTHOSTDOWN'
		)
		--->
		
		and table_name not in (
			'accesbackup',
			'CDATA',
			'CGLOBAL',
			'coba',
			'DateDim',
			'DeadlockEvents',
			'TCAMAWARD_ARCHIVE',
			'TCAMDISCIPLINE_ARCHIVE',
			'TCLDDASHBOARD_Backup',
			'tclddashboard_backup2',
			'TCLDDASHBOARDITEM_Backup',
			'TCLIDFORMHEADREQ',
			'TCLIRREPAIRREQ',
			'TCLIRSUPPLIESREQ',
			'TCLIRTAXIREQ',
			'TCLMDASHGROUP_temp',
			'TCLMSUPPLIES',
			'tdummypath',
			'temp_mail',
			'temp_pop',
			'TEMPSEMINARHR',
			'TEMPSEMINARHR3',
			<!--- 'TEODEMPSURVEY', --->
			'TEOMCAREERPATH_pos',
			'TEOMSURVEYCATEGORY',
			'TEOMSURVEYPERIOD',
			'TEOMSURVEYQUESTION',
			'TEOREMPSURVEYQUEST',
			'TEORSURVEYPERIODQUEST',
			'tes_thp',
			'tesdata',
			'THRMEMPCOMPANY',
			'TPMCHECKTEMP',
			'TPMDCPMD',
			'TPMDCPMH',
			'TPMDCPMLIBDETAIL',
			'TPMDEMPCAREERPLANDNOTE_pos',
			'TPMDJFLCOMPETENCE',
			'TPMDJTCOMPETENCE',
			'TPMDLIBGROUP',
			'TPMDLIBGROUPAPPRAISAL',
			'TPMDLIBGROUPCOMPETENCE',
			'TPMDLIBGROUPCOMPONENT',
			'TPMDLIBGROUPOBJECTIVE',
			'TPMDPERFORMANCE_MIDD',
			'TPMDPERFORMANCE_MIDH',
			'TPMDPERFORMANCE_MIDKPI',
			'TPMDPERFORMANCE_MIDNOTE',
			'TPMDPERIODAPPLIB',
			'TPMDPERIODAPPRLIBTEMP',
			'TPMDPERIODCOMPLIB',
			'TPMDPERIODKPILIBTEMP',
			'TPMDPERIODOBJLIB',
			'TPMMPERIODOLD',
			'TPMMREPEATPERIOD',
			'TPMRCOMPETENCEJT',
			'TPMRFORMPOS',
			'TPMRLIBGROUPGRADE',
			'TPMRLIBGROUPPOS',
			'tpydjournaldetailtemp',
			'TPYDSALARYPROCESS',
			'TPYMSALARYGRADED',
			'TPYMSALARYGRADEH',
			'TRCDAPPOFFER',
			'TRCDRECRUITMENTREQUEST',
			'TTRDPLAN',
			'TTRDPLANDETAIL',
			'TTRDPLANREQUEST',
			'TTRDPLANREQUESTDETAIL',
			'TTRDREQUEST',
			'TTRMCOST',
			'TTRMEVALGROUP',
			'TTRMEVALLIB',
			'TTRMEVALSTAGE',
			'TTRMFEEDBACK',
			'TTRMPLANPPERIOD',
			'TTRMTRAINCOURSE',
			'TTRMVENUEROOM',
			'TTRREVALGROUP',
			'TTRRPLANMEMBER',
			'TTRRPLANREQUESTMEMBER',
			'TTRRTRAINCOURSEEVAL',
			'ww',
			'xx_TCLMDASHODATAFACT',
			'xx_testwahyu'
		) 
			<!--- 
			and table_name not in ('dtproperties','Results','sysdiagrams') 
			and table_name not in ('THRMPOSITION2','ATTENDANCETEMP_xx','BOARD','BOARD_MAIN')
			and table_name not like '%$%'
			and table_name not like '%_TEMP'
			and table_name not like '%_BACKUP'
			and table_name not like '%_ORIG'
			<!--- yohanes 10 Mei 2012 --->
			and table_name not like 'backup_%'
			and table_name not like '%_BCK' 
			and table_name not like '%_BAK' 
			and table_name not like '%2' 
			and table_name not like '%_bc' 
			and table_name not like '%thrmempbanktransfertest%'
			and table_name not like '%thrmposition_26Mar2011%'
			and table_name not like '%_TEMP_LEO'
			and table_name not in ('PMATTR','PMBRNC','PMCLSS','PMCNFG','PMGUSR','PMLATT','PMLIBR','PMLOCK','PMOBJT','PMOCNF','PMOLOG','PMOPTS','PMPERM','PMRLSH','PMRLTN','PMRLTX','PMSEQN','PMTEXT','PMUSER','PMXFIL','THRMEMPSALARYPARAM','TMP_Random','THRMTRAININGCATEGORY_OLD20120704','tmptestmmmm','thrmpolicy_24Sep2013','testtablechar ')
			<cfif Ucase(url.dbdsttype) eq "ORACLE">
			and table_name not in ('Tappchecklist_Detail','Tappchecklist_Detail_Configuration','Tappchecklist_Detail_Migration','TAPPMigration_function_component','THRM2316setting','THRMINCOMECATEGORY','THRMLogSettingApprovalDetail','THRMPAYROLLCOMPONENTREQUEST_DETAIL','THRMPHRATE')
			</cfif>
			--->
		order by table_name 
		<!--- end --->
	</cfquery>
</cfif>

<cfif UCase(url.dbdsttype) eq "ORACLE">
	<cfquery name="qTable2" datasource="#TargetDSN#">
		select table_name from user_tables
		ORDER BY table_name
	</cfquery>
<cfelse><!--- if UCase(url.dbdsttype) eq "MSSQLSERVER" --->
	<cfquery name="qTable2" datasource="#TargetDSN#">
		SELECT * FROM Information_Schema.TABLES 
		where table_type = 'BASE TABLE'
		<!---  and table_name not in ('dtproperties','Results')  --->
		and table_schema = '#url.dbdst#'
		<!--- and table_name = 'bakup_config_21042020' --->
		order by table_name 
	</cfquery>
</cfif>
<!--- <cfdump var='#qTable1#' label='qTable1' expand='yes'>
<cfdump var='#qTable2#' label='qTable2' expand='yes'> --->

<cfset TargetTable = ValueList(qTable2.table_name)>

<cfif isDefined("URL.debug")>
	<cfdump var="#qTable1#">
	<cfabort>
</cfif>

<!--- marcabort line:<cfabort> --->

<cfloop query="qTable1">
	<cfset TableCheck = qTable1.table_name>
	<cfif NOT ListFindNoCase(TargetTable,TableCheck)>
		<cfif not isdefined("oldonly")>
			<cfset colname = "">
			<cfif UCase(url.dbsrctype) eq "ORACLE">
				<cfquery name="qColumns2" datasource="#SourceDSN#">
					select column_name, data_type, data_length from user_tab_columns where UPPER(table_name) = '#UCase(TableCheck)#'
					order by column_id
				</cfquery>
				<cfquery name="qidentity" datasource="#SourceDSN#">
					select table_name, trigger_body from user_triggers
					where UPPER(table_name) = '#UCase(TableCheck)#'
				</cfquery>
				
				<cfif qidentity.RecordCount>
					<cfquery name="qCol" datasource="#SourceDSN#">
						SELECT	Column_Name
						FROM	user_tab_columns
						WHERE	UPPER(table_name) = '#UCase(TableCheck)#'
					</cfquery>
					<cfloop query="qCol">
						<cfif FindNoCase(":NEW.#qCol.Column_Name#",qidentity.Trigger_Body)>
							<cfset find = FindNoCase("#qCol.Column_Name#",qidentity.Trigger_Body)>
							<cfset colname = Mid(qidentity.Trigger_Body,find,LEN(qCol.Column_Name))>
						</cfif>
					</cfloop>
				</cfif>
			<cfelse><!--- if UCase(url.dbsrctype) eq "MSSQLSERVER" --->
				<cfquery name="qColumns2" datasource="#SourceDSN#">
					SELECT DISTINCT TABLE_NAME,COLUMN_NAME,ORDINAL_POSITION,COLUMN_DEFAULT
						,IS_NULLABLE,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,
						<!--- add by Marc --->
						<cfif UCase(url.dbsrctype) eq "mariadb">
							column_type
						</cfif>
					FROM  Information_Schema.COLUMNS 
					where UPPER(table_name) = '#UCase(TableCheck)#'
					and table_schema = '#dbsrc#'
					Order by Ordinal_Position
				</cfquery>
				<!--- <cfdump var='#qColumns2#' label='qColumns2' expand='yes'> --->
				<cftry>
					<cfquery name="qidentity" datasource="#SourceDSN#">
						SELECT TOP 1 IDENTITYCOL
						From "#UCase(TableCheck)#"
					</cfquery>
					<cfset colname = UCase(qidentity.columnlist)>
				<cfcatch>#cfcatch.message#</cfcatch>
				</cftry>
			</cfif>
 			<table border="1" width="500"> 
 				<tr><td>ADD TABLE</td><td bgcolor="C0C0C0"><b><!--- <font color="##0000ff">#UCase(SourceDSN)#</font>. ---><font color="##ff0000">#TableCheck#</font><!--- &nbsp;(#Ucase(url.dbsrctype)#) ---></b></td></tr> 

			<cfif isdefined("alter")>
				<cfif url.dbdsttype eq "MSSQLSERVER">
					<cfset crtable="dbo.#TableCheck#">
				<cfelse>
					<cfset crtable=TableCheck>
				</cfif>
				<cfset dbcreate = "CREATE TABLE #crtable# ( ">
			</cfif>

			<cfset colcount = 0>
			<cfloop query="qColumns2">
				<cfif UCase(url.dbsrctype) eq "ORACLE">
					<cfset data_length = data_length>
				<cfelseif UCase(url.dbsrctype) eq "MARIADB">
					<cfset data_length = column_type>
				<cfelse><!--- if UCase(url.dbsrctype) eq "MSSQLSERVER" --->
					<cfset data_length = ucase(character_maximum_length)>
				</cfif>
					<!--- kolom table baru --->				
					<!--- <tr>
						<td width="50%">
							<cfif UCase(url.dbsrctype) eq "ORACLE">
								<cfif colname eq qColumns2.column_name><b>#UCASE(qColumns2.column_name)#*</b><cfelse>#UCASE(qColumns2.column_name)#</cfif>
							<cfelse><!--- if UCase(url.dbsrctype) eq "MSSQLSERVER" --->
								<cfif colname eq qColumns2.column_name>
									<b>#UCASE(qColumns2.column_name)#*</b>
								<cfelse>
									#UCASE(qColumns2.column_name)#
								</cfif>
							</cfif>
						</td>
						<td width="25%">#UCASE(qColumns2.data_type)#</td>
						<td width="25%">#data_length#&nbsp;</td>				
					</tr> --->

				<cfif isdefined("alter")>
					<cfif url.dbdsttype neq url.dbsrctype>
						<cfif UCase(url.dbdsttype) eq "ORACLE">
							<cfset Tdata_type = ListGetAt(OraDataType,ListFindNoCase(SQLDataType,qColumns2.data_type))>
						<cfelse><!--- if UCase(url.dbdsttype) eq "MSSQLSERVER" --->
							<cfset Tdata_type = ListGetAt(SQLDataType,ListFindNoCase(OraDataType,qColumns2.data_type))>
						</cfif>
					<cfelse>
						<!--- Remarked by Marc :
						<cfset Tdata_type = qColumns2.data_type> --->
						<!--- Add by Marc --->
						<cfset Tdata_type = qColumns2.column_type>
					</cfif>
					<cfif colcount gt 0>
						<cfset dbcreate = dbcreate & ", ">
					</cfif>
					
					<cfif UCase(url.dbdsttype) eq "ORACLE">
						<cfset dbcreate = dbcreate & "#UCase(column_name)# #UCase(Tdata_type)# ">
					<cfelseif UCase(url.dbdsttype) eq "MSSQLSERVER">
					 	<cfset dbcreate = dbcreate & "[#UCase(column_name)#] #UCase(Tdata_type)# ">
						<cfif colname eq qColumns2.column_name>
							<cfset dbcreate = dbcreate & "IDENTITY (1,1) ">
						</cfif>
					<!--- add by Marc --->
					<cfelse><!--- if UCase(url.dbdsttype) eq "mariadb/mysql" --->
						<cfset dbcreate = dbcreate & "`#lcase(column_name)#` #lcase(Tdata_type)# ">
					   	<cfif colname eq qColumns2.column_name>
						   <cfset dbcreate = dbcreate & "IDENTITY (1,1) ">
					   	</cfif>
					</cfif>
					<!--- <cfif NOT ListFindNoCase(NonAtribut,Tdata_Type) AND data_length neq "">
					      <cfif data_length eq "-1">
						     <cfset data_length="MAX">
                          </cfif>
                           <cfif UCase(url.dbdsttype) eq "ORACLE">
						      <cfif UCase(Tdata_type) eq "VARCHAR2">
                                <cfif val(data_length) gte 4000>
                                  <cfset data_length = 4000 >
                                </cfif> 
                              </cfif>
                          </cfif>
						  <cfset dbcreate = dbcreate & "(#data_length#) ">
                     </cfif> --->
					<cfset colcount = colcount + 1>
				</cfif>
			</cfloop>
	
			
			
			<cfif isdefined("alter")>
				<cfset dbcreate = dbcreate & " )">
				<tr><td>SCRIPT</td><td>#UCase(TableCheck)#</td><td>#dbcreate#</td></tr>
				
				<cfif isdefined("alteryes")>
				<!--- SCRIPT ADD TABLE --->
				<cfquery name="qAlter" datasource="#TargetDSN#"> 
					#dbcreate#
				</cfquery>
				</cfif>
				
				<cfif colname neq "" and UCase(url.dbdsttype) eq "ORACLE">
					<cftry>
						<cfquery name="qDropSeq" datasource="#TargetDSN#">
							DROP SEQUENCE #TableCheck#_SEQ
						</cfquery>
						<cfcatch></cfcatch>
					</cftry>
					<cfquery name="qAlterSequence" datasource="#TargetDSN#">
						CREATE SEQUENCE #TableCheck#_SEQ
							INCREMENT BY 1
							START WITH 1
							NOMAXVALUE
							NOMINVALUE
							NOCYCLE
							CACHE 20
							NOORDER
					</cfquery>
					<cfquery name="qAlterTrigger" datasource="#TargetDSN#">
						CREATE OR REPLACE TRIGGER #TableCheck#_TRIG before insert on #TableCheck# for each row begin select #TableCheck#_SEQ.nextval into :new.#colname# from dual; end #TableCheck#_TRIG;
					</cfquery>
				</cfif>
			</cfif>

 			</table> 
		</cfif>
	<cfelse> <!--- Sync Column --->
		<cfif UCase(url.dbdsttype) eq "ORACLE">
			<cfquery name="qColumns1" datasource="#TargetDSN#">
				select column_name, data_type, data_length from user_tab_columns where UPPER(table_name) = '#UCase(TableCheck)#'
				order by column_id
			</cfquery>
		<cfelse><!--- if UCase(url.dbdsttype) eq "MSSQLSERVER" --->
			<cfquery name="qColumns1" datasource="#TargetDSN#">
				SELECT DISTINCT TABLE_NAME,COLUMN_NAME,ORDINAL_POSITION,COLUMN_DEFAULT
					,IS_NULLABLE,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH
				FROM  Information_Schema.COLUMNS 
				where UPPER(table_name) = '#UCase(TableCheck)#'
				and table_schema = '#dbdst#'
				Order by Ordinal_Position
			</cfquery>
			<!--- <cfdump var='#qColumns1#' label='qColumns1' expand='yes'> --->
		</cfif>
		<cfset TargetColumns = UCase(ValueList(qColumns1.column_name))>
		<cfset TargetColumns = ListQualify(TargetColumns,"'",",","CHAR")>
		<cfif UCase(url.dbsrctype) eq "ORACLE">
			<cfquery name="qColumns2" datasource="#SourceDSN#">
				select column_name, data_type, data_length from user_tab_columns where UPPER(table_name) = '#UCase(TableCheck)#'
				and UPPER(column_name) not in (#PreserveSinglequotes(TargetColumns)#)
				order by column_id
			</cfquery>
			<cfset idencol = "">
			<cfquery name="qIdenCheck" datasource="#SourceDSN#">
				select table_name, trigger_body from user_triggers
				where UPPER(table_name) = '#UCase(TableCheck)#'
			</cfquery>
			<cfif qIdenCheck.RecordCount>
				<cfquery name="qCol" datasource="#SourceDSN#">
					SELECT	Column_Name
					FROM	user_tab_columns
					WHERE	UPPER(table_name) = '#UCase(TableCheck)#'
				</cfquery>
				<cfloop query="qCol">
					<cfif FindNoCase(":NEW.#qCol.Column_Name#",qIdenCheck.Trigger_Body)>
						<cfset find = FindNoCase("#qCol.Column_Name#",qIdenCheck.Trigger_Body)>
						<cfset idencol = Mid(qIdenCheck.Trigger_Body,find,LEN(qCol.Column_Name))>
					</cfif>
				</cfloop>
			</cfif>
		
		<cfelse><!--- if UCase(url.dbsrctype) eq "MSSQLSERVER" --->
			<cfquery name="qColumns2" datasource="#SourceDSN#">
				SELECT DISTINCT TABLE_NAME,COLUMN_NAME,ORDINAL_POSITION,COLUMN_DEFAULT
					,IS_NULLABLE,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH, column_type
				FROM  Information_Schema.COLUMNS 
				where UPPER(table_name) = '#UCase(TableCheck)#'
				and table_schema = '#dbsrc#'
				and UPPER(column_name) not in (#PreserveSinglequotes(TargetColumns)#)
				Order by Ordinal_Position
			</cfquery>
			<!--- <cfdump var='#qColumns2#' label='qColumns2' expand='yes'> --->
			<cftry>
					<cfquery name="qIdenCheck" datasource="#SourceDSN#">
						SELECT TOP 1 IDENTITYCOL
						From "#UCase(TableCheck)#"
					</cfquery>
					<cfset idencol = qIdenCheck.columnlist>
				<cfcatch></cfcatch>
			</cftry>
		</cfif>
		
		<!--- <cfif idencol neq "">
				<cfset idencoltgt = "">
				<cfif UCase(url.dbdsttype) eq "ORACLE">
				<cfquery name="qIdenCheckTgt" datasource="#TargetDSN#">
					select table_name, trigger_body from user_triggers
					where UPPER(table_name) = '#UCase(TableCheck)#'
				</cfquery>
				<cfif qIdenCheck.RecordCount>
					<cfquery name="qCol" datasource="#SourceDSN#">
						SELECT	Column_Name
						FROM	user_tab_columns
						WHERE	UPPER(table_name) = '#UCase(TableCheck)#'
					</cfquery>
					<cfloop query="qCol">
						<cfif FindNoCase(":NEW.#qCol.Column_Name#",qIdenCheckTgt.Trigger_Body)>
							<cfset find = FindNoCase("#qCol.Column_Name#",qIdenCheckTgt.Trigger_Body)>
							<cfset idencoltgt = Mid(qIdenCheckTgt.Trigger_Body,find,LEN(qCol.Column_Name))>
						</cfif>
					</cfloop>
				</cfif>
			<cfelseif UCase(url.dbdsttype) eq "MSSQLSERVER">
				<cftry>
					<cfquery name="qIdenCheckTgt" datasource="#TargetDSN#">
						SELECT TOP 1 IDENTITYCOL
						From "#UCase(TableCheck)#"
					</cfquery>
					<cfset idencoltgt = qIdenCheckTgt.columnlist>
				<cfcatch></cfcatch>
				</cftry>
			</cfif>
			<cfif idencoltgt eq "" AND qIdenCheck.RecordCount>
				<cfif isdefined("alter")>
					<cfif UCase(url.dbdsttype) eq "ORACLE">
						<cfquery name="qMax" datasource="#TargetDSN#">
							SELECT	Max(#idencol#) AS ValMax FROM #TableCheck#
						</cfquery>
						<cfif isNumeric(qMax.ValMax)>
							<cfset startseq = qMax.ValMax + 1>
						<cfelse>
							<cfset startseq = 1>
						</cfif>
						<cfset seqname = TableCheck&"_SEQ">
						<cfset trigname = TableCheck&"_TRIG">
						<!--- <cftry>
							<cfquery name="qDropSeq" datasource="#TargetDSN#">
								DROP SEQUENCE #seqname#
							</cfquery>
							<cfquery name="qDropSeq" datasource="#TargetDSN#">
								DROP TRIGGER #trigname#
							</cfquery>
							<cfcatch></cfcatch>
						</cftry>
						<cfquery name="qCreatSeq" datasource="#TargetDSN#">
							CREATE SEQUENCE #seqname# INCREMENT BY 1 START WITH #startseq#
						</cfquery> --->
						<!--- <cfquery name="qCreateTrig" datasource="#TargetDSN#">
							CREATE OR REPLACE TRIGGER #trigname# before insert on #TableCheck# for each row begin select #seqname#.nextval into :new.#idencol# from dual; end #trigname#;
						</cfquery> --->
					</cfif>
				</cfif>
				<!--- <table border="1" width="500">
					<tr>
						<td colspan="2" bgcolor="C0C0C0"><b><font color="##ff0000">IDENTITY NOT FOUND IN TABLE</font> #UCase(TableCheck)#</b></td>
					</tr>
					<tr>
						<td width="60%">#UCASE(TableCheck)#</td>
						<td width="40%">#UCASE(idencol)#</td>
					</tr>
				</table> --->
			</cfif>
		</cfif>		 --->
		<cfif qColumns2.RecordCount>
 			<table border="1" width="500">
 				<tr><td>ADD COLUMN</td><td bgcolor="C0C0C0"><b><!--- <font color="##0000ff">#UCase(SourceDSN)#</font>. --->#TableCheck#<!--- &nbsp;(#Ucase(url.dbdsttype)#) ---></b></td></tr> 
			<cfloop query="qColumns2">
				<cfif UCase(url.dbsrctype) eq "ORACLE">
					<cfset data_length = data_length>
				<cfelse><!--- if UCase(url.dbsrctype) eq "MSSQLSERVER" --->
					<cfset data_length = ucase(character_maximum_length)>
				</cfif>
  				<tr>
					<td>ADD COLUMN</td>
					<td>#UCase(TableCheck)#</td>
					<td width="50%">`#UCase(qColumns2.column_name)#`</td>
					<td width="25%">#UCase(qColumns2.data_type)#</td>
					<td width="25%">#data_length#&nbsp;</td>
				</tr>
				
				<!--- FOR INSERTING DEFAULT VALUE of the new column, need to be rethought --->
					<!--- 
				<cfquery name="qQry" datasource="#SourceDSN#">
					select top 1 #UCase(column_name)#
					from #UCase(TableCheck)# 
					where [#UCase(column_name)#] is not null
					</cfquery>
				--->
		
				<cfif isdefined("alter")>
					<cfif url.dbdsttype neq url.dbsrctype>
						<cfif UCase(url.dbdsttype) eq "ORACLE">
							<cfset Tdata_type = ListGetAt(OraDataType,ListFindNoCase(SQLDataType,qColumns2.data_type))>
						<cfelseif UCase(url.dbdsttype) eq "MSSQLSERVER">
							<cfset Tdata_type = ListGetAt(SQLDataType,ListFindNoCase(OraDataType,qColumns2.data_type))>
						<cfelse>
							<cfset Tdata_type = qColumns2.column_type>
						</cfif>
					<cfelse>
						<cfset Tdata_type = qColumns2.column_type>
					</cfif>
					<tr><td>SCRIPT</td><td>#UCase(TableCheck)#</td>
						<td>
						ALTER TABLE #UCase(TableCheck)#
						ADD 
						<cfif UCase(url.dbdsttype) eq "ORACLE">
							#UCase(column_name)#
						<cfelse>
							`#UCase(column_name)#`
						</cfif> 
						#UCase(Tdata_type)# 
							<!--- <cfif NOT ListFindNoCase(NonAtribut,Tdata_Type) AND data_length neq "">
								<cfif data_length eq "-1">
									<cfset data_length="MAX">
								</cfif>(#data_length#)
							</cfif>			 --->
					</td></tr>
					<cfif isdefined("alteryes")>
					<!--- SCRIPT ADD COLUMN --->
					<cfquery name="qAlter" datasource="#TargetDSN#">
					 	ALTER TABLE #UCase(TableCheck)#
						ADD <cfif UCase(url.dbdsttype) eq "ORACLE"> #UCase(column_name)#<cfelse> `#lcase(column_name)#`</cfif> #lcase(Tdata_type)# 
							<!--- <cfif NOT ListFindNoCase(NonAtribut,Tdata_Type) AND data_length neq "">
								<cfif data_length eq "-1">
									<cfset data_length="MAX">
								</cfif>
									(#data_length#)
							</cfif> --->
					</cfquery>
					</cfif>
					<!--- add yohanes, 10 Mei 2012 --->
					
					<!--- INSERT DEFAULT VALUE, need to be rethought --->
					<!--- 
					<cfif qQry.recordcount>
					<cfquery name="qUpdData" datasource="#TargetDSN#">
					 	Update #UCase(TableCheck)#
						SET <cfif UCase(url.dbdsttype) eq "ORACLE">#UCase(column_name)#<cfelse>[#UCase(column_name)#]</cfif> = '#evaluate("qQry.#column_name#")#'
					</cfquery>
					</cfif>
					 --->
					<!--- end --->
				</cfif>

			</cfloop>
 			</table> 
		</cfif>
	</cfif>

	<!--- 		
	<!--- Indexes --->
	<cfif url.dbsrctype eq "ORACLE">
		<cfquery name="qTbIndex" datasource="#SourceDSN#">
			select I.table_name,I.index_name,column_name 
			from user_indexes I, user_ind_columns C
			where I.table_name = C.table_name
				and UPPER(I.table_name) = '#ucase(TableCheck)#'
				and UPPER(index_type) = 'NORMAL'
			order by index_name
		</cfquery>
	<cfelse>
		<cfquery name="qTbIndex" datasource="#SourceDSN#">
			select T.name table_name,I.name index_name,C.name column_name
			from sysindexes I,sysobjects T,sysindexkeys X,syscolumns C
			where T.id = I.id 
			    and T.id = X.id
			    and X.indid = I.indid
			    and T.id = C.id
			    and C.colid = X.colid
			    and I.indid <> 0 and I.used <> 0
			    and T.xtype='U' and UPPER(T.name)='#ucase(TableCheck)#'	
			order by index_name
		</cfquery>
	</cfif>
	<cfset iname="">
	<cfset lstXName="">
	<cfset lstXField="">
	<cfloop query="qTbIndex">
		<cfif iname neq index_name>
			<cfif iname neq "" and lstXField neq "">
				<cfset lstXName=listSetAt(lstXName,listlen(lstXName,"|"),listLast(lstXName,"|") & "-" & lstXField ,"|")>
			</cfif>
			<cfset lstXName=listAppend(lstXName,index_name,"|")>
			<cfset lstXField="">
			<cfset lstXField=listAppend(lstXField,column_name)>
			<cfset iname = index_name>
		<cfelse>
			<cfset lstXField=listAppend(lstXField,column_name)>
		</cfif>
	</cfloop>
	<cfif iname neq "" and lstXField neq "">
		<cfset lstXName=listSetAt(lstXName,listlen(lstXName,"|"),listLast(lstXName,"|") & "-" & lstXField ,"|")>
	</cfif>
	<cfloop index="xname" list="#lstXName#" delimiters="|">
	<cftry>
		<cfif url.dbdsttype eq "ORACLE">
			<cftransaction>
				<cfquery name="qDropIndex" datasource="#TargetDSN#">
					DROP INDEX #listfirst(xname,"-")#
				</cfquery>
				<cfquery name="qCreateIndex" datasource="#TargetDSN#">
					CREATE INDEX #listfirst(xname,"-")#
					ON #ucase(TableCheck)# (#listlast(xname,"-")#)
				</cfquery>
			</cftransaction>
		<cfelse>
			<cfquery name="qUpdateIndex" datasource="#TargetDSN#">
				CREATE INDEX #listfirst(xname,"-")#
				ON #ucase(TableCheck)# (#listlast(xname,"-")#)
				WITH DROP_EXISTING
			</cfquery>
		</cfif>
	<cfcatch></cfcatch>
	</cftry>
	</cfloop>
	<!--- End of Indexes --->
 	--->	
 
</cfloop>


<script>
	<cfif isdefined("alteryes")>
		alert('Database altered!!')
	<cfelseif isdefined("alter")>
		alert('Database script created!!')
	<cfelse>
		alert('DB check Finish')
	</cfif>
</script>
</cfoutput>