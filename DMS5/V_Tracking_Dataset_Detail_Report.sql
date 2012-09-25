/****** Object:  View [dbo].[V_Tracking_Dataset_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Tracking_Dataset_Detail_Report AS 
SELECT  T_Dataset.Dataset_Num AS Dataset ,
        T_Instrument_Name.IN_name AS Instrument ,
        DATEPART(MONTH, T_Dataset.Acq_Time_Start) AS Month ,
        DATEPART(DAY, T_Dataset.Acq_Time_Start) AS Day ,
        T_Dataset.Acq_Time_Start AS Start ,
        T_Dataset.Acq_Length_Minutes AS Duration ,
        T_Experiments.Experiment_Num AS Experiment ,
        ISNULL(T_Users.U_Name, '') + ' [' + T_Dataset.DS_Oper_PRN + ']' AS Operator ,
        T_Dataset.DS_comment AS Comment ,
        T_Requested_Run.RDS_EUS_Proposal_ID AS EMSL_Proposal_ID ,
        dbo.GetRequestedRunEUSUsersList(T_Requested_Run.ID, 'I') AS EMSL_Users_List ,
        T_EUS_UsageType.Name AS EMSL_Usage_Type
FROM    T_Dataset
        INNER JOIN T_Experiments ON T_Dataset.Exp_ID = T_Experiments.Exp_ID
        INNER JOIN T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
        INNER JOIN T_Requested_Run ON T_Requested_Run.DatasetID = T_Dataset.Dataset_ID
        INNER JOIN T_EUS_UsageType ON T_Requested_Run.RDS_EUS_UsageType = T_EUS_UsageType.ID
        LEFT OUTER JOIN T_Users ON T_Dataset.DS_Oper_PRN = T_Users.U_PRN 

GO
GRANT VIEW DEFINITION ON [dbo].[V_Tracking_Dataset_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Tracking_Dataset_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
