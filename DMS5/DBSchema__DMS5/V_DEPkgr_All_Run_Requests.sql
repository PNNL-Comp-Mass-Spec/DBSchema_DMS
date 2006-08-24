/****** Object:  View [dbo].[V_DEPkgr_All_Run_Requests] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_All_Run_Requests
AS
SELECT     Request_ID, Request_Name, Created_Date, Requested_Instrument, Experiment_ID, Dataset_ID, Completed
FROM         dbo.V_DEPkgr_Pending_Run_Requests
UNION
SELECT     Request_ID, Request_Name, Created_Date, Requested_Instrument, Experiment_ID, Dataset_ID, Completed
FROM         dbo.V_DEPkgr_Completed_Run_Requests

GO
