/****** Object:  View [dbo].[V_File_Attachment_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_File_Attachment_List_Report] AS 
SELECT FA.ID,
       FA.File_Name AS [File Name],
       FA.Description,
       FA.Entity_Type AS [Entity Type],
       FA.Entity_ID AS [Entity ID],
       U.Name_with_PRN AS Owner,
       FA.File_Size_Bytes AS [Size (KB)],
       FA.Created,
       FA.Last_Affected AS [Last Affected]
FROM dbo.T_File_Attachment FA
     INNER JOIN dbo.T_Users U
       ON FA.Owner_PRN = U.U_PRN
WHERE FA.Active > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_File_Attachment_List_Report] TO [DDL_Viewer] AS [dbo]
GO
