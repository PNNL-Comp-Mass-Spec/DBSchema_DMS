/****** Object:  View [dbo].[V_Tracking_Dataset_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Tracking_Dataset_Detail_Report]
AS
SELECT DS.Dataset_Num AS dataset,
       InstName.IN_name AS instrument,
       DATEPART(month, DS.Acq_Time_Start) AS month,
       DATEPART(day, DS.Acq_Time_Start) AS day,
       DS.Acq_Time_Start AS start,
       DS.Acq_Length_Minutes AS duration,
       E.Experiment_Num AS experiment,
       U.Name_with_PRN AS operator,
       DS.DS_comment AS comment,
       EUT.Name AS emsl_usage_type,
       RR.RDS_EUS_Proposal_ID AS emsl_proposal_id,
       dbo.GetRequestedRunEUSUsersList(RR.id, 'I') AS emsl_users_list
FROM T_Dataset DS
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Requested_Run RR
       ON RR.DatasetID = DS.Dataset_ID
     INNER JOIN T_EUS_UsageType EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     LEFT OUTER JOIN T_Users U
       ON DS.DS_Oper_PRN = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Tracking_Dataset_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
