/****** Object:  View [dbo].[V_Tracking_Dataset_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Tracking_Dataset_Detail_Report] AS 
SELECT DS.Dataset_Num AS Dataset,
       InstName.IN_name AS Instrument,
       DATEPART(month, DS.Acq_Time_Start) AS [Month],
       DATEPART(day, DS.Acq_Time_Start) AS [Day],
       DS.Acq_Time_Start AS Start,
       DS.Acq_Length_Minutes AS Duration,
       E.Experiment_Num AS Experiment,
       U.Name_with_PRN AS Operator,
       DS.DS_comment AS [Comment],
       EUT.Name AS [EMSL Usage Type],
       RR.RDS_EUS_Proposal_ID AS [EMSL Proposal ID],
       dbo.GetRequestedRunEUSUsersList(RR.ID, 'I') AS [EMSL Users List]
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
