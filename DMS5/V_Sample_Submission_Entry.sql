/****** Object:  View [dbo].[V_Sample_Submission_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Sample_Submission_Entry
AS
SELECT     dbo.T_Sample_Submission.ID, dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Users.U_PRN AS ReceivedBy, 
                      dbo.T_Sample_Submission.Description, dbo.T_Sample_Submission.Container_List AS ContainerList, '' AS NewContainerComment
FROM         dbo.T_Sample_Submission INNER JOIN
                      dbo.T_Campaign ON dbo.T_Sample_Submission.Campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Users ON dbo.T_Sample_Submission.Received_By_User_ID = dbo.T_Users.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Submission_Entry] TO [DDL_Viewer] AS [dbo]
GO
