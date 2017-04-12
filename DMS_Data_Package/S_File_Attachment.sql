/****** Object:  Synonym [dbo].[S_File_Attachment] ******/
CREATE SYNONYM [dbo].[S_File_Attachment] FOR [DMS5].[dbo].[T_File_Attachment]
GO
GRANT VIEW DEFINITION ON [dbo].[S_File_Attachment] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[S_File_Attachment] TO [DMSWebUser] AS [dbo]
GO
GRANT UPDATE ON [dbo].[S_File_Attachment] TO [DMSWebUser] AS [dbo]
GO
