/****** Object:  View [dbo].[V_Analysis_Job_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Request_Entry]
AS
SELECT AJR.AJR_requestID AS request_id,
       AJR.AJR_requestName AS request_name,
       AJR.AJR_created AS created,
       AJR.AJR_analysisToolName AS analysis_tool,
       AJR.AJR_parmFileName AS param_file_name,
       AJR.AJR_settingsFileName AS settings_file_name,
       AJR.AJR_organismDBName AS organism_db_name,
       Org.OG_name AS organism_name,
       Case When IsNull(Data_Package_ID, 0) > 0 Then ''
            Else dbo.GetJobRequestDatasetNameList(AJR.AJR_requestID)
       End As datasets,
       AJR.data_package_id,
       AJR.AJR_comment AS comment,
       AJR.AJR_specialProcessing AS special_processing,
       ARS.StateName AS state,
       U.U_PRN AS requestor,
       AJR.AJR_proteinCollectionList AS prot_coll_name_list,
       AJR.AJR_proteinOptionsList AS prot_coll_options_list
FROM T_Analysis_Job_Request AS AJR
     INNER JOIN T_Analysis_Job_Request_State AS ARS
       ON AJR.AJR_state = ARS.ID
     INNER JOIN T_Users AS U
       ON AJR.AJR_requestor = U.ID
     INNER JOIN T_Organisms AS Org
       ON AJR.AJR_organism_ID = Org.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_Entry] TO [DDL_Viewer] AS [dbo]
GO
