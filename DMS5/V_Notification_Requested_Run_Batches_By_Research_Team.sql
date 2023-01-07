/****** Object:  View [dbo].[V_Notification_Requested_Run_Batches_By_Research_Team] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Notification_Requested_Run_Batches_By_Research_Team] AS
SELECT DISTINCT TNE.ID AS Seq,
                TET.Name AS Event,
                T_Requested_Run_Batches.ID AS Entity,
                T_Requested_Run_Batches.Batch AS Name,
                T.Campaign,
                Person,
                Person_Role,
                TNE.Entered,
                TET.Target_Entity_Type AS entity_type,
                T.prn,
                TET.ID AS Event_Type,
                TNE.Event_Type AS Event_Type_ID,
                TET.Link_Template
FROM T_Notification_Event TNE
     INNER JOIN T_Notification_Event_Type AS TET
       ON TET.ID = TNE.Event_Type
     INNER JOIN T_Requested_Run_Batches
       ON TNE.Target_ID = T_Requested_Run_Batches.ID
     INNER JOIN T_Requested_Run
       ON T_Requested_Run_Batches.ID = T_Requested_Run.RDS_BatchID
     INNER JOIN ( SELECT T_Dataset.Dataset_ID,
                         T_Dataset.Dataset_Num,
                         T_Campaign.Campaign_Num AS Campaign,
                         T_Users.U_Name AS Person,
                         dbo.GetResearchTeamUserRoleList(SRTM.Team_ID, SRTM.User_ID) AS Person_Role,
                         T_Users.U_PRN AS prn
                  FROM T_Dataset
                       INNER JOIN T_Experiments
                         ON T_Dataset.Exp_ID = T_Experiments.Exp_ID
                       INNER JOIN T_Campaign
                         ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
                       INNER JOIN T_Research_Team
                         ON T_Campaign.CM_Research_Team = T_Research_Team.ID
                       INNER JOIN T_Research_Team_Membership AS SRTM
                         ON T_Research_Team.ID = SRTM.Team_ID
                       INNER JOIN T_Users
                         ON SRTM.User_ID = T_Users.ID
                       INNER JOIN T_Research_Team_Roles AS SRTR
                         ON SRTM.Role_ID = SRTR.ID
                  WHERE T_Campaign.CM_State = 'Active' AND
                        T_Users.U_active = 'Y'
                ) AS T
       ON T.Dataset_ID = T_Requested_Run.DatasetID
WHERE TET.Target_Entity_Type = 1 AND
      TET.Visible = 'Y' AND
      T_Requested_Run_Batches.ID <> 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Requested_Run_Batches_By_Research_Team] TO [DDL_Viewer] AS [dbo]
GO
