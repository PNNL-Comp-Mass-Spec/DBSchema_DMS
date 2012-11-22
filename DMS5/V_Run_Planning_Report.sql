/****** Object:  View [dbo].[V_Run_Planning_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Run_Planning_Report] as
SELECT GroupQ.[Inst. Group],
       GroupQ.[DS Type],
       GroupQ.[Run Count],
       GroupQ.[Batch or Experiment],
       RequestLookupQ.RDS_BatchID AS Batch,
       GroupQ.Requester,
       DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) AS [Days in Queue],
       GroupQ.[Days in Prep Queue],
       TAC.Actual_Hours,
       TIGA.Allocated_Hours,
       GroupQ.[Separation Group],
       CASE WHEN LEN(RequestLookupQ.RDS_comment) > 30 
            THEN SUBSTRING(RequestLookupQ.RDS_comment, 1, 27) + '...'
            ELSE RequestLookupQ.RDS_comment
       END AS [Comment],
       GroupQ.[Min Request],
       GroupQ.[Work Package],
       GroupQ.Proposal,
       TEUT.Name AS [Usage],
       GroupQ.Locked,
       GroupQ.[Last Ordered],
       GroupQ.[Request Name Code],
       CASE
           WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 30 THEN 30  -- Request is 0 to 30 days old
           WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 60 THEN 60  -- Request is 30 to 60 days old
           WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 90 THEN 90  -- Request is 60 to 90 days old
           ELSE 120                                                            -- Request is over 90 days old
       END AS #DaysInQueue
FROM ( SELECT [Inst. Group],
              MIN(RequestID) AS [Min Request],
              COUNT(RequestName) AS [Run Count],
              MIN([Batch/Experiment]) AS [Batch or Experiment],
              Requester,
              MIN(Request_Created) AS [Date Created],
              [Separation Group],
              [DS Type],
              [Work Package],
              Proposal,
              Locked,
              [Last Ordered],
              [Request Name Code],
              MAX([Days in Prep Queue]) AS [Days in Prep Queue]
       FROM ( SELECT RA.Instrument AS [Inst. Group],
                     RA.[Separation Group],
                     RA.[Type] AS [DS Type],
                     RA.Request AS RequestID,
                     RA.Name AS RequestName,
                     CASE WHEN RA.Batch = 0
                          THEN LEFT(RA.Experiment, 20)
                               + CASE WHEN LEN(RA.Experiment) > 20
                                      THEN '...'
                                      ELSE ''
                                 END
                          ELSE LEFT(RRB.Batch, 20)
                               + CASE WHEN LEN(RRB.Batch) > 20
                                      THEN '...'
                                      ELSE ''
                                 END
                     END AS [Batch/Experiment] ,
                     RA.[Request Name Code],
                     RA.Requester,
                     RA.Created AS Request_Created,
                     RA.[Work Package],
                     RA.Proposal,
                     RRB.Locked,
                     CONVERT(datetime, FLOOR(CONVERT(float, RRB.Last_Ordered))) AS [Last Ordered],
                     CASE WHEN SPR.ID = 0 THEN NULL
                          ELSE QT.[Days In Queue]
                     END AS [Days in Prep Queue]
              FROM V_Run_Assignment AS RA
                   INNER JOIN T_Requested_Run_Batches AS RRB
                     ON RA.Batch = RRB.ID
                   INNER JOIN T_Experiments AS E
                     ON RA.[Experiment ID] = E.Exp_ID
                   INNER JOIN T_Sample_Prep_Request AS SPR
                     ON E.EX_sample_prep_request_ID = SPR.ID
                   LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times AS QT
                     ON SPR.ID = QT.Request_ID
              WHERE (RA.Status = 'Active') ) AS RequestQ
       GROUP BY [Inst. Group], [Separation Group], [DS Type], [Request Name Code], Requester, [Work Package],
                Proposal, Locked, [Last Ordered] 
     ) AS GroupQ
     INNER JOIN T_Requested_Run AS RequestLookupQ
       ON GroupQ.[Min Request] = RequestLookupQ.ID
     INNER JOIN T_EUS_UsageType AS TEUT
       ON RequestLookupQ.RDS_EUS_UsageType = TEUT.ID
     LEFT OUTER JOIN ( SELECT TIN.IN_Group AS Inst_Group,
                              TRR.RDS_EUS_Proposal_ID AS Proposal,
                              CONVERT(decimal(10, 1), SUM(TD.Acq_Length_Minutes) / 60.0) AS Actual_Hours
                       FROM T_Dataset AS TD
                            INNER JOIN T_Requested_Run AS TRR
                              ON TD.Dataset_ID = TRR.DatasetID
                            INNER JOIN T_Instrument_Name AS TIN
                              ON TIN.Instrument_ID = TD.DS_instrument_name_ID
                       WHERE (TD.DS_rating > 1) AND
                             (TRR.RDS_EUS_UsageType = 16) AND
                             (TD.DS_state_ID = 3) AND
                             (TD.Acq_Time_Start >= dbo.GetFiscalYearStart(1))
                       GROUP BY TIN.IN_Group, TRR.RDS_EUS_Proposal_ID 
                      ) AS TAC
       ON TAC.Inst_Group = GroupQ.[Inst. Group] AND
          TAC.Proposal = GroupQ.Proposal
     LEFT OUTER JOIN ( SELECT QG.IN_Group,
                              QIA.Proposal_ID,
                              QIA.Allocated_Hours
                       FROM T_Instrument_Group AS QG
                            INNER JOIN T_Instrument_Allocation AS QIA
                              ON QG.Allocation_Tag = QIA.Allocation_Tag
                       WHERE (QIA.Fiscal_Year = dbo.GetFYFromDate(GETDATE())) 
                     ) AS TIGA
       ON TIGA.IN_Group = GroupQ.[Inst. Group] AND
          TIGA.Proposal_ID = GroupQ.Proposal


GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Planning_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Planning_Report] TO [PNL\D3M580] AS [dbo]
GO
