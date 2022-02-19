/****** Object:  View [dbo].[V_Tracking_Dataset_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Tracking_Dataset_Entry] AS 
SELECT DS.Dataset_Num AS datasetNum,
       E.Experiment_Num AS experimentNum,
       DS.DS_Oper_PRN AS operPRN,
       InstName.IN_name AS instrumentName,
       DS.Acq_Time_Start AS runStart,
       DS.Acq_Length_Minutes AS runDuration,
       DS.DS_comment AS [comment],
       EUT.Name AS eusUsageType,
       RR.RDS_EUS_Proposal_ID AS eusProposalID,
       dbo.GetRequestedRunEUSUsersList(RR.ID, 'I') AS eusUsersList
FROM T_Dataset DS
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Requested_Run RR
       ON RR.DatasetID = DS.Dataset_ID
     INNER JOIN T_EUS_UsageType EUT
       ON RR.RDS_EUS_UsageType = EUT.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Tracking_Dataset_Entry] TO [DDL_Viewer] AS [dbo]
GO
