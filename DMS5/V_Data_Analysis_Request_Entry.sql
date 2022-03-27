/****** Object:  View [dbo].[V_Data_Analysis_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Analysis_Request_Entry]
AS
SELECT R.ID,
       R.Request_Name,
       R.Analysis_Type,
       R.Requester_PRN,
       R.Description,
       R.Analysis_Specifications,
       R.Comment,
       dbo.GetDataAnalysisRequestBatchList(R.ID) As Batch_IDs,
       R.Data_Package_ID,
       R.Exp_Group_ID,
       R.Work_Package,
       R.Requested_Personnel,
       R.Assigned_Personnel,
       R.Priority,
       R.Reason_For_High_Priority,
       R.Estimated_Analysis_Time_Days,
       T_Data_Analysis_Request_State_Name.State_Name,
       R.State_Comment
FROM T_Data_Analysis_Request AS R
     INNER JOIN T_Data_Analysis_Request_State_Name
       ON R.State = T_Data_Analysis_Request_State_Name.State_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Analysis_Request_Entry] TO [DDL_Viewer] AS [dbo]
GO
