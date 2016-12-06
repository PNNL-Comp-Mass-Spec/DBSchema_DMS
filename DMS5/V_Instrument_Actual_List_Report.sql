/****** Object:  View [dbo].[V_Instrument_Actual_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[V_Instrument_Actual_List_Report] as
SELECT UsageQ.Fiscal_Year,
       ISNULL(UsageQ.Proposal_ID, 0) AS Proposal_ID,
       ISNULL(CONVERT(varchar(32), T_EUS_Proposals.Title) + '...', '-No Proposal-') AS Title,
       T_EUS_Proposal_State_Name.Name AS Status,
       UsageQ.FT_Usage, UsageQ.IMS_Usage, UsageQ.ORB_Usage, UsageQ.EXA_Usage, UsageQ.LTQ_Usage, UsageQ.GC_Usage, UsageQ.QQQ_Usage,
       UsageQ.FT_Alloc, UsageQ.IMS_Alloc, UsageQ.ORB_Alloc, UsageQ.EXA_Alloc, UsageQ.LTQ_Alloc, UsageQ.GC_Alloc, UsageQ.QQQ_Alloc, 
       UsageQ.FT_Actual + UsageQ.IMS_Actual + UsageQ.ORB_Actual + UsageQ.EXA_Actual + UsageQ.LTQ_Actual + UsageQ.GC_Actual + UsageQ.QQQ_Actual AS Total_Actual,
       UsageQ.FT_Actual, UsageQ.IMS_Actual, UsageQ.ORB_Actual, UsageQ.EXA_Actual, UsageQ.LTQ_Actual, UsageQ.GC_Actual, UsageQ.QQQ_Actual,
       UsageQ.Campaigns, UsageQ.Campaign_First, UsageQ.Campaign_Last,
       UsageQ.FT_EMSL_Actual + UsageQ.IMS_EMSL_Actual + UsageQ.ORB_EMSL_Actual + UsageQ.EXA_EMSL_Actual + UsageQ.LTQ_EMSL_Actual + UsageQ.GC_EMSL_Actual + UsageQ.QQQ_EMSL_Actual AS Total_EMSL_Actual,
       UsageQ.FT_EMSL_Actual, UsageQ.IMS_EMSL_Actual, UsageQ.ORB_EMSL_Actual, UsageQ.EXA_EMSL_Actual, UsageQ.LTQ_EMSL_Actual, UsageQ.GC_EMSL_Actual, UsageQ.QQQ_EMSL_Actual
FROM T_EUS_Proposal_State_Name
     INNER JOIN T_EUS_Proposals
       ON T_EUS_Proposal_State_Name.ID = T_EUS_Proposals.State_ID
     RIGHT OUTER JOIN (
        SELECT IsNull(TAL.Fiscal_Year, TAC.FY) AS Fiscal_Year,
               IsNull(TAL.Proposal_ID, TAC.Proposal) AS Proposal_ID,
               CASE WHEN TAL.FT_Alloc > 0 THEN CONVERT(varchar(24), CONVERT(decimal(9, 1), TAC.FT_Actual / TAL.FT_Alloc * 100)) + '%'
                   ELSE CASE WHEN TAC.FT_Actual > 0 THEN 'Non alloc use' ELSE '' END
               END AS FT_Usage,
               CASE WHEN TAL.IMS_Alloc > 0 THEN CONVERT(varchar(24), CONVERT(decimal(9, 1), TAC.IMS_Actual / TAL.IMS_Alloc * 100)) + '%'
                   ELSE CASE WHEN TAC.IMS_Actual > 0 THEN 'Non alloc use' ELSE '' END
               END AS IMS_Usage,
               CASE WHEN TAL.ORB_Alloc > 0 THEN CONVERT(varchar(24), CONVERT(decimal(9, 1), TAC.ORB_Actual / TAL.ORB_Alloc * 100))  + '%'
                   ELSE CASE WHEN TAC.ORB_Actual > 0 THEN 'Non alloc use' ELSE '' END
               END AS ORB_Usage,
               CASE WHEN TAL.EXA_Alloc > 0 THEN CONVERT(varchar(24), CONVERT(decimal(9, 1), TAC.EXA_Actual / TAL.EXA_Alloc * 100)) + '%'
                   ELSE CASE WHEN TAC.EXA_Actual > 0 THEN 'Non alloc use' ELSE '' END
               END AS EXA_Usage,
               CASE WHEN TAL.LTQ_Alloc > 0 THEN CONVERT(varchar(24), CONVERT(decimal(9, 1), TAC.LTQ_Actual / TAL.LTQ_Alloc * 100)) + '%'
                   ELSE CASE WHEN TAC.LTQ_Actual > 0 THEN 'Non alloc use' ELSE '' END
               END AS LTQ_Usage,
               CASE WHEN TAL.GC_Alloc > 0 THEN CONVERT(varchar(24), CONVERT(decimal(9, 1), TAC.GC_Actual / TAL.GC_Alloc * 100)) + '%'
                   ELSE CASE WHEN TAC.GC_Actual > 0 THEN 'Non alloc use' ELSE '' END
               END AS GC_Usage,
               CASE WHEN TAL.QQQ_Alloc > 0 THEN CONVERT(varchar(24), CONVERT(decimal(9, 1), TAC.QQQ_Actual / TAL.QQQ_Alloc * 100)) + '%'
                   ELSE CASE WHEN TAC.QQQ_Actual > 0 THEN 'Non alloc use' ELSE '' END
               END AS QQQ_Usage,
               TAL.FT_Alloc,  TAC.FT_Actual,
               TAL.IMS_Alloc, TAC.IMS_Actual,
               TAL.ORB_Alloc, TAC.ORB_Actual,
               TAL.EXA_Alloc, TAC.EXA_Actual,
               TAL.LTQ_Alloc, TAC.LTQ_Actual,
               TAL.GC_Alloc,  TAC.GC_Actual,
               TAL.QQQ_Alloc, TAC.QQQ_Actual,
               TAC.Campaigns,
               TAC.Campaign_First,
               TAC.Campaign_Last,
               TAC.FT_EMSL_Actual,
               TAC.IMS_EMSL_Actual,
               TAC.ORB_EMSL_Actual,
               TAC.EXA_EMSL_Actual,
               TAC.LTQ_EMSL_Actual,
               TAC.GC_EMSL_Actual,
               TAC.QQQ_EMSL_Actual               
        FROM ( SELECT dbo.GetFYFromDate(TD.Acq_Time_Start) AS FY,
                      TRR.RDS_EUS_Proposal_ID AS Proposal,
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
                     (TD.Acq_Time_Start >= dbo.GetFiscalYearStart(1)) AND
                     TIN.IN_operations_role NOT IN ('Offsite', 'InSilico')
               GROUP BY dbo.GetFYFromDate(TD.Acq_Time_Start),
                        TRR.RDS_EUS_Proposal_ID
             ) TAC
		     FULL OUTER JOIN (
		         SELECT Fiscal_Year,
		                Proposal_ID,
		                SUM(CASE WHEN Allocation_Tag = 'FT' THEN Allocated_Hours ELSE 0 END) AS FT_Alloc,
		                SUM(CASE WHEN Allocation_Tag = 'IMS' THEN Allocated_Hours ELSE 0 END) AS IMS_Alloc,
		                SUM(CASE WHEN Allocation_Tag = 'ORB' THEN Allocated_Hours ELSE 0 END) AS ORB_Alloc,
		                SUM(CASE WHEN Allocation_Tag = 'EXA' THEN Allocated_Hours ELSE 0 END) AS EXA_Alloc,
		                SUM(CASE WHEN Allocation_Tag = 'LTQ' THEN Allocated_Hours ELSE 0 END) AS LTQ_Alloc,
		                SUM(CASE WHEN Allocation_Tag = 'GC' THEN Allocated_Hours ELSE 0 END) AS GC_Alloc,
		                SUM(CASE WHEN Allocation_Tag = 'QQQ' THEN Allocated_Hours ELSE 0 END) AS QQQ_Alloc
		         FROM T_Instrument_Allocation
		         GROUP BY Proposal_ID, Fiscal_Year 
		     ) TAL
               ON TAC.Proposal = TAL.Proposal_ID AND
                  TAC.FY = TAL.Fiscal_Year 
     ) UsageQ
       ON T_EUS_Proposals.PROPOSAL_ID = UsageQ.Proposal_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Actual_List_Report] TO [DDL_Viewer] AS [dbo]
GO
