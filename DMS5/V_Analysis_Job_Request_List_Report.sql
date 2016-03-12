/****** Object:  View [dbo].[V_Analysis_Job_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Analysis_Job_Request_List_Report]
AS
SELECT AJR.AJR_requestID AS Request,
       AJR.AJR_requestName AS Name,
       AJRS.StateName AS State,
       U.U_Name AS Requestor,
       AJR.AJR_created AS Created,
       AJR.AJR_analysisToolName AS Tool,
       AJR.AJR_jobCount AS Jobs,
       AJR.AJR_parmFileName AS [Param File],
       AJR.AJR_settingsFileName AS [Settings File],
       Org.OG_name AS Organism,
       AJR.AJR_organismDBName AS [Organism DB File],
       AJR.AJR_proteinCollectionList AS ProteinCollectionList,
       AJR.AJR_proteinOptionsList AS ProteinOptions,
       CAST(AJR.AJR_datasets AS char(40)) AS Datasets,
       AJR.AJR_comment AS Comment
FROM dbo.T_Analysis_Job_Request AS AJR
     INNER JOIN dbo.T_Users AS U
       ON AJR.AJR_requestor = U.ID
     INNER JOIN dbo.T_Analysis_Job_Request_State AS AJRS
       ON AJR.AJR_state = AJRS.ID
     INNER JOIN dbo.T_Organisms AS Org
       ON AJR.AJR_organism_ID = Org.Organism_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_List_Report] TO [PNL\D3M578] AS [dbo]
GO
