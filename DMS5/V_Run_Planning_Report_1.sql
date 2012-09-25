/****** Object:  View [dbo].[V_Run_Planning_Report_1] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view V_Run_Planning_Report_1 as
SELECT  GroupQ.[Inst. Group] ,
        GroupQ.[DS Type] ,
        GroupQ.[Run Count] ,
        GroupQ.[Batch or Experiment] ,
        RequestLookupQ.RDS_BatchID AS Batch ,
        GroupQ.Requester ,
        DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) AS [Days in Queue] ,
        GroupQ.[Days in Prep Queue] ,
        TAC.Actual_Hours ,
        TIGA.Allocated_Hours ,
        GroupQ.[Separation Type] ,
        CASE WHEN LEN(RequestLookupQ.RDS_comment) > 30
             THEN SUBSTRING(RequestLookupQ.RDS_comment, 1, 27) + '...'
             ELSE RequestLookupQ.RDS_comment
        END AS Comment ,
        GroupQ.[Min Request] ,
        GroupQ.[Work Package] ,
        GroupQ.Proposal ,
        TEUT.Name AS Usage ,
        GroupQ.Locked ,
        GroupQ.[Last Ordered] ,
        GroupQ.[Request Name Code] ,
        CASE WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 30
             THEN 30
             WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 60
             THEN 60
             WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 90
             THEN 90
             ELSE 120
        END AS [#DaysInQueue]
FROM    ( SELECT    [Inst. Group] ,
                    MIN(RequestID) AS [Min Request] ,
                    COUNT(RequestName) AS [Run Count] ,
                    MIN([Batch/Experiment]) AS [Batch or Experiment] ,
                    Requester ,
                    MIN(Request_Created) AS [Date Created] ,
                    [Separation Type] ,
                    [DS Type] ,
                    [Work Package] ,
                    Proposal ,
                    Locked ,
                    [Last Ordered] ,
                    [Request Name Code] ,
                    MAX([Days in Prep Queue]) AS [Days in Prep Queue]
          FROM      ( SELECT    RA.Instrument AS [Inst. Group] ,
                                RA.[Separation Type] ,
                                RA.Type AS [DS Type] ,
                                RA.Request AS RequestID ,
                                RA.Name AS RequestName ,
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
                                RA.[Request Name Code] ,
                                RA.Requester ,
                                RA.Created AS Request_Created ,
                                RA.[Work Package] ,
                                RA.Proposal ,
                                RRB.Locked ,
                                CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, RRB.Last_Ordered))) AS [Last Ordered] ,
                                CASE WHEN SPR.ID = 0 THEN NULL
                                     ELSE QT.[Days In Queue]
                                END AS [Days in Prep Queue]
                      FROM      V_Run_Assignment AS RA
                                INNER JOIN T_Requested_Run_Batches AS RRB ON RA.Batch = RRB.ID
                                INNER JOIN T_Experiments AS E ON RA.[Experiment ID] = E.Exp_ID
                                INNER JOIN T_Sample_Prep_Request AS SPR ON E.EX_sample_prep_request_ID = SPR.ID
                                LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times
                                AS QT ON SPR.ID = QT.Request_ID
                      WHERE     ( RA.Status = 'Active' )
                    ) AS RequestQ
          GROUP BY  [Inst. Group] ,
                    [Separation Type] ,
                    [DS Type] ,
                    [Request Name Code] ,
                    Requester ,
                    [Work Package] ,
                    Proposal ,
                    Locked ,
                    [Last Ordered]
        ) AS GroupQ
        INNER JOIN T_Requested_Run AS RequestLookupQ ON GroupQ.[Min Request] = RequestLookupQ.ID
        INNER JOIN T_EUS_UsageType AS TEUT ON RequestLookupQ.RDS_EUS_UsageType = TEUT.ID
        INNER JOIN T_Instrument_Group TGG ON GroupQ.[Inst. Group] = TGG.IN_Group
        LEFT OUTER JOIN ( SELECT    TG.Allocation_Tag ,
                                    TRR.RDS_EUS_Proposal_ID AS Proposal ,
                                    CONVERT(DECIMAL(10, 1), SUM(TD.Acq_Length_Minutes)
                                    / 60.0) AS Actual_Hours
                          FROM      T_Dataset AS TD
                                    INNER JOIN T_Requested_Run AS TRR ON TD.Dataset_ID = TRR.DatasetID
                                    INNER JOIN T_Instrument_Name AS TIN ON TIN.Instrument_ID = TD.DS_instrument_name_ID
                                    INNER JOIN T_Instrument_Group AS TG ON TIN.IN_Group = TG.IN_Group
                          WHERE     ( TD.DS_rating > 1 )
                                    AND ( TRR.RDS_EUS_UsageType = 16 )
                                    AND ( TD.DS_state_ID = 3 )
                                    AND ( TD.Acq_Time_Start >= dbo.GetFiscalYearStart(1) )
                          GROUP BY  TRR.RDS_EUS_Proposal_ID ,
                                    TG.Allocation_Tag
                        ) AS TAC ON TAC.Allocation_Tag = TGG.Allocation_Tag
                                    AND TAC.Proposal = GroupQ.Proposal
        LEFT OUTER JOIN ( SELECT    QG.IN_Group ,
                                    QIA.Proposal_ID ,
                                    QIA.Allocated_Hours
                          FROM      T_Instrument_Group AS QG
                                    INNER JOIN T_Instrument_Allocation AS QIA ON QG.Allocation_Tag = QIA.Allocation_Tag
                          WHERE     ( QIA.Fiscal_Year = dbo.GetFYFromDate(GETDATE()) )
                        ) AS TIGA ON GroupQ.[Inst. Group] = TIGA.IN_Group
                                     AND GroupQ.Proposal = TIGA.Proposal_ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Planning_Report_1] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Planning_Report_1] TO [PNL\D3M580] AS [dbo]
GO
