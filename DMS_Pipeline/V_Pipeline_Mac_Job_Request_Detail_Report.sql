/****** Object:  View [dbo].[V_Pipeline_Mac_Job_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Pipeline_Mac_Job_Request_Detail_Report
AS
SELECT        ID, Description, Request_Type AS [Request Type], Requestor, Data_Package_ID AS [Data Package ID], MT_Database AS [MT Database], Options, Comment, 
                         Scheduling_Notes, Scheduled_Job, Created
FROM            dbo.T_MAC_Job_Request

GO
