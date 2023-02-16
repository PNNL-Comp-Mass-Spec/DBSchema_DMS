/****** Object:  View [dbo].[V_Requested_Run_Batch_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Batch_Detail_Report]
AS
SELECT RRB.id,
       RRB.Batch AS name,
       RRB.description,
       dbo.GetBatchRequestedRunList(RRB.ID) AS requests,
       ISNULL(FC.factor_count, 0) AS factors,
       U.Name_with_PRN AS owner,
       RRB.created,
       RRB.locked,
       RRB.Last_Ordered AS last_ordered,
       RRB.Requested_Batch_Priority AS requested_batch_priority,
       RRB.Requested_Completion_Date AS requested_completion_date,
       RRB.Justification_for_High_Priority AS justification_for_high_priority,
       dbo.GetBatchDatasetInstrumentList(RRB.ID) AS instrument_used,
       RRB.Requested_Instrument AS instrument_group,
       RRB.comment,
       CASE WHEN RBS.separation_group_first = RBS.separation_group_last
            THEN RBS.separation_group_first
            ELSE RBS.separation_group_first + ' - ' + RBS.separation_group_last
       END AS separation_group,
       RRB.Batch_Group_id AS batch_group,
       RRB.Batch_Group_Order AS batch_group_order
FROM dbo.T_Requested_Run_Batches RRB
     INNER JOIN dbo.T_Users U
       ON RRB.Owner = U.ID
     LEFT OUTER JOIN dbo.V_Factor_Count_By_Req_Run_Batch AS FC
       ON FC.Batch_ID = RRB.ID
     LEFT OUTER JOIN T_Cached_Requested_Run_Batch_Stats RBS
       ON RRB.ID = RBS.batch_id

GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
