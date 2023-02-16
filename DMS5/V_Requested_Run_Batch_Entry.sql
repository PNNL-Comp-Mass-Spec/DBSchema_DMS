/****** Object:  View [dbo].[V_Requested_Run_Batch_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Batch_Entry]
AS
SELECT RRB.id,
       RRB.Batch AS name,
       RRB.description,
       dbo.GetBatchRequestedRunList(RRB.ID) AS requested_run_list,
       U.U_PRN AS owner_username,
       RRB.Requested_Batch_Priority AS requested_batch_priority,
       RRB.Requested_Completion_Date AS requested_completion_date,
       RRB.Justification_for_High_Priority AS justification_high_priority,
       RRB.Requested_Instrument AS requested_instrument,
       RRB.comment,
       RRB.Batch_Group_id AS batch_group,
       RRB.Batch_Group_Order AS batch_group_order
FROM dbo.T_Requested_Run_Batches RRB
     INNER JOIN dbo.T_Users U
       ON RRB.Owner = U.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Entry] TO [DDL_Viewer] AS [dbo]
GO
