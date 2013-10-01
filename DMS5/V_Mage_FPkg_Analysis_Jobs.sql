/****** Object:  View [dbo].[V_Mage_FPkg_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Mage_FPkg_Analysis_Jobs] as
/*
 * This view was used by the File Packager tool written by Gary Kiebel in 2012
 * As of September 2013 this tool is not in use and thus this view could likely be deleted in the future
 */
SELECT MAJ.Job,
       MAJ.Folder,
       SPath.SP_vol_name_client + SPath.SP_path AS Storage_Path,
       AP.AP_network_share_path + '\' AS Archive_Path,
       AJ.AJ_Purged AS Purged,
       MAJ.[State],
       MAJ.Dataset,
       MAJ.Dataset_ID,
       MAJ.Tool,
       MAJ.Parameter_File,
       MAJ.Settings_File,
       MAJ.Instrument,
       MAJ.Experiment,
       MAJ.Campaign,
       MAJ.Organism,
       MAJ.[Organism DB],
       MAJ.[Protein Collection List],
       MAJ.[Protein Options],
       MAJ.[Comment],
       MAJ.Job_Finish
FROM V_Mage_Analysis_Jobs MAJ
     INNER JOIN T_Analysis_Job AS AJ
       ON MAJ.Job = AJ.AJ_jobID
     INNER JOIN T_Dataset AS DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN T_Storage_Path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     LEFT OUTER JOIN T_Dataset_Archive DA
                     INNER JOIN T_Archive_Path AP
                       ON DA.AS_storage_path_ID = AP.AP_path_ID
       ON DS.Dataset_ID = DA.AS_Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Analysis_Jobs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Analysis_Jobs] TO [PNL\D3M580] AS [dbo]
GO
