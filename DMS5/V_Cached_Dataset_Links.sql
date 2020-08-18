/****** Object:  View [dbo].[V_Cached_Dataset_Links] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Cached_Dataset_Links
AS 
SELECT L.Dataset_ID,
       D.Dataset_Num AS Dataset,
       L.DS_RowVersion,
       L.SPath_RowVersion,
       L.Dataset_Folder_Path,
       L.Archive_Folder_Path,
       L.MyEMSL_URL,
       L.QC_Link,
       L.QC_2D,
       L.QC_Metric_Stats,
       L.MASIC_Directory_Name,
       L.UpdateRequired,
       L.Last_Affected
FROM T_Cached_Dataset_Links AS L
     INNER JOIN T_Dataset AS D
       ON D.Dataset_ID = L.Dataset_ID


GO
