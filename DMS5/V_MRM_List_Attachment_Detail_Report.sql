/****** Object:  View [dbo].[V_MRM_List_Attachment_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_MRM_List_Attachment_Detail_Report AS 
SELECT        ID, Attachment_Name AS Name, Attachment_Description AS Description, Owner_PRN AS Owner, Active, Created, [File_Name] AS [File Name], Contents
FROM            T_Attachments
WHERE        (Attachment_Type = 'MRM Transition List')
GO
GRANT VIEW DEFINITION ON [dbo].[V_MRM_List_Attachment_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
