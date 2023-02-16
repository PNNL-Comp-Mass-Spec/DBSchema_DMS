/****** Object:  View [dbo].[V_Requested_Run_Batch_Group_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Batch_Group_Entry]
AS
SELECT BG.batch_group_id AS id,
       BG.batch_group AS name,
       BG.description,
       dbo.GetBatchGroupMemberList(BG.batch_group_id) AS requested_run_batch_list,
       U.U_Name AS owner_username
FROM T_Requested_Run_Batch_Group BG
      LEFT Outer JOIN T_Users U
        ON BG.owner_user_id = U.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Group_Entry] TO [DDL_Viewer] AS [dbo]
GO
