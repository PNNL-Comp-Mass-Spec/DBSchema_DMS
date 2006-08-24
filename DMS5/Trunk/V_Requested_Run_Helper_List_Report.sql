/****** Object:  View [dbo].[V_Requested_Run_Helper_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Requested_Run_Helper_List_Report
AS
SELECT     dbo.T_Requested_Run.ID AS Request, dbo.T_Requested_Run.RDS_Name AS Name, dbo.T_Experiments.Experiment_Num AS Experiment, 
                      dbo.T_Requested_Run.RDS_instrument_name AS Instrument, dbo.T_Users.U_Name AS Requester, dbo.T_Requested_Run.RDS_created AS Created, 
                      dbo.T_Requested_Run.RDS_WorkPackage AS [Work Package], dbo.T_Requested_Run.RDS_comment AS Comment_____________, 
                      dbo.T_Requested_Run.RDS_note AS Note, dbo.T_DatasetTypeName.DST_name AS Type, dbo.T_Requested_Run.RDS_Well_Plate_Num AS Wellplate, 
                      dbo.T_Requested_Run.RDS_Well_Num AS Well
FROM         dbo.T_DatasetTypeName INNER JOIN
                      dbo.T_Requested_Run ON dbo.T_DatasetTypeName.DST_Type_ID = dbo.T_Requested_Run.RDS_type_ID INNER JOIN
                      dbo.T_Users ON dbo.T_Requested_Run.RDS_Oper_PRN = dbo.T_Users.U_PRN INNER JOIN
                      dbo.T_Experiments ON dbo.T_Requested_Run.Exp_ID = dbo.T_Experiments.Exp_ID
WHERE     (dbo.T_Requested_Run.RDS_BatchID = 0)

GO
