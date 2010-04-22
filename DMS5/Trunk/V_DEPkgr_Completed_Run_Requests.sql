/****** Object:  View [dbo].[V_DEPkgr_Completed_Run_Requests] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_Completed_Run_Requests
AS
SELECT     ID AS Request_ID, RDS_Name AS Request_Name, RDS_created AS Created_Date, RDS_instrument_name AS Requested_Instrument, 
                      Exp_ID AS Experiment_ID, DatasetID AS Dataset_ID, 'Completed' AS Completed
FROM         dbo.T_Requested_Run
WHERE     (NOT (DatasetID IS NULL))

GO
GRANT VIEW DEFINITION ON [dbo].[V_DEPkgr_Completed_Run_Requests] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_DEPkgr_Completed_Run_Requests] TO [PNL\D3M580] AS [dbo]
GO
