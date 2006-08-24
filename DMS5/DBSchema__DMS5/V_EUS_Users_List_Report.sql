/****** Object:  View [dbo].[V_EUS_Users_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_EUS_Users_List_Report
AS
SELECT     dbo.T_EUS_Users.PERSON_ID AS ID, dbo.T_EUS_Users.NAME_FM AS Name, dbo.T_EUS_Site_Status.Name AS [Site Status]
FROM         dbo.T_EUS_Users INNER JOIN
                      dbo.T_EUS_Site_Status ON dbo.T_EUS_Users.Site_Status = dbo.T_EUS_Site_Status.ID

GO
