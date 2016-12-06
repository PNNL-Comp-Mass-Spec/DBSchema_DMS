/****** Object:  View [dbo].[V_File_Attachment_Stats_by_ID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--
CREATE VIEW [dbo].[V_File_Attachment_Stats_by_ID] AS 
SELECT Entity_Type, Entity_ID AS ID, COUNT(*) AS Attachments
FROM T_File_Attachment
WHERE Active > 0
GROUP BY Entity_Type, Entity_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_File_Attachment_Stats_by_ID] TO [DDL_Viewer] AS [dbo]
GO
