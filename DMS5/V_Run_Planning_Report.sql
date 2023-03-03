/****** Object:  View [dbo].[V_Run_Planning_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Run_Planning_Report]
AS
SELECT GroupQ.inst_group,
       GroupQ.ds_type,
       Case When GroupQ.Fraction_Count > 1
            Then GroupQ.Run_Count * GroupQ.fraction_count
            Else GroupQ.run_count
       End AS run_count,
       GroupQ.blocked,
       GroupQ.block_missing,
       Case When RequestLookupQ.RDS_BatchID > 0
            Then GroupQ.batch_prefix
            Else GroupQ.request_prefix
       End AS request_or_batch_name,
       RequestLookupQ.RDS_BatchID AS batch,
       GroupQ.Batch_Group_ID As batch_group,
       Case When GroupQ.Batch_Group_ID > 0 Then dbo.get_batch_group_member_list(GroupQ.Batch_Group_ID) Else '' End As batches,
       GroupQ.requester,
       DATEDIFF(DAY, GroupQ.date_created, GETDATE()) AS days_in_queue,
       GroupQ.days_in_prep_queue,
       GroupQ.queue_state,
       GroupQ.queued_instrument,
       -- Cast(TAC.Actual_Hours As decimal(10, 0)) As actual_hours,
       GroupQ.separation_group,
       Case When RequestLookupQ.RDS_BatchID > 0
            Then GroupQ.batch_comment
            Else RequestLookupQ.rds_comment
       End As comment,
       GroupQ.min_request,
       GroupQ.work_package,
       GroupQ.wp_state,
       GroupQ.proposal,
       GroupQ.proposal_type,
       TEUT.Name AS usage,
       GroupQ.locked,
       GroupQ.last_ordered,
       GroupQ.request_name_code,
       CASE WHEN DATEDIFF(DAY, GroupQ.date_created, GETDATE()) <= 30
            THEN 30     -- Request is 0 to 30 days old
            WHEN DATEDIFF(DAY, GroupQ.date_created, GETDATE()) <= 60
            THEN 60     -- Request is 30 to 60 days old
            WHEN DATEDIFF(DAY, GroupQ.date_created, GETDATE()) <= 90
            THEN 90     -- Request is 60 to 90 days old
            ELSE 120    -- Request is over 90 days old
       END AS days_in_queue_bin,
       GroupQ.WPActivationState AS wp_activation_state,
       GroupQ.Requested_Batch_Priority AS batch_priority,
       CASE WHEN GroupQ.Fraction_Count > 1 THEN 1
            WHEN GroupQ.FractionBasedRequestCount > 1 THEN 2
            ELSE 0
       END AS fraction_color_mode
FROM ( SELECT Inst_Group,
              MIN(RequestID) AS Min_Request,
              COUNT(RequestID) AS Run_Count,
              MIN(Request_Prefix) AS Request_Prefix,
              Requester,
              MIN(Request_Created) AS Date_Created,
              Separation_Group,
              Fraction_Count,
              DS_Type,
              Work_Package,
              WP_State,
              WPActivationState,
              Proposal,
              Proposal_Type,
              Locked,
              Batch_Prefix,
              Requested_Batch_Priority,
              Batch_Comment,
              Batch_Group_ID,
              Last_Ordered,
              Queue_State,
              Queued_Instrument,
              Request_Name_Code,
              Sum(Case When RequestOrigin = 'fraction' Then 1 Else 0 End) As FractionBasedRequestCount,
              MAX([Days_in_Prep_Queue]) AS Days_in_Prep_Queue,
              SUM(Block_Missing) AS Block_Missing,
              SUM(Blocked) AS Blocked
      FROM ( SELECT RR.RDS_instrument_group AS Inst_Group,
                    RR.RDS_Sec_Sep AS Separation_Group,
                    DTN.DST_Name AS DS_Type,
                    RR.ID AS RequestID,
                    LEFT(RR.RDS_Name, 20) + CASE WHEN LEN(RR.RDS_Name) > 20 THEN '...'
                                                ELSE ''
                                            END AS Request_Prefix,
                    RR.RDS_NameCode AS Request_Name_Code,
                    RR.RDS_Origin As RequestOrigin,
                    U.U_Name AS Requester,
                    RR.RDS_created AS Request_Created,
                    RR.RDS_WorkPackage AS Work_Package,
                    Coalesce(CC.Activation_State_Name, '') AS WP_State,
                    CC.Activation_State AS WPActivationState,
                    RR.RDS_EUS_Proposal_ID AS Proposal,
                    EPT.Abbreviation AS Proposal_Type,
                    RRB.Locked,
                    RRB.Requested_Batch_Priority,
                    RR.RDS_BatchID AS Batch,
                    RRB.Comment As Batch_Comment,
                    RRB.Batch_Group_ID,
                    QS.Queue_State_Name AS Queue_State,
                    CASE WHEN RR.Queue_State = 2 THEN Coalesce(AssignedInstrument.IN_name, '') ELSE '' END AS Queued_Instrument,
                    LEFT(RRB.Batch, 20) + CASE WHEN LEN(RRB.Batch) > 20 THEN '...'
                                            ELSE ''
                                        END AS Batch_Prefix,
                    Cast(RRB.Last_Ordered AS Date) AS Last_Ordered,
                    CASE
                        WHEN SPR.ID = 0 THEN NULL
                        ELSE QT.Days_In_Queue
                    END AS Days_in_Prep_Queue,
                    CASE
                        WHEN Coalesce(SPR.BlockAndRandomizeRuns, '') = 'yes' AND (
                            Coalesce(RR.RDS_Block, 0) = 0 Or Coalesce(RR.RDS_Run_Order, 0) = 0) THEN 1
                        ELSE 0
                    END AS Block_Missing,
                    CASE
                        WHEN Coalesce(RR.RDS_Block, 0) > 0 AND
                            Coalesce(RR.RDS_Run_Order, 0) > 0 THEN 1
                        ELSE 0
                    END AS Blocked,
                    SG.Fraction_Count As Fraction_Count
             FROM T_Dataset_Type_Name AS DTN
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
      GROUP BY Inst_Group,
               Separation_Group,
               Fraction_Count,
               DS_Type,
               Request_Name_Code,
               Requester,
               Work_Package,
               WP_State,
               WPActivationState,
               Proposal,
               Proposal_Type,
               Locked,
               Last_Ordered,
               Queue_State,
               Queued_Instrument,
               Batch,
               Batch_Prefix,
               Requested_Batch_Priority,
               Batch_Comment,
               Batch_Group_ID
    ) AS GroupQ
    INNER JOIN T_Requested_Run AS RequestLookupQ
        ON GroupQ.Min_Request = RequestLookupQ.ID
    INNER JOIN T_EUS_UsageType AS TEUT
        ON RequestLookupQ.RDS_EUS_UsageType = TEUT.ID
    -- LEFT OUTER JOIN T_Cached_Instrument_Usage_by_Proposal AS TAC
    --     ON TAC.IN_Group = GroupQ.Inst_Group AND TAC.EUS_Proposal_ID = GroupQ.Proposal

GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Planning_Report] TO [DDL_Viewer] AS [dbo]
GO
