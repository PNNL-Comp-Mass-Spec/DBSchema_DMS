/****** Object:  View [dbo].[V_Run_Tracking_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Run_Tracking_List_Report]
AS
SELECT DS.Dataset_ID AS id,
       DS.Dataset_Num AS dataset,
       DS.Acq_Time_Start AS time_start,
       DS.Acq_Time_End AS time_end,
       DS.Acq_Length_Minutes AS duration,
       DS.Interval_to_Next_DS AS interval,
       dbo.T_Instrument_Name.IN_name AS instrument,
       DSN.DSS_name AS state,
       DRN.DRN_name AS rating,
       'C:' + LC.SC_Column_Number AS lc_column,
       RR.ID AS request,
       RR.RDS_WorkPackage AS work_package,
       RR.RDS_EUS_Proposal_ID AS eus_proposal,
       EUT.Name AS eus_usage,
       C.campaign_id,
       C.CM_Fraction_EMSL_Funded AS fraction_emsl_funded,
       C.CM_EUS_Proposal_List AS campaign_proposals,
       DATEPART(YEAR, DS.Acq_Time_Start) AS year,
       DATEPART(MONTH, DS.Acq_Time_Start) AS month,
       DATEPART(DAY, DS.Acq_Time_Start) AS day,
       CASE WHEN DS.DS_type_ID = 100 THEN 'Tracking' ELSE 'Regular' END AS dataset_type
FROM dbo.T_Dataset AS DS
        INNER JOIN dbo.T_Instrument_Name ON DS.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
        INNER JOIN dbo.T_Experiments AS E ON DS.Exp_ID = E.Exp_ID
        INNER JOIN dbo.T_Campaign AS C ON E.EX_campaign_ID = C.Campaign_ID
        INNER JOIN dbo.T_Dataset_State_Name AS DSN ON DS.DS_state_ID = DSN.Dataset_state_ID
        INNER JOIN dbo.T_Dataset_Rating_Name AS DRN ON DS.DS_rating = DRN.DRN_state_ID
        INNER JOIN dbo.T_LC_Column AS LC ON DS.DS_LC_column_ID = LC.ID
        LEFT OUTER JOIN dbo.T_Requested_Run AS RR ON DS.Dataset_ID = RR.DatasetID
        INNER JOIN dbo.T_EUS_UsageType AS EUT ON RR.RDS_EUS_UsageType = EUT.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Tracking_List_Report] TO [DDL_Viewer] AS [dbo]
GO
