/****** Object:  View [dbo].[V_Requested_Run_Batch_Group_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Requested_Run_Batch_Group_Detail_Report]
AS
SELECT BG.batch_group_id AS id,
       BG.batch_group AS name,
       BG.description,
       dbo.get_batch_group_member_list(BG.batch_group_id) AS batches,
       dbo.get_batch_group_requested_run_list(BG.batch_group_id) AS requests,
       U.Name_with_PRN AS owner,
       BG.created,
       dbo.get_batch_group_instrument_group_list(BG.batch_group_id) AS instrument_group
FROM T_Requested_Run_Batch_Group BG
     LEFT OUTER JOIN dbo.T_Users U
       ON BG.Owner_User_ID = U.ID;

GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Group_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
