/****** Object:  View [dbo].[V_File_Attachment_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_File_Attachment_List_Report AS 
SELECT        T_File_Attachment.ID, T_File_Attachment.File_Name AS [File Name], T_File_Attachment.Description, T_File_Attachment.Entity_Type AS [Entity Type], 
                         T_File_Attachment.Entity_ID AS [Entity ID], T_Users.U_Name + ' (' + T_File_Attachment.Owner_PRN + ')' AS Owner, T_File_Attachment.File_Size_Bytes AS [Size (KB)], 
                         T_File_Attachment.Created, T_File_Attachment.Last_Affected AS [Last Affected]
FROM            T_File_Attachment INNER JOIN
                         T_Users ON T_File_Attachment.Owner_PRN = T_Users.U_PRN
GO
