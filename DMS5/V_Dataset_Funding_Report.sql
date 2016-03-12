/****** Object:  View [dbo].[V_Dataset_Funding_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Dataset_Funding_Report]
AS
SELECT DS.Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
       InstName.IN_name AS Instrument,
       Exp.Experiment_Num AS Experiment,
       ISNULL(DS.Acq_Time_Start, RR.RDS_Run_Start) AS Run_Start,
       ISNULL(DS.Acq_Time_End, RR.RDS_Run_Finish) AS Run_Finish,
       DS.Acq_Length_Minutes AS [Acq Length],
       -- DATEDIFF(MINUTE, ISNULL(DS.Acq_Time_Start, RR.RDS_Run_Start), ISNULL(DS.Acq_Time_End, RR.RDS_Run_Finish)) AS [Acq Length],
       C.Campaign_Num AS Campaign,
       DSN.DSS_name AS State,
       DS.DS_created AS Created,
       DSRating.DRN_name AS Rating,
       RR.ID AS Request,
       RR.RDS_Oper_PRN AS Requester,
       RR.RDS_EUS_Proposal_ID AS [EMSL Proposal],
       RR.RDS_WorkPackage AS [Work Package],
       SPR.Work_Package_Number AS [SamplePrep Work Package],
       dbo.GetProposalEUSUsersList(RR.RDS_EUS_Proposal_ID, 'N') AS EMSL_Users,
       dbo.GetProposalEUSUsersList(RR.RDS_EUS_Proposal_ID, 'I') AS EMSL_UserIDs,
       DTN.DST_name AS [Dataset Type],
       DS.DS_Oper_PRN AS Operator,
       DS.Scan_Count AS [Scan Count],
       DS.DS_sec_sep AS [Separation Type],
       DS.DS_comment AS [Comment],
       Case When C.CM_Fraction_EMSL_Funded > 0 THEN CM_Fraction_EMSL_Funded
            WHEN SPR.Work_Package_Number LIKE 'K798%' OR RR.RDS_WorkPackage LIKE 'K798%' THEN 1 
            Else 0 
       End AS Fraction_EMSL_Funded,
       CASE WHEN ISNULL(DS.Acq_Time_Start, RR.RDS_Run_Start) < 2000 
                 THEN YEAR(DATEADD(DAY, 92, DS_Created))
            ELSE YEAR(DATEADD(DAY, 92, ISNULL(ISNULL(DS.Acq_Time_Start, RR.RDS_Run_Start), DS_Created))) 
       END AS FY,
       InstName.IN_operations_role AS Instrument_Ops_Role,
       InstName.IN_class AS Instrument_Class
FROM T_Sample_Prep_Request SPR RIGHT OUTER JOIN
    T_DatasetStateName DSN INNER JOIN
    T_Dataset DS ON DSN.Dataset_state_ID = DS.DS_state_ID INNER JOIN
    T_DatasetTypeName DTN ON DS.DS_type_ID = DTN.DST_Type_ID INNER JOIN
    T_Instrument_Name InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID INNER JOIN
    T_DatasetRatingName DSRating ON DS.DS_rating = DSRating.DRN_state_ID INNER JOIN
    T_Experiments Exp ON DS.Exp_ID = Exp.Exp_ID INNER JOIN
    T_Campaign C ON Exp.EX_campaign_ID = C.Campaign_ID ON 
    SPR.ID = Exp.EX_sample_prep_request_ID LEFT OUTER JOIN
    T_Requested_Run RR ON DS.Dataset_ID = RR.DatasetID
WHERE (DS.DS_rating > 0) AND (DS.DS_state_ID = 3)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Funding_Report] TO [PNL\D3M578] AS [dbo]
GO
