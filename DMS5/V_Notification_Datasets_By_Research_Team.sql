/****** Object:  View [dbo].[V_Notification_Datasets_By_Research_Team] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Notification_Datasets_By_Research_Team as 
SELECT DISTINCT TOP ( 100 ) PERCENT
  TNE.ID AS Seq,
  TET.Name AS Event,
  T.Dataset_ID AS Entity,
  T.Dataset_Num AS Name,
  T.Campaign,
  T.[User],
  T.Role,
  TNE.Entered,
  TET.Target_Entity_Type AS [#EntityType],
  T.[#PRN],
  TET.ID AS EventType,
  TNE.Event_Type AS EventTypeID,
  TET.Link_Template
FROM
  T_Notification_Event TNE
  INNER JOIN T_Notification_Event_Type AS TET ON TET.ID = TNE.Event_Type
  INNER JOIN ( SELECT
                T_Dataset.Dataset_ID,
                T_Dataset.Dataset_Num,
                T_Campaign.Campaign_Num AS Campaign,
                T_Users.U_Name AS [User],
                dbo.GetResearchTeamUserRoleList(SRTM.Team_ID, SRTM.User_ID) AS Role,
                T_Users.U_PRN AS [#PRN]
               FROM
                T_Dataset
                INNER JOIN T_Experiments ON T_Dataset.Exp_ID = T_Experiments.Exp_ID
                INNER JOIN T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
                INNER JOIN T_Research_Team ON T_Campaign.CM_Research_Team = T_Research_Team.ID
                INNER JOIN T_Research_Team_Membership AS SRTM ON T_Research_Team.ID = SRTM.Team_ID
                INNER JOIN T_Users ON SRTM.User_ID = T_Users.ID
                INNER JOIN T_Research_Team_Roles AS SRTR ON SRTM.Role_ID = SRTR.ID
               WHERE
                ( T_Campaign.CM_State = 'Active' )
             ) AS T ON T.Dataset_ID = TNE.Target_ID
WHERE
   TET.Target_Entity_Type = 4
   AND (TET.Visible = 'Y')
GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Datasets_By_Research_Team] TO [PNL\D3M578] AS [dbo]
GO
