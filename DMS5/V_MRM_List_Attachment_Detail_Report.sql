/****** Object:  View [dbo].[V_MRM_List_Attachment_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_MRM_List_Attachment_Detail_Report
AS
SELECT id, attachment_name as name, attachment_description as description, owner_prn as owner, active, created, file_name, contents
FROM T_Attachments
WHERE Attachment_Type = 'MRM Transition List'

GO
GRANT VIEW DEFINITION ON [dbo].[V_MRM_List_Attachment_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
