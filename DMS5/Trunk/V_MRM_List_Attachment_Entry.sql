/****** Object:  View [dbo].[V_MRM_List_Attachment_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_MRM_List_Attachment_Entry
AS
SELECT 
    ID AS ID, 
    Attachment_Type AS AttachmentType, 
    Attachment_Name AS AttachmentName, 
    Attachment_Description AS AttachmentDescription, 
    Owner_PRN AS OwnerPRN, 
    Active AS Active, 
    Contents AS Contents, 
    File_Name AS FileName
FROM T_Attachments


GO
GRANT VIEW DEFINITION ON [dbo].[V_MRM_List_Attachment_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_MRM_List_Attachment_Entry] TO [PNL\D3M580] AS [dbo]
GO
