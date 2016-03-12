/****** Object:  View [dbo].[V_Instrument_Actual_Montly_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Instrument_Actual_Montly_List_Report] as
SELECT UsageQ.[Year],
       UsageQ.[Month],
       ISNULL(UsageQ.Proposal_ID, 0) AS Proposal_ID,
       ISNULL(CONVERT(varchar(32), T_EUS_Proposals.Title) + '...', '-No Proposal-') AS Title,
       T_EUS_Proposal_State_Name.Name AS Status,
       UsageQ.FT_Actual + UsageQ.IMS_Actual + UsageQ.ORB_Actual + UsageQ.EXA_Actual + UsageQ.LTQ_Actual + UsageQ.GC_Actual + UsageQ.QQQ_Actual AS Total_Actual,
       UsageQ.FT_Actual, UsageQ.IMS_Actual, UsageQ.ORB_Actual, UsageQ.EXA_Actual, UsageQ.LTQ_Actual, UsageQ.GC_Actual, UsageQ.QQQ_Actual,
       UsageQ.Campaigns, UsageQ.Campaign_First, UsageQ.Campaign_Last,
       UsageQ.FT_EMSL_Actual + UsageQ.IMS_EMSL_Actual + UsageQ.ORB_EMSL_Actual + UsageQ.EXA_EMSL_Actual + UsageQ.LTQ_EMSL_Actual + UsageQ.GC_EMSL_Actual + UsageQ.QQQ_EMSL_Actual AS Total_EMSL_Actual,
       UsageQ.FT_EMSL_Actual, UsageQ.IMS_EMSL_Actual, UsageQ.ORB_EMSL_Actual, UsageQ.EXA_EMSL_Actual, UsageQ.LTQ_EMSL_Actual, UsageQ.GC_EMSL_Actual, UsageQ.QQQ_EMSL_Actual
FROM T_EUS_Proposal_State_Name
     INNER JOIN T_EUS_Proposals
       ON T_EUS_Proposal_State_Name.ID = T_EUS_Proposals.State_ID
     RIGHT OUTER JOIN (
               SELECT YEAR(TD.Acq_Time_Start) AS [Year],
                      MONTH(TD.Acq_Time_Start) AS [Month],
                      TRR.RDS_EUS_Proposal_ID AS Proposal_ID,
                      COUNT(DISTINCT C.Campaign_Num) AS Campaigns,
                      MIN(C.Campaign_Num) AS Campaign_First,
                      MAX(C.Campaign_Num) AS Campaign_Last,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'FT' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS FT_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'IMS' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS IMS_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'ORB' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS ORB_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'EXA' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS EXA_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'LTQ' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS LTQ_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'GC' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS GC_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'QQQ' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS QQQ_Actual,
                      
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'FT' THEN TD.Acq_Length_Minutes * C.CM_Fraction_EMSL_Funded ELSE 0 END) / 60.0) AS FT_EMSL_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'IMS' THEN TD.Acq_Length_Minutes * C.CM_Fraction_EMSL_Funded ELSE 0 END) / 60.0) AS IMS_EMSL_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'ORB' THEN TD.Acq_Length_Minutes * C.CM_Fraction_EMSL_Funded ELSE 0 END) / 60.0) AS ORB_EMSL_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'EXA' THEN TD.Acq_Length_Minutes * C.CM_Fraction_EMSL_Funded ELSE 0 END) / 60.0) AS EXA_EMSL_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'LTQ' THEN TD.Acq_Length_Minutes * C.CM_Fraction_EMSL_Funded ELSE 0 END) / 60.0) AS LTQ_EMSL_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'GC' THEN TD.Acq_Length_Minutes * C.CM_Fraction_EMSL_Funded ELSE 0 END) / 60.0) AS GC_EMSL_Actual,
                      CONVERT(decimal(10, 1), SUM( CASE WHEN InstGroup.Allocation_Tag = 'QQQ' THEN TD.Acq_Length_Minutes * C.CM_Fraction_EMSL_Funded ELSE 0 END) / 60.0) AS QQQ_EMSL_Actual                      
                      
               FROM T_Dataset AS TD
                    INNER JOIN T_Requested_Run AS TRR
                      ON TD.Dataset_ID = TRR.DatasetID
                    INNER JOIN T_Instrument_Name AS TIN
                      ON TIN.Instrument_ID = TD.DS_instrument_name_ID
                    INNER JOIN T_Instrument_Group InstGroup
                      ON TIN.IN_Group = InstGroup.IN_Group
                    INNER JOIN T_Experiments E 
                      ON TD.Exp_ID = E.Exp_ID 
                    INNER JOIN T_Campaign C 
                      ON E.EX_campaign_ID = C.Campaign_ID
               WHERE (TD.DS_rating > 1) AND
                     (TRR.RDS_EUS_UsageType NOT IN (10, 12, 13)) AND
                     (TD.DS_state_ID = 3) AND                     
                     TIN.IN_operations_role NOT IN ('Offsite', 'InSilico')
               GROUP BY YEAR(TD.Acq_Time_Start),
                        MONTH(TD.Acq_Time_Start),
                        TRR.RDS_EUS_Proposal_ID
     ) UsageQ
       ON T_EUS_Proposals.PROPOSAL_ID = UsageQ.Proposal_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Actual_Montly_List_Report] TO [PNL\D3M578] AS [dbo]
GO
