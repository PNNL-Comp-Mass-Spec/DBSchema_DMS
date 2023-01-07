/****** Object:  View [dbo].[V_LC_Cart_Config_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Config_History_List_Report]
AS
SELECT TIH.id,
       TIH.cart,
       TIH.Date_Of_Change AS date_of_change,
       TIH.description,
       CASE
           WHEN DATALENGTH(TIH.Note) < 150 THEN Note
           ELSE SUBSTRING(TIH.note, 1, 150) + ' (more...)'
       END AS note,
       TIH.entered,
       TU.Name_with_PRN AS entered_by,
       AttachmentStats.files
FROM T_LC_Cart_Config_History AS TIH
     LEFT OUTER JOIN T_Users AS TU
       ON TIH.EnteredBy = TU.U_PRN
     LEFT OUTER JOIN ( SELECT ID,
                              Attachments AS Files
                       FROM V_File_Attachment_Stats_by_ID
                       WHERE Entity_Type = 'lc_cart_config_history' ) AttachmentStats
       ON TIH.ID = AttachmentStats.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Config_History_List_Report] TO [DDL_Viewer] AS [dbo]
GO
