/****** Object:  View [dbo].[V_LC_Cart_Request_Loading_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_LC_Cart_Request_Loading_List_Report
as
SELECT        T_Requested_Run.RDS_BatchID AS BatchID, T_Requested_Run_Batches.Locked, T_Requested_Run.ID AS Request, T_Requested_Run.RDS_Name AS Name, 
                         T_Requested_Run.RDS_Status AS Status, T_Requested_Run.RDS_instrument_name AS Instrument, T_Requested_Run.RDS_Sec_Sep AS Separation_Type, 
                         T_Experiments.Experiment_Num AS Experiment, T_Requested_Run.RDS_Block AS Block, T_LC_Cart.Cart_Name AS Cart, 
                         T_Requested_Run.RDS_Cart_Col AS Col
FROM            T_Requested_Run INNER JOIN
                         T_LC_Cart ON T_Requested_Run.RDS_Cart_ID = T_LC_Cart.ID INNER JOIN
                         T_Requested_Run_Batches ON T_Requested_Run.RDS_BatchID = T_Requested_Run_Batches.ID INNER JOIN
                         T_Experiments ON T_Requested_Run.Exp_ID = T_Experiments.Exp_ID
WHERE        (T_Requested_Run.RDS_Status = 'Active')
GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Request_Loading_List_Report] TO [DDL_Viewer] AS [dbo]
GO
