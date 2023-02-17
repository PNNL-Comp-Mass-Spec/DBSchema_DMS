/****** Object:  Synonym [dbo].[s_get_dms_file_storage_path] ******/
CREATE SYNONYM [dbo].[s_get_dms_file_storage_path] FOR [DMS5].[dbo].[GetDMSFileStoragePath]
GO
GRANT VIEW DEFINITION ON [dbo].[s_get_dms_file_storage_path] TO [DDL_Viewer] AS [dbo]
GO
