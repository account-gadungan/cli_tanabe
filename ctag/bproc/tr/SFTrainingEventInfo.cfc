<!---
			Author               : 
			E-mail               : 
			Company              : DataOn/ PT. Indodev Niaga Internet
			Client               :  
			FileName             : \ctag\bproc\tr\SFTrainingEventInfo.cfc
			Application          : SunFish HR SaaS
			Date                 : 19 Juli 2013
			Summary              : 
			Revisions            : SFTrainingEventInfo.cfc 
--->
<cfcomponent displayname="SFTrainingEventInfo" hint="SunFish Training Event Info Business Process Object" extends="sfcomp.bproc.tr.SFTrainingEventInfo">
	
	<cffunction name="SaveInfo">
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
		<cfoutput>
		#seldelivmethod# koma
		#evalmethod# koma
		#acceptcriteria# koma
		#material# 
		</cfoutput>
		<cfparam name="sel_cost_type" default="">
		<!--- Training Event Param --->
		<cfparam name="hdn_trncourse_code" default="">
		<cfparam name="trnevent_topic" default="">
		<cfparam name="hdn_nametype" default="">
		<cfparam name="nametype" default="">
		<cfparam name="trnevent_startdate" default="">
		<cfparam name="trnevent_enddate" default="">
		<cfparam name="trnevent_sts" default="">
		<cfset retVarSaveInfo = true>
		<cfset retvar1 = true>
		<cfset retvar2 = true>
		<cfset retvar3 = true>
		<cfquery name="LOCAL.qSelectEvent" datasource="#REQUEST.SDSN#">
			SELECT trnevent_code FROM TTRDTRAINEVENT
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		
		<cfset LOCAL.strckData = FORM />
		<cfset LOCAL.strckDataEvent = StructNew() />
		<cfset strckDataEvent['trnevent_code'] = #evaluate("trnevent_code")# />
		<cfset strckDataEvent['trncourse_code'] = #evaluate("hdn_trncourse_code")# />
		<cfset strckDataEvent['company_code'] = #evaluate("company_code")# />
		<cfset strckDataEvent['trnevent_topic'] = #evaluate("trnevent_topic")# />
		<cfset strckDataEvent['trnevent_type'] = #evaluate("nametype")# />
		<cfset strckDataEvent['trnevent_startdate'] = #evaluate("trnevent_startdate")# />
		<cfset strckDataEvent['trnevent_enddate'] = #evaluate("trnevent_enddate")# />
		<cfset strckDataEvent['trnevent_sts'] = #evaluate("trnevent_sts")# />
		<cfset strckDataEvent['costcenter_type'] = #evaluate("sel_cost_type")# />
		
		<cfset LOCAL.objModel1 = CreateObject("component", "SMTrainingEvent") />
		<cfif qSelectEvent.recordcount>
			<cfset retvar1 = objModel1.Update(strckDataEvent)>
		<cfelse>
			<cfset retvar1 = objModel1.Insert(strckDataEvent)>
		</cfif> 
		
		<cfparam name="hdn_provider_code" default="">
		<cfquery name="LOCAL.qSelectVenue" datasource="#REQUEST.SDSN#">
			SELECT trnevent_code FROM TTRRTRAINEVENTVENUE
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<cfset LOCAL.strckData = FORM />
		<cfset LOCAL.strckDataEventVenue = StructNew() />
		<cfset strckDataEventVenue['trnevent_code'] = #evaluate("trnevent_code")# />
		<cfset strckDataEventVenue['company_code'] = #evaluate("company_code")# />
		<cfset strckDataEventVenue['provider_code'] = #evaluate("hdn_provider_code")# />
		<cfset LOCAL.objEventVenue= CreateObject("component", "SMTrainingEventVenue") />
		<cfif val(qSelectVenue.recordcount) gt 0>
			<cfset retvar2=objEventVenue.Update(strckDataEventVenue) />
		<cfelse>
			<cfset retvar2=objEventVenue.Insert(strckDataEventVenue) />
		</cfif>
		
		<!--- End --->
		
		<cfquery name="LOCAL.qSelectInfo" datasource="#REQUEST.SDSN#">
			SELECT trnevent_code FROM TTRRTRAINEVENTINFO
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<cfset LOCAL.strckData = FORM />
		<cfset LOCAL.strckDataEventInfo = StructNew() />
		<cfset strckDataEventInfo['trnevent_code'] = #evaluate("trnevent_code")# />
		<cfset strckDataEventInfo['company_code'] = #evaluate("company_code")# />
		<cfset strckDataEventInfo['trnevent_bckground'] = #evaluate("trnevent_bckground")# />
		<cfset strckDataEventInfo['trnevent_obj'] = #evaluate("trnevent_obj")# />
		<cfset strckDataEventInfo['trnevent_target'] = #evaluate("trnevent_target")# />
		<cfset strckDataEventInfo['trnevent_remark'] = #evaluate("trnevent_remark")# />
		<!--- muadz nambahin yang buat diinsert --->
		<cfset strckDataEventInfo['delivmethod'] = #evaluate("seldelivmethod")# />
		<cfset strckDataEventInfo['evalmethod'] = #evaluate("evalmethod")# />
		<cfset strckDataEventInfo['acceptcriteria'] = #evaluate("acceptcriteria")# />
		<cfset strckDataEventInfo['material'] = #evaluate("material")# />
		<!--- muadz nambahin yang buat diinsert --->
		<cfif trnevent_attachment neq ''>
			<cfif hdn_trnevent_attachment neq ''>
				<CF_SFUPLOAD ACTION="DELETE" CODE="trneventinfo" FILENAME="#hdn_trnevent_attachment#" output="vTestDelete">
			</cfif>
			<cfset trneventcode = #evaluate("trnevent_code")#>
			<CF_SFUPLOAD ACTION="UPLOAD" CODE="trneventinfo" FILEFIELD="trnevent_attachment" REWRITE="YES" RENAME="#trneventcode#" output="vTest">
			<cfset file_name_save = #trneventcode#&'.'&#vTest.clientFileExt# />
			<cfset strckDataEventInfo['trnevent_attachment'] = #file_name_save# />
		<cfelse>
			<cfset strckDataEventInfo['trnevent_attachment'] = #hdn_trnevent_attachment# />
		</cfif>
		<cfset LOCAL.objEventInfo = CreateObject("component", "SMTrainingEventInfo") />
		<cfdump  var="#strckDataEventInfo#">
		<cfquery name="LOCAL.qSelectsahaja" datasource="#REQUEST.SDSN#">
			SELECT * FROM TTRRTRAINEVENTINFO where trnevent_code = '#trnevent_code#'
		</cfquery>
		<cfdump  var="#qSelectsahaja#" label="before">
		<cfif val(qSelectInfo.recordcount) gt 0>
			<!---<cfset LOCAL.retvar3=objEventInfo.Update(strckDataEventInfo) />--->
			<cfset LOCAL.retvar3=Application.SFDB.Update("TTRRTRAINEVENTINFO",strckDataEventInfo)>
			<!--- muadz kaga ngarti dah kenapa pakai sfdb atau model si column customnya ga bisa terupdate 
			<cfquery name="LOCAL.qUpdateEventIfo" datasource="#REQUEST.SDSN#" result="rUpdateEventIfo">
				update TTRRTRAINEVENTINFO set delivmethod = '#delivmethod#', evalmethod = '#evalmethod#', acceptcriteria = '#acceptcriteria#', material = '#material#' where trnevent_code = '#trnevent_code#'
			</cfquery>
			<cfdump  var="#rUpdateEventIfo#" label="rUpdateEventIfo">--->
		<cfelse>
			<!---<cfset LOCAL.retvar3=objEventInfo.Insert(strckDataEventInfo) />--->
			<cfset LOCAL.retvar3=Application.SFDB.Insert("TTRRTRAINEVENTINFO",strckDataEventInfo)>
		</cfif>
		<cfquery name="LOCAL.qSelectsaja" datasource="#REQUEST.SDSN#">
			SELECT * FROM TTRRTRAINEVENTINFO where trnevent_code = '#trnevent_code#'
		</cfquery>
		<cfdump  var="#qSelectsaja#" label="after">
		<cfif retvar1 eq false OR retvar2 eq false OR retvar3 eq false>
			<cfset retVarSaveInfo = false>
		</cfif>

		<cfreturn retVarSaveInfo>
	</cffunction>
	
	
	<cffunction name="DeleteInfo">
		<cfparam name="trnevent_code" default="">
		<cfparam name="company_code" default="#REQUEST.Scookie.COID#">
		<cfparam name="trnevent_bckground" default="">
		<cfparam name="trnevent_obj" default="">
		<cfparam name="trnevent_target" default="">
		<cfparam name="trnevent_remark" default="">
		<!--- Muadz nambahin yang buat diinsert --->
		<cfparam name="seldelivmethod" default="">
		<cfparam name="evalmethod" default="">
		<cfparam name="acceptcriteria" default="">
		<cfparam name="material" default="">
		<!--- Muadz nambahin yang buat diinsert --->
		<cfparam name="trnevent_attachment" default="">
		<cfparam name="hdn_trnevent_attachment" default="">
		<cfset LOCAL.strckData = FORM />
		<cfset LOCAL.strckDataEventInfo = StructNew() />
		<cfset strckDataEventInfo['trnevent_code'] = #evaluate("trnevent_code")# />
		<cfset strckDataEventInfo['company_code'] = #evaluate("company_code")# />
		<cfset strckDataEventInfo['trnevent_bckground'] = #evaluate("trnevent_bckground")# />
		<cfset strckDataEventInfo['trnevent_obj'] = #evaluate("trnevent_obj")# />
		<cfset strckDataEventInfo['trnevent_target'] = #evaluate("trnevent_target")# />
		<cfset strckDataEventInfo['trnevent_remark'] = #evaluate("trnevent_remark")# />
		<!--- muadz nambahin yang buat diinsert --->
		<cfset strckDataEventInfo['delivmethod'] = #evaluate("seldelivmethod")# />
		<cfset strckDataEventInfo['evalmethod'] = #evaluate("evalmethod")# />
		<cfset strckDataEventInfo['acceptcriteria'] = #evaluate("acceptcriteria")# />
		<cfset strckDataEventInfo['material'] = #evaluate("material")# />
		<!--- muadz nambahin yang buat diinsert --->
		<cfif hdn_trnevent_attachment neq ''>
			<CF_SFUPLOAD ACTION="DELETE" CODE="trneventinfo" FILENAME="#hdn_trnevent_attachment#" output="vTestDelete">
		</cfif>
		<cfset LOCAL.objEventInfo = CreateObject("component", "SMTrainingEventInfo") />
		<cfset LOCAL.retvar=objEventInfo.Delete(strckDataEventInfo) />
	</cffunction>
	
	<cffunction name="DeleteAll">
		<cfparam name="trnevent_code" default="">
		<cfparam name="company_code" default="#REQUEST.Scookie.COID#">
		<cfparam name="trnevent_bckground" default="">
		<cfparam name="trnevent_obj" default="">
		<cfparam name="trnevent_target" default="">
		<cfparam name="trnevent_remark" default="">
		<!--- Muadz nambahin yang buat diinsert --->
		<cfparam name="seldelivmethod" default="">
		<cfparam name="evalmethod" default="">
		<cfparam name="acceptcriteria" default="">
		<cfparam name="material" default="">
		<!--- Muadz nambahin yang buat diinsert --->
		<cfparam name="trnevent_attachment" default="">
		<cfparam name="hdn_trnevent_attachment" default="">
		
		<!--- Delete Agenda --->
		<cfquery name="LOCAL.qDeleteActivityInstructor" datasource="#REQUEST.SDSN#">
			DELETE FROM TTRRTRAINEVENTINSTRUCTOR
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<cfquery name="LOCAL.qDeleteActivityInstructor" datasource="#REQUEST.SDSN#">
			DELETE FROM TTRRTRAINEVENTINSTRUCTOR
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<cfquery name="LOCAL.qDeleteActivityTime" datasource="#REQUEST.SDSN#">
			DELETE FROM TTRRTRAINEVENTACTIVITYTIME
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<cfquery name="LOCAL.qDeleteActivity" datasource="#REQUEST.SDSN#">
			DELETE FROM TTRRTRAINEVENTACTIVITY
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<!--- End --->
		
		<!--- Delete Vanue --->
		<cfquery name="LOCAL.qDeleteVanue" datasource="#REQUEST.SDSN#">
			DELETE FROM TTRRTRAINEVENTVENUE
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<!--- End --->
		
		<!--- Delete Participant --->
		<cfquery name="LOCAL.qSelectParticipant" datasource="#REQUEST.SDSN#">
			DELETE FROM TTRRTRAINEVENTMEMBER
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		
		<cfset LOCAL.strckData = FORM />
		<cfset LOCAL.strckDataEventCapacity = StructNew() />
		<cfset strckDataEventCapacity['trnevent_code'] = #evaluate("trnevent_code")# />
		<cfset strckDataEventCapacity['company_code'] = #evaluate("company_code")# />
		<cfset strckDataEventCapacity['trnevent_capacity'] = 0 />
		
		<cfset LOCAL.objEventCapacity= CreateObject("component", "SMTrainingEvent") />
		<cfset LOCAL.retvar2=objEventCapacity.Update(strckDataEventCapacity) />
		<!--- End --->
		
		<!--- Delete ESS --->
		<cfquery name="LOCAL.qSelectESS" datasource="#REQUEST.SDSN#">
			DELETE FROM TTRRTRAINEVENTESS
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<!--- End --->
		
		<!--- Delete Other --->
		<cfquery name="LOCAL.qSelectOTHER" datasource="#REQUEST.SDSN#">
			DELETE FROM TTRRTRAINEVENTOTHER
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<!--- End --->
		
		<cfset LOCAL.strckData = FORM />
		<cfset LOCAL.strckDataEventInfo = StructNew() />
		<cfset strckDataEventInfo['trnevent_code'] = #evaluate("trnevent_code")# />
		<cfset strckDataEventInfo['company_code'] = #evaluate("company_code")# />
		<cfset strckDataEventInfo['trnevent_bckground'] = #evaluate("trnevent_bckground")# />
		<cfset strckDataEventInfo['trnevent_obj'] = #evaluate("trnevent_obj")# />
		<cfset strckDataEventInfo['trnevent_target'] = #evaluate("trnevent_target")# />
		<cfset strckDataEventInfo['trnevent_remark'] = #evaluate("trnevent_remark")# />
		<!--- muadz nambahin yang buat dihapus --->
		<cfset strckDataEventInfo['delivmethod'] = #evaluate("seldelivmethod")# />
		<cfset strckDataEventInfo['evalmethod'] = #evaluate("evalmethod")# />
		<cfset strckDataEventInfo['acceptcriteria'] = #evaluate("acceptcriteria")# />
		<cfset strckDataEventInfo['material'] = #evaluate("material")# />
		<!--- muadz nambahin yang buat dihapus --->
		<cfif hdn_trnevent_attachment neq ''>
			<CF_SFUPLOAD ACTION="DELETE" CODE="trneventinfo" FILENAME="#hdn_trnevent_attachment#" output="vTestDelete">
		</cfif>
		<cfset LOCAL.objEventInfo = CreateObject("component", "SMTrainingEventInfo") />
		
		<cfset LOCAL.retvar=objEventInfo.Delete(strckDataEventInfo) />
		
		<!--- Delete Event All --->
		<cfquery name="LOCAL.qSelectEventAll" datasource="#REQUEST.SDSN#">
			DELETE FROM TTRDTRAINEVENT
			WHERE trnevent_code = <cfqueryparam value="#trnevent_code#" cfsqltype="CF_SQL_VARCHAR"> 
			AND company_code = <cfqueryparam value="#company_code#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<!--- End --->
		
		<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Delete Training Event Data",true)>
		
		<cfoutput>
			<script>
				alert("#SFLANG#");
				<!---/*using top cos' form enctype is "multipart/form-data" and return element used frameajax*/--->
				top.popClose();
				if(top.opener){
					top.opener.reloadPage();
				}
			</script>
		</cfoutput>
	</cffunction>
</cfcomponent>