/****** Object:  View [dbo].[V_File_Attachment_Display] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_File_Attachment_Display] AS SELECT T_File_Attachment.ID, 
	T_File_Attachment.File_Name AS [Name], 
	T_File_Attachment.Description, 
	T_File_Attachment.Entity_Type, 
	T_File_Attachment.Entity_ID, 
	T_Users.U_Name AS Owner, 
	T_File_Attachment.File_Size_Bytes AS Bytes, 
	T_File_Attachment.Last_Affected,
	T_File_Attachment.Archive_Folder_Path AS [Archive Folder Path], 
	T_File_Attachment.File_Mime_Type
FROM T_File_Attachment INNER JOIN T_Users ON T_File_Attachment.Owner_PRN = T_Users.U_PRN
GO
