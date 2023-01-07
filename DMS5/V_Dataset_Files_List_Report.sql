/****** Object:  View [dbo].[V_Dataset_Files_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Files_List_Report]
AS
SELECT DF.dataset_id,
       DS.Dataset_Num AS dataset,
       DF.file_path,
       DF.file_size_bytes,
       DF.file_hash,
       DF.file_size_rank,
       InstName.IN_name AS instrument,
       DF.dataset_file_id
FROM T_Dataset_Files DF
     INNER JOIN T_Dataset DS
       ON DF.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
WHERE Deleted = 0


GO
