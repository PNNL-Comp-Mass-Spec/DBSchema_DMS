/****** Object:  View [dbo].[V_Scheduled_Run_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Scheduled_Run_Export
AS
SELECT     dbo.T_Requested_Run.ID AS Request, dbo.T_Requested_Run.RDS_Name AS Name, dbo.T_Requested_Run.RDS_priority AS Priority, 
                      dbo.T_Requested_Run.RDS_instrument_name AS Instrument, dbo.T_DatasetTypeName.DST_name AS Type, 
                      dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Users.U_Name AS Requester, dbo.T_Requested_Run.RDS_created AS Created, 
                      dbo.T_Requested_Run.RDS_comment AS Comment, dbo.T_Requested_Run.RDS_note AS Note, 
                      dbo.T_Requested_Run.RDS_WorkPackage AS [Work Package], dbo.T_Requested_Run.RDS_Well_Plate_Num AS [Wellplate Number], 
                      dbo.T_Requested_Run.RDS_Well_Num AS [Well Number], dbo.T_Requested_Run.RDS_internal_standard AS [Internal Standard], 
                      dbo.T_Requested_Run.RDS_instrument_setting AS [Instrument Settings], dbo.T_Requested_Run.RDS_special_instructions AS [Special Instructions], 
                      dbo.T_LC_Cart.Cart_Name AS Cart, dbo.T_Requested_Run.RDS_Run_Start AS [Run Start], 
                      dbo.T_Requested_Run.RDS_Run_Finish AS [Run Finish]
FROM         dbo.T_DatasetTypeName INNER JOIN
                      dbo.T_Requested_Run ON dbo.T_DatasetTypeName.DST_Type_ID = dbo.T_Requested_Run.RDS_type_ID INNER JOIN
                      dbo.T_Users ON dbo.T_Requested_Run.RDS_Oper_PRN = dbo.T_Users.U_PRN INNER JOIN
                      dbo.T_Experiments ON dbo.T_Requested_Run.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_LC_Cart ON dbo.T_Requested_Run.RDS_Cart_ID = dbo.T_LC_Cart.ID
WHERE     (dbo.T_Requested_Run.RDS_priority > 0)

GO
