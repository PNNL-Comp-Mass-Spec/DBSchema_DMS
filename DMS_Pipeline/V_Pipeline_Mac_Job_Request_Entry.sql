/****** Object:  View [dbo].[V_Pipeline_Mac_Job_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Pipeline_Mac_Job_Request_Entry
AS
SELECT        ID, Description, Request_Type AS RequestType, Requestor, Data_Package_ID AS DataPackageID, MT_Database AS MTDatabase, Options, Comment, 
                         Scheduled_Job AS ScheduledJob, Scheduling_Notes AS SchedulingNotes, Created
FROM            dbo.T_MAC_Job_Request

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Mac_Job_Request_Entry] TO [DDL_Viewer] AS [dbo]
GO
