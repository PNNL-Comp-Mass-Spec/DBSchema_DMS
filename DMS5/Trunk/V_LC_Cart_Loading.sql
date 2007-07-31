/****** Object:  View [dbo].[V_LC_Cart_Loading] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Loading
AS
SELECT RR.ID AS Request, '' AS [Sel.], RR.RDS_Name AS [Name], 
       LCCart.Cart_Name AS [LC Cart], RR.RDS_Cart_Col AS [Column], 
       RR.RDS_instrument_name AS Instrument, DSType.DST_Name AS [Run Type],
       RR.RDS_BatchID AS Batch, RR.RDS_Block AS Block, RR.RDS_Run_Order AS [Run Order],
       RR.RDS_comment AS Comment, E.Experiment_Num AS Experiment, RR.RDS_priority AS Priority,
       U.U_Name AS Requester, RR.RDS_created AS Created
FROM dbo.T_Requested_Run RR INNER JOIN 
     dbo.T_Users U ON RR.RDS_Oper_PRN = U.U_PRN INNER JOIN 
     dbo.T_Experiments E ON RR.Exp_ID = E.Exp_ID INNER JOIN 
     dbo.T_LC_Cart LCCart ON RR.RDS_Cart_ID = LCCart.ID INNER JOIN 
     dbo.T_DatasetTypeName DSType ON RR.RDS_type_ID = DSType.DST_Type_ID
GO
