/****** Object:  View [dbo].[V_DEPkgr_Analysis_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_Analysis_Request
AS
SELECT     dbo.T_Analysis_Job_Request.AJR_requestID AS Request_ID, dbo.T_Analysis_Job_Request.AJR_requestName AS Request_Name, 
                      dbo.T_Analysis_Job_Request.AJR_created AS Created, dbo.T_Analysis_Job_Request.AJR_analysisToolName AS Analysis_Tool, 
                      dbo.T_Analysis_Job_Request_State.StateName AS State, dbo.T_Analysis_Job_Request.AJR_datasets AS Dataset_List
FROM         dbo.T_Analysis_Job_Request INNER JOIN
                      dbo.T_Analysis_Job_Request_State ON dbo.T_Analysis_Job_Request.AJR_state = dbo.T_Analysis_Job_Request_State.ID

GO
