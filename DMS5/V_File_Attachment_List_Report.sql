/****** Object:  View [dbo].[V_File_Attachment_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_File_Attachment_List_Report]
AS
SELECT FA.id,
       FA.file_name,
       FA.description,
       FA.entity_type,
       FA.entity_id,
       U.Name_with_PRN AS owner,
       FA.File_Size_Bytes AS size_kb,
       FA.created,
       FA.last_affected
FROM dbo.T_File_Attachment FA
     INNER JOIN dbo.T_Users U
       ON FA.Owner_PRN = U.U_PRN
WHERE FA.Active > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_File_Attachment_List_Report] TO [DDL_Viewer] AS [dbo]
GO
