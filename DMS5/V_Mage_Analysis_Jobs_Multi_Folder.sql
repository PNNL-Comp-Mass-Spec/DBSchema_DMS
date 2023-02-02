/****** Object:  View [dbo].[V_Mage_Analysis_Jobs_Multi_Folder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mage_Analysis_Jobs_Multi_Folder] as
SELECT J.job,
       J.state,
       J.dataset,
       J.dataset_id,
       J.tool,
       J.parameter_file,
       J.settings_file,
       J.instrument,
       J.experiment,
       J.campaign,
       J.organism,
       J.organism_db,
       J.protein_collection_list,
       J.protein_options,
       J.comment,
       J.results_folder,
       ISNULL(DFP.Dataset_Folder_Path + '\' + J.results_folder, '') + '|' +
       ISNULL(DFP.Archive_Folder_Path + '\' + J.results_folder, '') + '|' +
       ISNULL(DFP.MyEMSL_Path_Flag + '\' + J.results_folder, '') AS folder,
       J.dataset_created,
       J.job_finish,
       J.dataset_rating
FROM V_Mage_Analysis_Jobs J
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON J.Dataset_ID = DFP.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Analysis_Jobs_Multi_Folder] TO [DDL_Viewer] AS [dbo]
GO
