/****** Object:  View [dbo].[V_Tracking_Dataset_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Tracking_Dataset_Entry AS 
SELECT  T_Dataset.Dataset_Num AS datasetNum ,
        T_Experiments.Experiment_Num AS experimentNum ,
        T_Dataset.DS_Oper_PRN AS operPRN ,
        T_Instrument_Name.IN_name AS instrumentName ,
        T_Dataset.Acq_Time_Start AS runStart ,
        T_Dataset.Acq_Length_Minutes AS runDuration ,
        T_Dataset.DS_comment AS comment ,
        T_Requested_Run.RDS_EUS_Proposal_ID AS eusProposalID ,
        dbo.GetRequestedRunEUSUsersList(T_Requested_Run.ID, 'I') AS eusUsersList ,
        T_EUS_UsageType.Name AS eusUsageType
FROM    T_Dataset
        INNER JOIN T_Experiments ON T_Dataset.Exp_ID = T_Experiments.Exp_ID
        INNER JOIN T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
        INNER JOIN T_Requested_Run ON T_Requested_Run.DatasetID = T_Dataset.Dataset_ID
        INNER JOIN T_EUS_UsageType ON T_Requested_Run.RDS_EUS_UsageType = T_EUS_UsageType.ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Tracking_Dataset_Entry] TO [PNL\D3M578] AS [dbo]
GO
