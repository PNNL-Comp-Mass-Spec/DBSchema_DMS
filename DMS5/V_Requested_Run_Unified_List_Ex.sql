/****** Object:  View [dbo].[V_Requested_Run_Unified_List_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Requested_Run_Unified_List_Ex]  as
SELECT  T_Requested_Run.ID AS Request ,
        T_Requested_Run.RDS_Name AS Name ,
        T_Requested_Run.RDS_Status AS Status ,
        T_Requested_Run.RDS_BatchID AS Batch ,
        T_Experiments.Experiment_Num AS Experiment ,
        T_Requested_Run.Exp_ID AS Experiment_ID ,
        T_Requested_Run.RDS_instrument_name AS Instrument ,
        T_Dataset.Dataset_Num AS Dataset ,
        T_Requested_Run.DatasetID AS Dataset_ID ,
        T_Requested_Run.RDS_Block AS Block ,
        T_Requested_Run.RDS_Run_Order AS Run_Order ,
        T_LC_Cart.Cart_Name AS Cart ,
        T_Requested_Run.RDS_Cart_Col AS LC_Col
FROM    T_LC_Cart
        INNER JOIN T_Requested_Run
        INNER JOIN T_Experiments ON T_Requested_Run.Exp_ID = T_Experiments.Exp_ID ON T_LC_Cart.ID = T_Requested_Run.RDS_Cart_ID
        LEFT OUTER JOIN T_Dataset ON T_Requested_Run.DatasetID = T_Dataset.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Unified_List_Ex] TO [DDL_Viewer] AS [dbo]
GO
