/****** Object:  View [dbo].[V_Mage_FPkg_Dataset_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view V_Mage_FPkg_Dataset_List as 
SELECT  DL.ID AS Dataset_ID ,
        DL.Dataset ,
        DL.Experiment ,
        DL.Campaign ,
        DL.State ,
        DL.Instrument ,
        DL.Created ,
        DL.[Dataset Type] AS Type ,
        CASE WHEN ISNULL(DA.AS_instrument_data_purged, 0) = 0
             THEN DL.[Dataset Folder Path]
             ELSE DL.[Archive Folder Path]
        END AS Folder ,
        DL.[Archive Folder Path] AS Archive_Path,
        DL.Comment
FROM    dbo.V_Dataset_List_Report_2 AS DL
        LEFT OUTER JOIN dbo.T_Dataset_Archive AS DA ON DL.ID = DA.AS_Dataset_ID

GO
