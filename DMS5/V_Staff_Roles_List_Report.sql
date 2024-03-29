/****** Object:  View [dbo].[V_Staff_Roles_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Staff_Roles_List_Report
AS
SELECT dbo.T_Users.U_Name AS person, dbo.T_Research_Team_Roles.role, dbo.T_Campaign.Campaign_Num AS campaign,
       dbo.T_Campaign.CM_State AS state, dbo.T_Campaign.CM_Project_Num AS project, dbo.T_Research_Team.collaborators,
       dbo.T_Campaign_Tracking.most_recent_activity
FROM dbo.T_Research_Team INNER JOIN
     dbo.T_Research_Team_Membership ON dbo.T_Research_Team.ID = dbo.T_Research_Team_Membership.Team_ID INNER JOIN
     dbo.T_Research_Team_Roles ON dbo.T_Research_Team_Membership.Role_ID = dbo.T_Research_Team_Roles.ID INNER JOIN
     dbo.T_Users ON dbo.T_Research_Team_Membership.User_ID = dbo.T_Users.ID INNER JOIN
     dbo.T_Campaign ON dbo.T_Research_Team.ID = dbo.T_Campaign.CM_Research_Team LEFT OUTER JOIN
     dbo.T_Campaign_Tracking ON dbo.T_Campaign.Campaign_ID = dbo.T_Campaign_Tracking.C_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Staff_Roles_List_Report] TO [DDL_Viewer] AS [dbo]
GO
