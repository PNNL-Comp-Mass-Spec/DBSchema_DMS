/****** Object:  View [dbo].[V_Run_Planning_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Run_Planning_Report] 
AS
SELECT  GroupQ.[Inst. Group],
        GroupQ.[DS Type],
        Case When GroupQ.Fraction_Count > 1 
             Then GroupQ.[Run Count] * GroupQ.Fraction_Count 
             Else GroupQ.[Run Count] 
        End AS [Run Count],
        GroupQ.Blocked,
        GroupQ.BlkMissing,
        Case When RequestLookupQ.RDS_BatchID > 0 
             Then GroupQ.Batch_Prefix 
             Else GroupQ.Request_Prefix 
        End AS [Request or Batch Name],
        RequestLookupQ.RDS_BatchID AS Batch,
        GroupQ.Requester,
        DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) AS [Days in Queue],
        GroupQ.[Days in Prep Queue],
        GroupQ.[Queue State],
        GroupQ.[Queued Instrument],
        Convert(decimal(10, 1), TAC.Actual_Hours) As Actual_Hours,
        TIGA.Allocated_Hours,
        GroupQ.[Separation Group],
        Case When RequestLookupQ.RDS_BatchID > 0 
             Then GroupQ.Batch_Comment
             Else RequestLookupQ.RDS_comment
        End As [Comment],
        GroupQ.[Min Request],
        GroupQ.[Work Package],
        GroupQ.[WP State],
        GroupQ.Proposal,
        GroupQ.[Proposal Type],
        TEUT.Name AS [Usage],
        GroupQ.Locked,
        GroupQ.[Last Ordered],
        GroupQ.[Request Name Code],
        CASE WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 30
             THEN 30  -- Request is 0 to 30 days old
             WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 60
             THEN 60  -- Request is 30 to 60 days old
             WHEN DATEDIFF(DAY, GroupQ.[Date Created], GETDATE()) <= 90
             THEN 90  -- Request is 60 to 90 days old
             ELSE 120                                                            -- Request is over 90 days old
        END AS #DaysInQueue,
        GroupQ.WPActivationState AS #WPActivationState,
        GroupQ.Requested_Batch_Priority AS #BatchPriority,
        Case When GroupQ.Fraction_Count > 1 Then 1
             When GroupQ.FractionBasedRequestCount > 1 Then 2
             Else 0
        End AS #FractionColorMode
FROM    ( SELECT    [Inst. Group],
                    MIN(RequestID) AS [Min Request],
                    COUNT(RequestID) AS [Run Count],
                    MIN(Request_Prefix) AS Request_Prefix,
                    Requester,
                    MIN(Request_Created) AS [Date Created],
                    [Separation Group],
                    Fraction_Count,
                    [DS Type],
                    [Work Package],
                    [WP State],
                    WPActivationState,
                    Proposal,
                    [Proposal Type],
                    Locked,
                    Batch_Prefix,
                    Requested_Batch_Priority,
                    Batch_Comment,
                    [Last Ordered],
                    [Queue State],
                    [Queued Instrument],
                    [Request Name Code],
                    Sum(Case When RequestOrigin = 'fraction' Then 1 Else 0 End) As FractionBasedRequestCount,
                    MAX([Days in Prep Queue]) AS [Days in Prep Queue],
                    SUM(BlkMissing) AS BlkMissing,
                    SUM(Blocked) AS Blocked                    
          FROM      ( SELECT RR.RDS_instrument_group AS [Inst. Group],
                             RR.RDS_Sec_Sep AS [Separation Group],
                             DTN.DST_Name AS [DS Type],
                             RR.ID AS RequestID,
                             LEFT(RR.RDS_Name, 20) + CASE WHEN LEN(RR.RDS_Name) > 20 THEN '...'
                                                          ELSE ''
                                                     END AS Request_Prefix,
                             RR.RDS_NameCode AS [Request Name Code],
                             RR.RDS_Origin As RequestOrigin,
                             U.U_Name AS Requester,
                             RR.RDS_created AS Request_Created,
                             RR.RDS_WorkPackage AS [Work Package],
                             ISNULL(CC.Activation_State_Name, '') AS [WP State],
                             CC.Activation_State AS WPActivationState,
                             RR.RDS_EUS_Proposal_ID AS Proposal,
                             EPT.Abbreviation AS [Proposal Type],
                             RRB.Locked,
                             RRB.Requested_Batch_Priority,
                             RR.RDS_BatchID AS Batch,
                             RRB.Comment As Batch_Comment,
                             QS.Queue_State_Name AS [Queue State],
                             CASE WHEN RR.Queue_State = 2 THEN ISNULL(AssignedInstrument.IN_name, '') ELSE '' END AS [Queued Instrument],
                             LEFT(RRB.Batch, 20) + CASE WHEN LEN(RRB.Batch) > 20 THEN '...'
                                                        ELSE ''
                                                   END AS Batch_Prefix,
                             CONVERT(datetime, FLOOR(CONVERT(float, RRB.Last_Ordered))) AS [Last Ordered],
                             CASE
                                 WHEN SPR.ID = 0 THEN NULL
                                 ELSE QT.[Days In Queue]
                             END AS [Days in Prep Queue],
                             CASE
                                 WHEN ISNULL(SPR.BlockAndRandomizeRuns, '') = 'yes' AND
                                      (ISNULL(RR.RDS_Block, '') = '' OR
                                       ISNULL(RR.RDS_Run_Order, '') = '') THEN 1
                                 ELSE 0
                             END AS BlkMissing,
                             CASE
                                 WHEN ISNULL(RR.RDS_Block, '') <> '' AND
                                      ISNULL(RR.RDS_Run_Order, '') <> '' THEN 1
                                 ELSE 0
                             END AS Blocked,
                             SG.Fraction_Count As Fraction_Count
                      FROM T_DatasetTypeName AS DTN
                           INNER JOIN T_Requested_Run AS RR
                             ON DTN.DST_Type_ID = RR.RDS_type_ID
                           INNER JOIN T_Users AS U
                             ON RR.RDS_Requestor_PRN = U.U_PRN
                           INNER JOIN T_Experiments AS E
                             ON RR.Exp_ID = E.Exp_ID
                           INNER JOIN T_Requested_Run_Queue_State QS 
                             ON RR.Queue_State = QS.Queue_State
                           INNER JOIN T_EUS_UsageType AS EUT
                             ON RR.RDS_EUS_UsageType = EUT.ID
                           INNER JOIN T_Requested_Run_Batches AS RRB
                             ON RR.RDS_BatchID = RRB.ID
                           INNER JOIN T_Sample_Prep_Request AS SPR
                             ON E.EX_sample_prep_request_ID = SPR.ID
                           Inner Join T_Separation_Group As SG
                             On RR.RDS_Sec_Sep = SG.Sep_Group
                           LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times AS QT
                             ON SPR.ID = QT.Request_ID
                           LEFT OUTER JOIN V_Charge_Code_Status AS CC
                             ON RR.RDS_WorkPackage = CC.Charge_Code
                           LEFT OUTER JOIN T_EUS_Proposals AS EUP
                             ON RR.RDS_EUS_Proposal_ID = EUP.Proposal_ID
                           LEFT OUTER JOIN T_EUS_Proposal_Type EPT
                             ON EUP.Proposal_Type = EPT.Proposal_Type
                           LEFT OUTER JOIN T_Instrument_Name AS AssignedInstrument
                             ON RR.Queue_Instrument_ID = AssignedInstrument.Instrument_ID
                      WHERE RR.RDS_Status = 'Active' AND
                            RR.DatasetID IS NULL
                    ) AS RequestQ
          GROUP BY  [Inst. Group],
                    [Separation Group],
                    Fraction_Count,
                    [DS Type],
                    [Request Name Code],
                    Requester,
                    [Work Package],
                    [WP State],
                    WPActivationState,
                    Proposal,
                    [Proposal Type],
                    Locked,
                    [Last Ordered],
                    [Queue State],
                    [Queued Instrument],
                    Batch,
                    Batch_Prefix,
                    Requested_Batch_Priority,
                    Batch_Comment
        ) AS GroupQ
        INNER JOIN T_Requested_Run AS RequestLookupQ ON GroupQ.[Min Request] = RequestLookupQ.ID
        INNER JOIN T_EUS_UsageType AS TEUT ON RequestLookupQ.RDS_EUS_UsageType = TEUT.ID
        LEFT OUTER JOIN T_Cached_Instrument_Usage_by_Proposal AS TAC ON TAC.IN_Group = GroupQ.[Inst. Group]
                                    AND TAC.EUS_Proposal_ID = GroupQ.Proposal
        LEFT OUTER JOIN ( SELECT    QG.IN_Group,
                                    QIA.Proposal_ID,
                                    QIA.Allocated_Hours
                          FROM      T_Instrument_Group AS QG
                                    INNER JOIN T_Instrument_Allocation AS QIA ON QG.Allocation_Tag = QIA.Allocation_Tag
                          WHERE     ( QIA.Fiscal_Year = dbo.GetFYFromDate(GETDATE()) )
                        ) AS TIGA ON TIGA.IN_Group = GroupQ.[Inst. Group] AND
                                     TIGA.Proposal_ID = GroupQ.Proposal


GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Planning_Report] TO [DDL_Viewer] AS [dbo]
GO
