/****** Object:  View [dbo].[V_Analysis_Job_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Request_Detail_Report
AS
SELECT     dbo.T_Analysis_Job_Request.AJR_requestID AS Request, dbo.T_Analysis_Job_Request.AJR_requestName AS Name, 
                      dbo.T_Analysis_Job_Request.AJR_created AS Created, dbo.T_Analysis_Job_Request.AJR_analysisToolName AS Tool, 
                      dbo.T_Analysis_Job_Request.AJR_parmFileName AS [Parameter File], dbo.T_Analysis_Job_Request.AJR_settingsFileName AS [Settings File], 
                      dbo.T_Analysis_Job_Request.AJR_organismName AS Organism, dbo.T_Analysis_Job_Request.AJR_organismDBName AS [Organism DB], 
                      dbo.T_Analysis_Job_Request.AJR_proteinCollectionList AS [Protein Collection List], 
                      dbo.T_Analysis_Job_Request.AJR_proteinOptionsList AS [Protein Options], dbo.T_Analysis_Job_Request.AJR_datasets AS Datasets, 
                      dbo.T_Analysis_Job_Request.AJR_comment AS Comment, dbo.T_Users.U_Name AS [Requestor Name], dbo.T_Users.U_PRN AS Requestor, 
                      dbo.T_Analysis_Job_Request_State.StateName AS State, dbo.GetRunRequestInstrList(dbo.T_Analysis_Job_Request.AJR_requestID) AS Instruments, 
                      dbo.GetRunRequestExistingJobList(dbo.T_Analysis_Job_Request.AJR_requestID) AS [Pre-existing Jobs]
FROM         dbo.T_Analysis_Job_Request INNER JOIN
                      dbo.T_Users ON dbo.T_Analysis_Job_Request.AJR_requestor = dbo.T_Users.ID INNER JOIN
                      dbo.T_Analysis_Job_Request_State ON dbo.T_Analysis_Job_Request.AJR_state = dbo.T_Analysis_Job_Request_State.ID


GO
