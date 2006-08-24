/****** Object:  View [dbo].[V_DEPkgr_Pending_Run_Requests] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_Pending_Run_Requests
AS
SELECT     ID AS Request_ID, RDS_Name AS Request_Name, RDS_created AS Created_Date, RDS_instrument_name AS Requested_Instrument, 
                      Exp_ID AS Experiment_ID, 0 AS Dataset_ID, 
                      CASE WHEN RDS_priority = 0 THEN 'Pending' WHEN RDS_priority > 0 THEN 'Scheduled' END AS Completed
FROM         dbo.T_Requested_Run

GO
