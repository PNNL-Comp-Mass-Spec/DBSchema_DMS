/****** Object:  View [dbo].[V_EUS_Proposal_Users_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_EUS_Proposal_Users_List_Report
AS
SELECT     dbo.T_EUS_Proposal_Users.Person_ID AS [EUS Person ID], dbo.T_EUS_Proposal_Users.Of_DMS_Interest AS [DMS Interest], 
                      dbo.T_EUS_Users.NAME_FM AS Name, dbo.T_EUS_Site_Status.Name AS [Site Status], 
                      dbo.T_EUS_Proposal_Users.Proposal_ID AS [#EUS Proposal ID]
FROM         dbo.T_EUS_Proposal_Users INNER JOIN
                      dbo.T_EUS_Users ON dbo.T_EUS_Proposal_Users.Person_ID = dbo.T_EUS_Users.PERSON_ID INNER JOIN
                      dbo.T_EUS_Site_Status ON dbo.T_EUS_Users.Site_Status = dbo.T_EUS_Site_Status.ID

GO
