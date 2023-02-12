/****** Object:  View [dbo].[V_Requested_Run_Batch_Group_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Batch_Group_List_Report]
AS
SELECT BG.batch_group_id AS id,
       BG.batch_group AS name,
       dbo.GetBatchGroupMemberList(BG.batch_group_id) AS batches,
       StatsQ.requests,
       StatsQ.first_request,
       StatsQ.last_request,
       dbo.GetBatchGroupInstrumentGroupList(BG.batch_group_id) AS instrument_group,
       BG.description,
       T_Users.U_Name AS owner,
       BG.created
FROM T_Requested_Run_Batch_Group BG
     LEFT JOIN T_Users
       ON BG.owner_user_id = t_users.ID
     LEFT JOIN ( SELECT RRB.batch_group_id,
                        count(*) AS requests,
                        min(RR.ID) AS first_request,
                        max(RR.ID) AS last_request,
                        min(RR.RDS_created) AS oldest_request_created
                 FROM T_Requested_Run RR
                      JOIN T_Requested_Run_Batches RRB
                        ON RR.RDS_BatchID = RRB.ID
                 WHERE NOT RRB.batch_group_id IS NULL
                 GROUP BY RRB.batch_group_id ) StatsQ
       ON BG.batch_group_id = StatsQ.batch_group_id;


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Group_List_Report] TO [DDL_Viewer] AS [dbo]
GO
