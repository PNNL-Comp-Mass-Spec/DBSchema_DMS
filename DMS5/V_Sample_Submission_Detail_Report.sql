/****** Object:  View [dbo].[V_Sample_Submission_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Submission_Detail_Report]
AS
SELECT SS.id,
       C.Campaign_Num AS campaign,
       U.Name_with_PRN AS received_by,
       SS.description,
       SS.Container_List AS container_list,
       SS.created
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
