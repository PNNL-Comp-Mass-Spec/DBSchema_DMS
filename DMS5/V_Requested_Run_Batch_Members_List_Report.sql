/****** Object:  View [dbo].[V_Requested_Run_Batch_Members_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Requested_Run_Batch_Members_List_Report
AS
SELECT     dbo.T_Requested_Run.ID AS Request, dbo.T_Requested_Run.RDS_Name AS Name, dbo.T_Requested_Run_Batches.Batch, 
                      dbo.T_Requested_Run.RDS_Blocking_Factor AS [Blocking Factor], dbo.T_Requested_Run.RDS_Block AS Block, 
                      dbo.T_Requested_Run.RDS_Run_Order AS [Run Order], dbo.T_Experiments.Experiment_Num AS Experiment, 
                      dbo.T_Requested_Run.RDS_instrument_name AS Instrument, dbo.T_Users.U_Name AS Requestor, dbo.T_Requested_Run.RDS_created AS Created, 
                      dbo.T_Requested_Run.RDS_priority AS Pri, dbo.T_Requested_Run.RDS_comment AS Comment_____________, 
                      dbo.T_Requested_Run.RDS_Well_Plate_Num AS Wellplate, dbo.T_Requested_Run.RDS_Well_Num AS Well, 
                      dbo.T_Requested_Run.RDS_BatchID AS [#BatchID]
FROM         dbo.T_Requested_Run INNER JOIN
                      dbo.T_Experiments ON dbo.T_Requested_Run.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Requested_Run_Batches ON dbo.T_Requested_Run.RDS_BatchID = dbo.T_Requested_Run_Batches.ID INNER JOIN
                      dbo.T_Users ON dbo.T_Experiments.EX_researcher_PRN = dbo.T_Users.U_PRN

GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Members_List_Report] TO [PNL\D3M578] AS [dbo]
GO
