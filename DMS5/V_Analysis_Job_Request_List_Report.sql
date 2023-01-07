/****** Object:  View [dbo].[V_Analysis_Job_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Request_List_Report]
AS
SELECT AJR.AJR_requestID AS request,
       AJR.AJR_requestName AS name,
       AJRS.StateName AS state,
       U.U_Name AS requester,
       AJR.AJR_created AS created,
       AJR.AJR_analysisToolName AS tool,
       AJR.AJR_jobCount AS jobs,
       AJR.AJR_parmFileName AS param_file,
       AJR.AJR_settingsFileName AS settings_file,
       Org.OG_name AS organism,
       AJR.AJR_organismDBName AS organism_db_file,
       AJR.AJR_proteinCollectionList AS protein_collection_list,
       AJR.AJR_proteinOptionsList AS protein_options,
       CASE
           WHEN IsNull(AJR.Data_Package_ID, 0) > 0 Then ''
           WHEN AJR.Dataset_Min = AJR.Dataset_Max THEN AJR.Dataset_Min
           ELSE Coalesce(AJR.Dataset_Min + ', ' + AJR.Dataset_Max, AJR.Dataset_Min, AJR.Dataset_Max)
       END AS datasets,
       AJR.Data_Package_ID AS data_package,
       AJR.AJR_comment AS comment
FROM dbo.T_Analysis_Job_Request AS AJR
     INNER JOIN dbo.T_Users AS U
       ON AJR.AJR_requestor = U.ID
     INNER JOIN dbo.T_Analysis_Job_Request_State AS AJRS
       ON AJR.AJR_state = AJRS.ID
     INNER JOIN dbo.T_Organisms AS Org
       ON AJR.AJR_organism_ID = Org.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_List_Report] TO [DDL_Viewer] AS [dbo]
GO
