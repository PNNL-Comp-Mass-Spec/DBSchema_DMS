/****** Object:  View [dbo].[V_MRM_List_Attachment_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MRM_List_Attachment_Entry]
AS
SELECT
    id,
    attachment_type,
    attachment_name,
    attachment_description,
    owner_prn AS owner_username,
    active,
    contents,
    file_name
FROM T_Attachments

GO
GRANT VIEW DEFINITION ON [dbo].[V_MRM_List_Attachment_Entry] TO [DDL_Viewer] AS [dbo]
GO
