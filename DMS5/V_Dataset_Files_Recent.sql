/****** Object:  View [dbo].[V_Dataset_Files_Recent] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Dataset_Files_Recent
AS
SELECT DF.Dataset_ID,
       DS.Dataset_Num AS Dataset,
       DF.File_Hash,
       DS_Created AS Dataset_Created
FROM T_Dataset_Files DF
     INNER JOIN T_Dataset DS
       ON DS.Dataset_ID = DF.Dataset_ID
WHERE DF.Allow_Duplicates = 0 AND
      DF.Deleted = 0 AND
      DS.DS_created >= GetDate() - 180

GO
