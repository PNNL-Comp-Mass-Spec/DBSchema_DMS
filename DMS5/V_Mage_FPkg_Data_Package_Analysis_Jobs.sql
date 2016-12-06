/****** Object:  View [dbo].[V_Mage_FPkg_Data_Package_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE view [dbo].[V_Mage_FPkg_Data_Package_Analysis_Jobs] AS
/*
 * This view was used by the File Packager tool written by Gary Kiebel in 2012
 * As of September 2013 this tool is not in use and thus this view could likely be deleted in the future
 */
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
        DPJ.Data_Package_ID ,
        DPJ.[Package Comment] ,
        VMA.Folder ,
        VMA.Storage_Path ,
        VMA.Purged ,
        VMA.Archive_Path
FROM V_Mage_FPkg_Analysis_Jobs AS VMA
     INNER JOIN S_V_Data_Package_Analysis_Jobs_Export AS DPJ
       ON VMA.Job = DPJ.Job



GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Data_Package_Analysis_Jobs] TO [DDL_Viewer] AS [dbo]
GO
