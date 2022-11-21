/****** Object:  View [dbo].[V_File_Attachment_Display] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_File_Attachment_Display] AS 
SELECT FA.ID,
       FA.File_Name AS Name,
       FA.Description,
       FA.Entity_Type,
       FA.Entity_ID,
       U.U_Name AS Owner,
       FA.File_Size_Bytes AS Bytes,
       FA.Last_Affected,
       FA.Archive_Folder_Path AS [Archive Folder Path],
       FA.File_Mime_Type
FROM T_File_Attachment FA
     INNER JOIN T_Users U
       ON FA.Owner_PRN = U.U_PRN
WHERE FA.Active > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_File_Attachment_Display] TO [DDL_Viewer] AS [dbo]
GO
