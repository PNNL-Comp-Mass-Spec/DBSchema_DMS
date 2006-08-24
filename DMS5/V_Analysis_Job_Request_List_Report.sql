/****** Object:  View [dbo].[V_Analysis_Job_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Request_List_Report
AS
SELECT     dbo.T_Analysis_Job_Request.AJR_requestID AS Request, dbo.T_Analysis_Job_Request.AJR_requestName AS Name, 
                      dbo.T_Analysis_Job_Request_State.StateName AS State, dbo.T_Users.U_Name AS Requestor, dbo.T_Analysis_Job_Request.AJR_created AS Created, 
                      dbo.T_Analysis_Job_Request.AJR_analysisToolName AS Tool, dbo.T_Analysis_Job_Request.AJR_parmFileName AS [Param File], 
                      dbo.T_Analysis_Job_Request.AJR_organismName AS Organism, dbo.T_Analysis_Job_Request.AJR_organismDBName AS [Organism DB File], 
                      dbo.T_Analysis_Job_Request.AJR_proteinCollectionList AS ProteinCollectionList, 
                      dbo.T_Analysis_Job_Request.AJR_proteinOptionsList AS ProteinOptions, CAST(dbo.T_Analysis_Job_Request.AJR_datasets AS char(40)) AS Datasets, 
                      dbo.T_Analysis_Job_Request.AJR_comment AS Comment, COUNT(dbo.T_Analysis_Job.AJ_jobID) AS Jobs
FROM         dbo.T_Analysis_Job_Request INNER JOIN
                      dbo.T_Users ON dbo.T_Analysis_Job_Request.AJR_requestor = dbo.T_Users.ID INNER JOIN
                      dbo.T_Analysis_Job_Request_State ON dbo.T_Analysis_Job_Request.AJR_state = dbo.T_Analysis_Job_Request_State.ID LEFT OUTER JOIN
                      dbo.T_Analysis_Job ON dbo.T_Analysis_Job_Request.AJR_requestID = dbo.T_Analysis_Job.AJ_requestID
GROUP BY dbo.T_Analysis_Job_Request.AJR_requestID, dbo.T_Analysis_Job_Request.AJR_requestName, dbo.T_Analysis_Job_Request_State.StateName, 
                      dbo.T_Analysis_Job_Request.AJR_created, dbo.T_Analysis_Job_Request.AJR_analysisToolName, dbo.T_Analysis_Job_Request.AJR_organismName, 
                      CAST(dbo.T_Analysis_Job_Request.AJR_datasets AS char(40)), dbo.T_Users.U_Name, dbo.T_Analysis_Job_Request.AJR_comment, 
                      dbo.T_Analysis_Job_Request.AJR_parmFileName, dbo.T_Analysis_Job_Request.AJR_organismDBName, 
                      dbo.T_Analysis_Job_Request.AJR_proteinCollectionList, dbo.T_Analysis_Job_Request.AJR_proteinOptionsList


GO
