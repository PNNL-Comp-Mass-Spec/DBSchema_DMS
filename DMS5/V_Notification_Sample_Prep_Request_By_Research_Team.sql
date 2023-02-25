/****** Object:  View [dbo].[V_Notification_Sample_Prep_Request_By_Research_Team] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Notification_Sample_Prep_Request_By_Research_Team] AS
SELECT DISTINCT TNE.ID AS seq,
                TET.Name AS event,
                T_Sample_Prep_Request.ID AS entity,
                T_Sample_Prep_Request.Request_Name AS name,
                T.campaign,
                person,
                person_role,
                TNE.entered,
                TET.Target_Entity_Type AS entity_type,
                T.username,
                TET.ID AS event_type,
                TNE.Event_Type AS event_type_id,
                TET.link_template
FROM T_Notification_Event TNE
     INNER JOIN T_Notification_Event_Type AS TET
       ON TET.ID = TNE.Event_Type
     INNER JOIN T_Sample_Prep_Request
       ON TNE.Target_ID = T_Sample_Prep_Request.ID
     INNER JOIN T_Sample_Prep_Request_State_Name
       ON T_Sample_Prep_Request.State = T_Sample_Prep_Request_State_Name.State_ID
     INNER JOIN ( SELECT T_Campaign.Campaign_Num AS Campaign,
                         T_Users.U_Name AS Person,
                         dbo.get_research_team_user_role_list(SRTM.Team_ID, SRTM.User_ID) AS Person_Role,
                         T_Users.U_PRN AS username
                  FROM T_Campaign
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
       ON T.Campaign = T_Sample_Prep_Request.Campaign
WHERE TET.Target_Entity_Type = 3 AND
      TET.Visible = 'Y'

GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Sample_Prep_Request_By_Research_Team] TO [DDL_Viewer] AS [dbo]
GO
