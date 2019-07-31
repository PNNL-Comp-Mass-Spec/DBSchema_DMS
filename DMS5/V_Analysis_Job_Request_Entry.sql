/****** Object:  View [dbo].[V_Analysis_Job_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Request_Entry] as 
SELECT AR.AJR_requestID,
       AR.AJR_requestName,
       AR.AJR_created,
       AR.AJR_analysisToolName,
       AR.AJR_parmFileName,
       AR.AJR_settingsFileName,
       AR.AJR_organismDBName,
       Org.OG_name AS AJR_organismName,
       dbo.GetRunRequestDatasetNameList(AR.AJR_requestID) As AJR_datasets,
       AR.AJR_comment,
       AR.AJR_specialProcessing,
       ARS.StateName AS State,
       U.U_PRN AS requestor,
       AR.AJR_proteinCollectionList AS protCollNameList,
       AR.AJR_proteinOptionsList AS protCollOptionsList,
       'No' AS adminReviewReqd
FROM T_Analysis_Job_Request AS AR
     INNER JOIN T_Analysis_Job_Request_State AS ARS
       ON AR.AJR_state = ARS.ID
     INNER JOIN T_Users AS U
       ON AR.AJR_requestor = U.ID
     INNER JOIN T_Organisms AS Org
       ON AR.AJR_organism_ID = Org.Organism_ID     

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_Entry] TO [DDL_Viewer] AS [dbo]
GO
