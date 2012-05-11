/****** Object:  View [dbo].[V_Instrument_Actual_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Instrument_Actual_List_Report] as
SELECT TAL.Fiscal_Year,
       TAL.Proposal_ID,
       CONVERT(varchar(32), T_EUS_Proposals.TITLE) + '...' AS Title,
       T_EUS_Proposal_State_Name.Name AS Status,       
       Case When TAL.FT_Alloc > 0  Then CONVERT(varchar(24), CONVERT(decimal(9,1), TAC.FT_Actual / TAL.FT_Alloc * 100)) + '%'
            Else Case When TAC.FT_Actual > 0  Then 'Non alloc use' Else '' End
       End AS FT_Usage,
       Case When TAL.IMS_Alloc > 0 Then CONVERT(varchar(24), CONVERT(decimal(9,1), TAC.IMS_Actual / TAL.IMS_Alloc * 100)) + '%'
            Else Case When TAC.IMS_Actual > 0 Then 'Non alloc use' Else '' End
       End AS IMS_Usage,
       Case When TAL.ORB_Alloc > 0 Then CONVERT(varchar(24), CONVERT(decimal(9,1), TAC.ORB_Actual / TAL.ORB_Alloc * 100)) + '%'
            Else Case When TAC.ORB_Actual > 0 Then 'Non alloc use' Else '' End
       End AS ORB_Usage,
       Case When TAL.EXA_Alloc > 0 Then CONVERT(varchar(24), CONVERT(decimal(9,1), TAC.EXA_Actual / TAL.EXA_Alloc * 100)) + '%'
            Else Case When TAC.EXA_Actual > 0 Then 'Non alloc use' Else '' End
       End AS EXA_Usage,
       Case When TAL.LTQ_Alloc > 0 Then CONVERT(varchar(24), CONVERT(decimal(9,1), TAC.LTQ_Actual / TAL.LTQ_Alloc * 100)) + '%'
            Else Case When TAC.LTQ_Actual > 0 Then 'Non alloc use' Else '' End
       End AS LTQ_Usage,
       Case When TAL.GC_Alloc > 0  Then CONVERT(varchar(24), CONVERT(decimal(9,1), TAC.GC_Actual / TAL.GC_Alloc * 100)) + '%'
            Else Case When TAC.GC_Actual > 0 Then 'Non alloc use' Else '' End
       End AS GC_Usage,
       Case When TAL.QQQ_Alloc > 0 Then CONVERT(varchar(24), CONVERT(decimal(9,1), TAC.QQQ_Actual / TAL.QQQ_Alloc * 100)) + '%'
            Else Case When TAC.QQQ_Actual > 0 Then 'Non alloc use' Else '' End
       End AS QQQ_Usage,        
       TAL.FT_Alloc,
       TAC.FT_Actual,
       TAL.IMS_Alloc,
       TAC.IMS_Actual,
       TAL.ORB_Alloc,
       TAC.ORB_Actual,
       TAL.EXA_Alloc,
       TAC.EXA_Actual,
       TAL.LTQ_Alloc,
       TAC.LTQ_Actual,
       TAL.GC_Alloc,
       TAC.GC_Actual,
       TAL.QQQ_Alloc,
       TAC.QQQ_Actual
FROM T_EUS_Proposal_State_Name
     INNER JOIN T_EUS_Proposals
       ON T_EUS_Proposal_State_Name.ID = T_EUS_Proposals.State_ID
     RIGHT OUTER JOIN ( SELECT Fiscal_Year,
                               Proposal_ID,
                               SUM(CASE WHEN Allocation_Tag = 'FT'  THEN Allocated_Hours ELSE 0 END) AS FT_Alloc, 
                               SUM(CASE WHEN Allocation_Tag = 'IMS' THEN Allocated_Hours ELSE 0 END) AS IMS_Alloc, 
                               SUM(CASE WHEN Allocation_Tag = 'ORB' THEN Allocated_Hours ELSE 0 END) AS ORB_Alloc, 
                               SUM(CASE WHEN Allocation_Tag = 'EXA' THEN Allocated_Hours ELSE 0 END) AS EXA_Alloc, 
                               SUM(CASE WHEN Allocation_Tag = 'LTQ' THEN Allocated_Hours ELSE 0 END) AS LTQ_Alloc, 
                               SUM(CASE WHEN Allocation_Tag = 'GC' THEN Allocated_Hours ELSE 0 END) AS GC_Alloc, 
                               SUM(CASE WHEN Allocation_Tag = 'QQQ' THEN Allocated_Hours ELSE 0 END) AS QQQ_Alloc
                        FROM T_Instrument_Allocation
                        GROUP BY Proposal_ID, Fiscal_Year 
                      ) AS TAL
       ON T_EUS_Proposals.PROPOSAL_ID = TAL.Proposal_ID
     LEFT OUTER JOIN ( SELECT dbo.GetFYFromDate(TD.Acq_Time_Start) AS FY,
                              TRR.RDS_EUS_Proposal_ID AS Proposal,
                              CONVERT(DECIMAL(10, 1), SUM(CASE WHEN Allocation_Tag = 'FT' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS FT_Actual, 
                              CONVERT(DECIMAL(10, 1), SUM(CASE WHEN Allocation_Tag = 'IMS' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS IMS_Actual, 
                              CONVERT(DECIMAL(10, 1), SUM(CASE WHEN Allocation_Tag = 'ORB' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS ORB_Actual, 
                              CONVERT(DECIMAL(10, 1), SUM(CASE WHEN Allocation_Tag = 'EXA' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS EXA_Actual, 
                              CONVERT(DECIMAL(10, 1), SUM(CASE WHEN Allocation_Tag = 'LTQ' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS LTQ_Actual, 
                              CONVERT(DECIMAL(10, 1), SUM(CASE WHEN Allocation_Tag = 'GC' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS GC_Actual, 
                              CONVERT(DECIMAL(10, 1), SUM(CASE WHEN Allocation_Tag = 'QQQ' THEN TD.Acq_Length_Minutes ELSE 0 END) / 60.0) AS QQQ_Actual
                       FROM T_Dataset AS TD
                            INNER JOIN T_Requested_Run AS TRR
                              ON TD.Dataset_ID = TRR.DatasetID
                            INNER JOIN T_Instrument_Name AS TIN
                              ON TIN.Instrument_ID = TD.DS_instrument_name_ID
                            INNER JOIN T_Instrument_Group
                              ON TIN.IN_Group = T_Instrument_Group.IN_Group
                       WHERE (TD.DS_rating > 1) AND
                             (TRR.RDS_EUS_UsageType = 16) AND
                             (TD.DS_state_ID = 3) AND
                             (TD.Acq_Time_Start >= dbo.GetFiscalYearStart(1))
                       GROUP BY TRR.RDS_EUS_Proposal_ID, dbo.GetFYFromDate(TD.Acq_Time_Start) 
                      ) AS TAC
       ON TAC.Proposal = TAL.Proposal_ID AND
          TAC.FY = TAL.Fiscal_Year
           

GO
