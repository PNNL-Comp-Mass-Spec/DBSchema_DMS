/****** Object:  View [dbo].[V_Analysis_Job_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Request_Entry] as 
SELECT AJR.AJR_requestID,
       AJR.AJR_requestName,
       AJR.AJR_created,
       AJR.AJR_analysisToolName,
       AJR.AJR_parmFileName,
       AJR.AJR_settingsFileName,
       AJR.AJR_organismDBName,
       Org.OG_name AS AJR_organismName,
       Case When IsNull(Data_Package_ID, 0) > 0 Then '' 
            Else dbo.GetJobRequestDatasetNameList(AJR.AJR_requestID) 
       End As AJR_datasets,
       AJR.Data_Package_ID,
       AJR.AJR_comment,
       AJR.AJR_specialProcessing,
       ARS.StateName AS State,
       U.U_PRN AS requestor,
       AJR.AJR_proteinCollectionList AS protCollNameList,
       AJR.AJR_proteinOptionsList AS protCollOptionsList
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
