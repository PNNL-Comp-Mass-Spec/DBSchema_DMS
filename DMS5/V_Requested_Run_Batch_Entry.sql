/****** Object:  View [dbo].[V_Requested_Run_Batch_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Batch_Entry]
AS
SELECT R.id,
       R.Batch AS name,
       R.description,
       dbo.GetBatchRequestedRunList(R.ID) AS requested_run_list,
       U.U_PRN AS owner_prn,
       R.Requested_Batch_Priority AS requested_batch_priority,
       R.Requested_Completion_Date AS requested_completion_date,
       R.Justification_for_High_Priority AS justification_high_priority,
       R.Requested_Instrument AS requested_instrument,
       R.comment
FROM dbo.T_Requested_Run_Batches R
     INNER JOIN dbo.T_Users U
       ON R.Owner = U.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Entry] TO [DDL_Viewer] AS [dbo]
GO
