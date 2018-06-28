/****** Object:  View [dbo].[V_Dataset_Files_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Files_List_Report]
AS
SELECT DF.Dataset_ID,
       DS.Dataset_Num AS Dataset,
       DF.File_Path,
       DF.File_Size_Bytes,
       DF.File_Hash,
       DF.File_Size_Rank,
       InstName.IN_name AS Instrument,
       DF.Dataset_File_ID
FROM T_Dataset_Files DF
     INNER JOIN T_Dataset DS
       ON DF.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
WHERE Deleted = 0


GO
