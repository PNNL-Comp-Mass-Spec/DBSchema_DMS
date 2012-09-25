/****** Object:  View [dbo].[V_File_Attachment_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 
CREATE VIEW V_File_Attachment_List_Report AS 
SELECT  dbo.T_File_Attachment.ID ,
        dbo.T_File_Attachment.File_Name AS [File Name] ,
        dbo.T_File_Attachment.Description ,
        dbo.T_File_Attachment.Entity_Type AS [Entity Type] ,
        dbo.T_File_Attachment.Entity_ID AS [Entity ID] ,
        dbo.T_Users.U_Name + ' (' + dbo.T_File_Attachment.Owner_PRN + ')' AS Owner ,
        dbo.T_File_Attachment.File_Size_Bytes AS [Size (KB)] ,
        dbo.T_File_Attachment.Created ,
        dbo.T_File_Attachment.Last_Affected AS [Last Affected]
FROM    dbo.T_File_Attachment
        INNER JOIN dbo.T_Users ON dbo.T_File_Attachment.Owner_PRN = dbo.T_Users.U_PRN
WHERE   ACTIVE > 0
GO
GRANT VIEW DEFINITION ON [dbo].[V_File_Attachment_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_File_Attachment_List_Report] TO [PNL\D3M580] AS [dbo]
GO
