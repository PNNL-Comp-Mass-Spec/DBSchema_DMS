/****** Object:  View [dbo].[V_LC_Cart_Request_Loading_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Request_Loading_List_Report]
AS
SELECT RR.RDS_BatchID AS BatchID,
       RRB.Locked,
       RR.ID AS Request,
       RR.RDS_Name AS [Name],
       RR.RDS_Status AS [Status],
       RR.RDS_instrument_group AS Instrument,
       RR.RDS_Sec_Sep AS Separation_Type,
       E.Experiment_Num AS Experiment,
       RR.RDS_Block AS [Block],
       LCCart.Cart_Name AS Cart,       
       CartConfig.Cart_Config_Name AS Cart_Config,
	   RR.RDS_Cart_Col AS Col
FROM T_Requested_Run RR
     INNER JOIN T_LC_Cart LCCart
       ON RR.RDS_Cart_ID = LCCart.ID
     INNER JOIN T_Requested_Run_Batches RRB
       ON RR.RDS_BatchID = RRB.ID
     INNER JOIN T_Experiments E
       ON RR.Exp_ID = E.Exp_ID
     LEFT OUTER JOIN T_LC_Cart_Configuration CartConfig
       ON RR.RDS_Cart_Config_ID = CartConfig.Cart_Config_ID
WHERE (RR.RDS_Status = 'Active')


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Request_Loading_List_Report] TO [DDL_Viewer] AS [dbo]
GO
