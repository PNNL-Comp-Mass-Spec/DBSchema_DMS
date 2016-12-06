/****** Object:  View [dbo].[V_Sample_Submission_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Submission_List_Report]
AS
SELECT SS.ID,
       C.Campaign_Num AS Campaign,
       U.Name_with_PRN AS Received_By,
       SS.Description,
       SS.Container_List,
       SS.Created
FROM dbo.T_Sample_Submission SS
     INNER JOIN dbo.T_Campaign C
       ON SS.Campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Users U
       ON SS.Received_By_User_ID = U.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Submission_List_Report] TO [DDL_Viewer] AS [dbo]
GO
