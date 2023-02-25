/****** Object:  View [dbo].[V_Data_Analysis_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Analysis_Request_Entry]
AS
SELECT R.id,
       R.request_name,
       R.analysis_type,
       R.requester_prn AS requester_username,
       R.description,
       R.analysis_specifications,
       R.comment,
       dbo.get_data_analysis_request_batch_list(R.ID) As batch_ids,
       R.data_package_id,
       R.exp_group_id,
       R.work_package,
       R.requested_personnel,
       R.assigned_personnel,
       R.priority,
       R.reason_for_high_priority,
       R.estimated_analysis_time_days,
       SN.state_name,
       R.state_comment
FROM T_Data_Analysis_Request AS R
     INNER JOIN T_Data_Analysis_Request_State_Name AS SN
       ON R.State = SN.State_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Analysis_Request_Entry] TO [DDL_Viewer] AS [dbo]
GO
