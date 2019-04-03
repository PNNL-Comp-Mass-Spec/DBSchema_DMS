/****** Object:  View [dbo].[V_Data_Package_Dataset_Files_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Dataset_Files_List_Report]
AS
SELECT DPD.Data_Package_ID AS ID,
       DPD.Dataset,
       DPD.Dataset_ID,
       DF.File_Path AS [File Path],
       DF.File_Size_Bytes AS [File Size Bytes],
       DF.File_Hash AS [File Hash],
       DF.File_Size_Rank AS [File Size Rank],
       DPD.Experiment,
       DPD.Instrument,
       DPD.[Package Comment],
       DL.Campaign,
       DL.[State],
       DL.Created,
       DL.Rating,
       DL.[Dataset Folder Path],
       DL.[Acq Start],
       DL.[Acq. End],
       DL.[Acq Length],
       DL.[Scan Count],
       DL.[LC Column],
       DL.[Separation Type],
       DL.Request,
       DPD.[Item Added],
       DL.[Comment],
       DL.[Dataset Type] AS [Type]
FROM dbo.T_Data_Package_Datasets AS DPD
     INNER JOIN dbo.S_V_Dataset_List_Report_2 AS DL
       ON DPD.Dataset_ID = DL.ID
     LEFT OUTER JOIN (
        SELECT Dataset_ID,
               File_Path,
               File_Size_Bytes,
               File_Hash,
               File_Size_Rank,
               Dataset_File_ID
        FROM dbo.S_Dataset_Files
        WHERE Deleted = 0
     ) DF ON DPD.Dataset_ID = DF.Dataset_ID


GO
