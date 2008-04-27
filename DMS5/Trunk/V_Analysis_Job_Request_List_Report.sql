/****** Object:  View [dbo].[V_Analysis_Job_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Request_List_Report
AS
SELECT     AJR.AJR_requestID AS Request, AJR.AJR_requestName AS Name, AJRS.StateName AS State, U.U_Name AS Requestor, AJR.AJR_created AS Created, 
                      AJR.AJR_analysisToolName AS Tool, AJR.AJR_parmFileName AS [Param File], AJR.AJR_settingsFileName AS [Settings File], 
                      Org.OG_name AS Organism, AJR.AJR_organismDBName AS [Organism DB File], AJR.AJR_proteinCollectionList AS ProteinCollectionList, 
                      AJR.AJR_proteinOptionsList AS ProteinOptions, CAST(AJR.AJR_datasets AS char(40)) AS Datasets, AJR.AJR_comment AS Comment, 
                      COUNT(AJ.AJ_jobID) AS Jobs
FROM         dbo.T_Analysis_Job_Request AS AJR INNER JOIN
                      dbo.T_Users AS U ON AJR.AJR_requestor = U.ID INNER JOIN
                      dbo.T_Analysis_Job_Request_State AS AJRS ON AJR.AJR_state = AJRS.ID INNER JOIN
                      dbo.T_Organisms AS Org ON AJR.AJR_organism_ID = Org.Organism_ID LEFT OUTER JOIN
                      dbo.T_Analysis_Job AS AJ ON AJR.AJR_requestID = AJ.AJ_requestID
GROUP BY AJR.AJR_requestID, AJR.AJR_requestName, AJRS.StateName, AJR.AJR_created, AJR.AJR_analysisToolName, Org.OG_name, 
                      CAST(AJR.AJR_datasets AS char(40)), U.U_Name, AJR.AJR_comment, AJR.AJR_parmFileName, AJR.AJR_organismDBName, 
                      AJR.AJR_proteinCollectionList, AJR.AJR_proteinOptionsList, AJR.AJR_settingsFileName

GO
