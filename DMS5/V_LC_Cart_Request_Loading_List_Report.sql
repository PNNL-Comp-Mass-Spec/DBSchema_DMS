/****** Object:  View [dbo].[V_LC_Cart_Request_Loading_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Request_Loading_List_Report]
AS
SELECT RR.RDS_BatchID AS batch_id,
       RRB.locked,
       RR.ID AS request,
       RR.RDS_Name AS name,
       RR.RDS_Status AS status,
       RR.RDS_instrument_group AS instrument,
       RR.RDS_Sec_Sep AS separation_type,
       E.Experiment_Num AS experiment,
       RR.RDS_Block AS block,
       LCCart.Cart_Name AS cart,
       CartConfig.Cart_Config_Name AS cart_config,
	   RR.RDS_Cart_Col AS col
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
