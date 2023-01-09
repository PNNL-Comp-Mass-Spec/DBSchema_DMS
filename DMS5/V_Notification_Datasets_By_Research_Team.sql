/****** Object:  View [dbo].[V_Notification_Datasets_By_Research_Team] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Notification_Datasets_By_Research_Team] as
SELECT DISTINCT TNE.ID AS seq,
                TET.Name AS event,
                T.Dataset_ID AS entity,
                T.Dataset_Num AS name,
                T.campaign,
                person,
                person_role,
                TNE.entered,
                TET.Target_Entity_Type AS entity_type,
                T.prn,
                TET.ID AS event_type,
                TNE.Event_Type AS event_type_id,
                TET.link_template
FROM T_Notification_Event TNE
     INNER JOIN T_Notification_Event_Type AS TET
       ON TET.ID = TNE.Event_Type
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
       ON T.Dataset_ID = TNE.Target_ID
WHERE TET.Target_Entity_Type = 4 AND
      TET.Visible = 'Y'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Datasets_By_Research_Team] TO [DDL_Viewer] AS [dbo]
GO
