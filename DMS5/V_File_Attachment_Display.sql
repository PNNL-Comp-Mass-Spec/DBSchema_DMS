/****** Object:  View [dbo].[V_File_Attachment_Display] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--
CREATE VIEW V_File_Attachment_Display AS 
SELECT  dbo.T_File_Attachment.ID ,
        dbo.T_File_Attachment.File_Name AS Name ,
        dbo.T_File_Attachment.Description ,
        dbo.T_File_Attachment.Entity_Type ,
        dbo.T_File_Attachment.Entity_ID ,
        dbo.T_Users.U_Name AS Owner ,
        dbo.T_File_Attachment.File_Size_Bytes AS Bytes ,
        dbo.T_File_Attachment.Last_Affected ,
        dbo.T_File_Attachment.Archive_Folder_Path AS [Archive Folder Path] ,
        dbo.T_File_Attachment.File_Mime_Type
FROM    dbo.T_File_Attachment
        INNER JOIN dbo.T_Users ON dbo.T_File_Attachment.Owner_PRN = dbo.T_Users.U_PRN
        WHERE T_File_Attachment.Active > 0
GO
GRANT VIEW DEFINITION ON [dbo].[V_File_Attachment_Display] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_File_Attachment_Display] TO [PNL\D3M580] AS [dbo]
GO
