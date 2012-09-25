/****** Object:  View [dbo].[V_Sample_Submission_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Sample_Submission_List_Report
AS
SELECT     dbo.T_Sample_Submission.ID, dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Users.U_Name + ' (' + dbo.T_Users.U_PRN + ')' AS Received_By,
                       dbo.T_Sample_Submission.Description, dbo.T_Sample_Submission.Container_List, dbo.T_Sample_Submission.Created
FROM         dbo.T_Sample_Submission INNER JOIN
                      dbo.T_Campaign ON dbo.T_Sample_Submission.Campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Users ON dbo.T_Sample_Submission.Received_By_User_ID = dbo.T_Users.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Submission_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Submission_List_Report] TO [PNL\D3M580] AS [dbo]
GO
