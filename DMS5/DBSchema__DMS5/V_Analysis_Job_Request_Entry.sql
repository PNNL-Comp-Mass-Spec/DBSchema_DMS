/****** Object:  View [dbo].[V_Analysis_Job_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Request_Entry
AS
SELECT     dbo.T_Analysis_Job_Request.AJR_requestID, dbo.T_Analysis_Job_Request.AJR_requestName, dbo.T_Analysis_Job_Request.AJR_created, 
                      dbo.T_Analysis_Job_Request.AJR_analysisToolName, dbo.T_Analysis_Job_Request.AJR_parmFileName, 
                      dbo.T_Analysis_Job_Request.AJR_settingsFileName, dbo.T_Analysis_Job_Request.AJR_organismDBName, 
                      dbo.T_Analysis_Job_Request.AJR_organismName, dbo.T_Analysis_Job_Request.AJR_datasets, dbo.T_Analysis_Job_Request.AJR_comment, 
                      dbo.T_Analysis_Job_Request_State.StateName AS State, dbo.T_Users.U_PRN AS requestor, 
                      dbo.T_Analysis_Job_Request.AJR_proteinCollectionList AS protCollNameList, 
                      dbo.T_Analysis_Job_Request.AJR_proteinOptionsList AS protCollOptionsList
FROM         dbo.T_Analysis_Job_Request INNER JOIN
                      dbo.T_Analysis_Job_Request_State ON dbo.T_Analysis_Job_Request.AJR_state = dbo.T_Analysis_Job_Request_State.ID INNER JOIN
                      dbo.T_Users ON dbo.T_Analysis_Job_Request.AJR_requestor = dbo.T_Users.ID


GO
