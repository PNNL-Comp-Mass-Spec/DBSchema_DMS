/****** Object:  View [dbo].[V_Requested_Run_Batch_Pending_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Batch_Pending_List_Report]
AS
SELECT id,
       name,
       requests,
       runs,
       blocked,
       block_missing,
       first_request,
       last_request,
       req_priority,
       instrument,
       inst_group,
       description,
       owner,
       created,
       days_in_queue,
       complete_by,
       days_in_prep_queue,
       justification_for_high_priority,
       comment,
       separation_group,
       days_in_queue_bin
FROM V_Requested_Run_Batch_List_Report
WHERE Requests > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Pending_List_Report] TO [DDL_Viewer] AS [dbo]
GO
