/****** Object:  View [dbo].[V_Run_Planning_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--
CREATE view [dbo].[V_Run_Planning_Report] as
SELECT  GroupQ.[Inst. Group] ,
        GroupQ.[DS Type] ,
        GroupQ.[Run Count] ,
        GroupQ.Blocked ,
        GroupQ.BlkMissing ,
        GroupQ.[Request Name or Batch],
        RequestLookupQ.RDS_BatchID AS Batch ,
        GroupQ.Requester ,
        DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) AS [Days in Queue] ,
        GroupQ.[Days in Prep Queue] ,
        Convert(decimal(10, 1), TAC.Actual_Hours) As Actual_Hours,
        TIGA.Allocated_Hours ,
        GroupQ.[Separation Group] ,
        RequestLookupQ.RDS_comment AS [Comment] ,
        GroupQ.[Min Request] ,
        GroupQ.[Work Package] ,
		GroupQ.[WP State],
        GroupQ.Proposal ,
        TEUT.Name AS [Usage] ,
        GroupQ.Locked ,
        GroupQ.[Last Ordered] ,
        GroupQ.[Request Name Code] ,
        CASE WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 30
             THEN 30  -- Request is 0 to 30 days old
             WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 60
             THEN 60  -- Request is 30 to 60 days old
             WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 90
             THEN 90  -- Request is 60 to 90 days old
             ELSE 120                                                            -- Request is over 90 days old
        END AS #DaysInQueue,
		WPActivationState AS #WPActivationState
FROM    ( SELECT    [Inst. Group] ,
                    MIN(RequestID) AS [Min Request] ,
                    COUNT(RequestName) AS [Run Count] ,
                    MIN([Batch/Request]) AS [Request Name or Batch],
                    Requester ,
                    MIN(Request_Created) AS [Date Created] ,
                    [Separation Group] ,
                    [DS Type] ,
                    [Work Package] ,
					[WP State] ,
					WPActivationState ,
                    Proposal ,
                    Locked ,
                    [Last Ordered] ,
                    [Request Name Code] ,
                    MAX([Days in Prep Queue]) AS [Days in Prep Queue] ,
                    SUM(BlkMissing) AS BlkMissing ,
                    SUM(Blocked) AS Blocked					
          FROM      ( SELECT    RA.Instrument AS [Inst. Group] ,
                                RA.[Separation Group] ,
                                RA.[Type] AS [DS Type] ,
                                RA.Request AS RequestID ,
                                RA.Name AS RequestName ,
                               CASE WHEN RA.Batch = 0
                                     THEN LEFT(RA.Name, 20)
                                          + CASE WHEN LEN(RA.Name) > 20
                                                 THEN '...'
                                                 ELSE ''
                                            END
                                     ELSE LEFT(RRB.Batch, 20)
                                          + CASE WHEN LEN(RRB.Batch) > 20
                                                 THEN '...'
                                                 ELSE ''
                                            END
                                END AS [Batch/Request] ,                                
                                RA.[Request Name Code] ,
                                RA.Requester ,
                                RA.Created AS Request_Created ,
                                RA.[Work Package] ,
								ISNULL(CC.Activation_State_Name, '') AS [WP State],
								CC.Activation_State AS WPActivationState,
                                RA.Proposal ,
                                RRB.Locked ,
                                RA.Batch,
                                CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, RRB.Last_Ordered))) AS [Last Ordered] ,
                                CASE WHEN SPR.ID = 0 THEN NULL
                                     ELSE QT.[Days In Queue]
                                END AS [Days in Prep Queue] ,
                                CASE WHEN ISNULL(SPR.BlockAndRandomizeRuns, '') = 'yes'
                                          AND ( ISNULL(RA.Block, '') = ''
                                                OR ISNULL(RA.[Run Order], '') = ''
                                              ) THEN 1
                                     ELSE 0
                                END AS BlkMissing ,
                                CASE WHEN ISNULL(RA.Block, '') <> ''
                                          AND ISNULL(RA.[Run Order], '') <> ''
                                     THEN 1
                                     ELSE 0
                                END AS Blocked
                      FROM      V_Run_Assignment AS RA
                                INNER JOIN T_Requested_Run_Batches AS RRB ON RA.Batch = RRB.ID
                                INNER JOIN T_Experiments AS E ON RA.[Experiment ID] = E.Exp_ID
                                INNER JOIN T_Sample_Prep_Request AS SPR ON E.EX_sample_prep_request_ID = SPR.ID
                                LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times AS QT ON SPR.ID = QT.Request_ID
								LEFT OUTER JOIN V_Charge_Code_Status AS CC ON RA.[Work Package] = CC.Charge_Code                                
                      WHERE     ( RA.Status = 'Active' )
                    ) AS RequestQ
          GROUP BY  [Inst. Group] ,
                    [Separation Group] ,
                    [DS Type] ,
                    [Request Name Code] ,
                    Requester ,
                    [Work Package] ,
					[WP State] ,
					WPActivationState ,
                    Proposal,
                    Locked ,
                    [Last Ordered],
                    Batch
        ) AS GroupQ
        INNER JOIN T_Requested_Run AS RequestLookupQ ON GroupQ.[Min Request] = RequestLookupQ.ID
        INNER JOIN T_EUS_UsageType AS TEUT ON RequestLookupQ.RDS_EUS_UsageType = TEUT.ID
        LEFT OUTER JOIN T_Cached_Instrument_Usage_by_Proposal AS TAC ON TAC.IN_Group = GroupQ.[Inst. Group]
                                    AND TAC.EUS_Proposal_ID = GroupQ.Proposal
        LEFT OUTER JOIN ( SELECT    QG.IN_Group ,
                                    QIA.Proposal_ID ,
                                    QIA.Allocated_Hours
                          FROM      T_Instrument_Group AS QG
                                    INNER JOIN T_Instrument_Allocation AS QIA ON QG.Allocation_Tag = QIA.Allocation_Tag
                          WHERE     ( QIA.Fiscal_Year = dbo.GetFYFromDate(GETDATE()) )
                        ) AS TIGA ON TIGA.IN_Group = GroupQ.[Inst. Group]
                                     AND TIGA.Proposal_ID = GroupQ.Proposal


GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Planning_Report] TO [DDL_Viewer] AS [dbo]
GO
