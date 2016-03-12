/****** Object:  View [dbo].[V_LC_Cart_Config_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[V_LC_Cart_Config_History_List_Report] as
SELECT TIH.ID,
       TIH.Cart,
       TIH.Date_Of_Change AS [Date Of Change],
       TIH.Description,
       CASE
           WHEN DATALENGTH(TIH.Note) < 150 THEN Note
           ELSE SUBSTRING(TIH.Note, 1, 150) + ' (more...)'
       END AS Note,
       TIH.Entered,
       TU.Name_with_PRN AS EnteredBy,
       AttachmentStats.Files
FROM T_LC_Cart_Config_History AS TIH
     LEFT OUTER JOIN T_Users AS TU
       ON TIH.EnteredBy = TU.U_PRN
     LEFT OUTER JOIN ( SELECT ID,
                              Attachments AS Files
                       FROM [V_File_Attachment_Stats_by_ID]
                       WHERE Entity_Type = 'lc_cart_config_history' ) AttachmentStats
       ON TIH.ID = AttachmentStats.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Config_History_List_Report] TO [PNL\D3M578] AS [dbo]
GO
