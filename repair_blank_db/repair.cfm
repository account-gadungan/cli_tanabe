<cfoutput>
    <cfquery name="qRepair" datasource="dbsf_mtindonesia" result="qResult">
        call repair_evald;
    </cfquery>
    #now()#
    <cfdump var="#qResult#">
</cfoutput>