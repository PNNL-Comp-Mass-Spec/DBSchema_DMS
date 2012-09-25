/****** Object:  View [dbo].[V_Mage_FPkg_Data_Package_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Mage_FPkg_Data_Package_Analysis_Jobs as
SELECT  VMA.Job ,
        VMA.State ,
        VMA.Dataset ,
        VMA.Dataset_ID ,
        VMA.Tool ,
        VMA.Parameter_File ,
        VMA.Settings_File ,
        VMA.Instrument ,
        VMA.Experiment ,
        VMA.Campaign ,
        VMA.Organism ,
        VMA.[Organism DB] ,
        VMA.[Protein Collection List] ,
        VMA.[Protein Options] ,
        VMA.Comment ,
        TPA.Data_Package_ID ,
        TPA.[Package Comment] ,
        VMA.Folder ,
        VMA.Storage_Path ,
        VMA.Purged ,
        VMA.Archive_Path
FROM    V_Mage_FPkg_Analysis_Jobs AS VMA
        INNER JOIN S_V_Data_Package_Analysis_Jobs_Export AS TPA ON VMA.Job = TPA.Job
GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Data_Package_Analysis_Jobs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Data_Package_Analysis_Jobs] TO [PNL\D3M580] AS [dbo]
GO
