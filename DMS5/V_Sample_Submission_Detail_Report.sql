/****** Object:  View [dbo].[V_Sample_Submission_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Submission_Detail_Report]
AS
SELECT SS.ID,
       C.Campaign_Num AS Campaign,
       U.Name_with_PRN AS [Received By],
       SS.Description,
       SS.Container_List AS [Container List],
       SS.Created
FROM dbo.T_Sample_Submission AS SS
     INNER JOIN dbo.T_Campaign AS C
       ON SS.Campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Users AS U
       ON SS.Received_By_User_ID = U.ID
     LEFT OUTER JOIN dbo.T_Prep_File_Storage AS PFS
       ON SS.Storage_Path = PFS.ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Submission_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
