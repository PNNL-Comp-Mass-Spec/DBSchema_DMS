/****** Object:  View [dbo].[V_Mage_Dataset_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mage_Dataset_List] AS 
SELECT DL.ID AS Dataset_ID,
       DL.Dataset,
       DL.Experiment,
       DL.Campaign,
       DL.State,
       DL.Instrument,
       DL.Created,
       DL.[Dataset Type] AS Type,
       Case When ISNULL(DA.AS_instrument_data_purged, 0) = 0 
       Then DL.[Dataset Folder Path]
       Else DL.[Archive Folder Path] 
       End AS Folder,
       DL.Comment
FROM V_Dataset_List_Report_2 DL LEFT OUTER JOIN
    T_Dataset_Archive DA ON DL.ID = DA.AS_Dataset_ID


GO
