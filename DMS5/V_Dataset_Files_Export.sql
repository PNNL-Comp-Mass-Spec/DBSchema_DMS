/****** Object:  View [dbo].[V_Dataset_Files_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Dataset_Files_Export]
AS
SELECT DF.dataset_id,
       DF.file_path,
       DF.file_size_bytes,
       DF.file_hash
FROM T_Dataset_Files DF
WHERE Deleted = 0

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Files_Export] TO [DDL_Viewer] AS [dbo]
GO
