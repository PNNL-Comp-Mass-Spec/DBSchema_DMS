/****** Object:  View [dbo].[V_LC_Cart_Loading] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Loading
AS
SELECT     dbo.T_Requested_Run.ID AS Request, '' AS [Sel.], dbo.T_Requested_Run.RDS_Name AS Name, dbo.T_LC_Cart.Cart_Name AS [LC Cart], 
                      dbo.T_Requested_Run.RDS_Cart_Col AS [Column], dbo.T_Requested_Run.RDS_instrument_name AS Instrument, 
                      dbo.T_Requested_Run.RDS_BatchID AS Batch, dbo.T_Requested_Run.RDS_Block AS Block, dbo.T_Requested_Run.RDS_Run_Order AS [Run Order], 
                      dbo.T_Requested_Run.RDS_comment AS Comment, dbo.T_Experiments.Experiment_Num AS Experiment, 
                      dbo.T_Requested_Run.RDS_priority AS Priority, dbo.T_Users.U_Name AS Requester, dbo.T_Requested_Run.RDS_created AS Created
FROM         dbo.T_Requested_Run INNER JOIN
                      dbo.T_Users ON dbo.T_Requested_Run.RDS_Oper_PRN = dbo.T_Users.U_PRN INNER JOIN
                      dbo.T_Experiments ON dbo.T_Requested_Run.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_LC_Cart ON dbo.T_Requested_Run.RDS_Cart_ID = dbo.T_LC_Cart.ID

GO
