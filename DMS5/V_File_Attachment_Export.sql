/****** Object:  View [dbo].[V_File_Attachment_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_File_Attachment_Export] AS 
SELECT FA.ID As Attachment_ID,
       FA.File_Name,
       FA.Description,
       FA.Entity_Type,
       FA.Entity_ID,
       U.Name_with_PRN AS Owner,
       FA.File_Size_Bytes AS File_Size_KB,
       FA.Created,
       FA.Last_Affected,
       FA.Archive_Folder_Path,
       FA.Active
FROM dbo.T_File_Attachment FA
     INNER JOIN dbo.T_Users U
       ON FA.Owner_PRN = U.U_PRN


GO
