/****** Object:  View [dbo].[V_Tracking_Dataset_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Tracking_Dataset_Entry]
AS
SELECT DS.Dataset_Num AS dataset,
       E.Experiment_Num AS experiment,
       DS.DS_Oper_PRN AS oper_prn,
       InstName.IN_name AS instrument_name,
       DS.Acq_Time_Start AS run_start,
       DS.Acq_Length_Minutes AS run_duration,
       DS.DS_comment AS [comment],
       EUT.Name AS eus_usage_type,
       RR.RDS_EUS_Proposal_ID AS eus_proposal_id,
       dbo.GetRequestedRunEUSUsersList(RR.ID, 'I') AS eus_users_list
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
