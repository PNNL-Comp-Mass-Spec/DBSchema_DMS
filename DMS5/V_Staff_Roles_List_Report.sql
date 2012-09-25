/****** Object:  View [dbo].[V_Staff_Roles_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Staff_Roles_List_Report
AS
SELECT     dbo.T_Users.U_Name AS Person, dbo.T_Research_Team_Roles.Role, dbo.T_Campaign.Campaign_Num AS Campaign, 
                      dbo.T_Campaign.CM_State AS State, dbo.T_Campaign.CM_Project_Num AS Project, dbo.T_Research_Team.Collaborators, 
                      dbo.T_Campaign_Tracking.Most_Recent_Activity
FROM         dbo.T_Research_Team INNER JOIN
                      dbo.T_Research_Team_Membership ON dbo.T_Research_Team.ID = dbo.T_Research_Team_Membership.Team_ID INNER JOIN
                      dbo.T_Research_Team_Roles ON dbo.T_Research_Team_Membership.Role_ID = dbo.T_Research_Team_Roles.ID INNER JOIN
                      dbo.T_Users ON dbo.T_Research_Team_Membership.User_ID = dbo.T_Users.ID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Research_Team.ID = dbo.T_Campaign.CM_Research_Team LEFT OUTER JOIN
                      dbo.T_Campaign_Tracking ON dbo.T_Campaign.Campaign_ID = dbo.T_Campaign_Tracking.C_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Staff_Roles_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Staff_Roles_List_Report] TO [PNL\D3M580] AS [dbo]
GO
