/****** Object:  View [dbo].[V_Dataset_Funding_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Dataset_Funding_Report]
AS
SELECT DS.Dataset_ID AS id,
       DS.Dataset_Num AS dataset,
       InstName.IN_name AS instrument,
       Exp.Experiment_Num AS experiment,
       DS.Acq_Time_Start AS run_start,
       DS.Acq_Time_End AS run_finish,
       DS.Acq_Length_Minutes AS acq_length,
       C.Campaign_Num AS campaign,
       DSN.DSS_name AS state,
       DS.DS_created AS created,
       DSRating.DRN_name AS rating,
       RR.ID AS request,
       RR.RDS_Requestor_PRN AS requester,
       RR.RDS_EUS_Proposal_ID AS emsl_proposal,
       RR.RDS_WorkPackage AS work_package,
       SPR.Work_Package_Number AS sample_prep_work_package,
       dbo.get_proposal_eus_users_list(RR.rds_eus_proposal_id, 'N', 5) AS emsl_users,
       dbo.get_proposal_eus_users_list(RR.rds_eus_proposal_id, 'I', 20) AS emsl_user_ids,
       DTN.DST_name AS dataset_type,
       DS.DS_Oper_PRN AS operator,
       DS.Scan_Count AS scan_count,
       DS.DS_sec_sep AS separation_type,
       DS.DS_comment AS comment,
       Case When C.CM_Fraction_EMSL_Funded > 0 THEN CM_Fraction_EMSL_Funded
            WHEN SPR.Work_Package_Number LIKE 'K798%' OR RR.RDS_WorkPackage LIKE 'K798%' THEN 1
            Else 0
       End AS fraction_emsl_funded,
       CASE WHEN DS.Acq_Time_Start < 2000
            THEN YEAR(DATEADD(DAY, 92, DS_Created))
            ELSE YEAR(DATEADD(DAY, 92, ISNULL(DS.acq_time_start, DS_Created)))
       END AS fy,
       InstName.IN_operations_role AS instrument_ops_role,
       InstName.IN_class AS instrument_class
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
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Funding_Report] TO [DDL_Viewer] AS [dbo]
GO
