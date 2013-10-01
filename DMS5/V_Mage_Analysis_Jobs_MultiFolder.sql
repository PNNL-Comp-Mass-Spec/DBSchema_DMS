/****** Object:  View [dbo].[V_Mage_Analysis_Jobs_MultiFolder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[V_Mage_Analysis_Jobs_MultiFolder] as 
SELECT J.Job,
       J.[State],
       J.Dataset,
       J.Dataset_ID,
       J.Tool,
       J.Parameter_File,
       J.Settings_File,
       J.Instrument,
       J.Experiment,
       J.Campaign,
       J.Organism,
       J.[Organism DB],
       J.[Protein Collection List],
       J.[Protein Options],
       J.[Comment],
       J.[Results Folder],
       ISNULL(DFP.Dataset_Folder_Path + '\' + J.[Results Folder], '') + '|' + 
       ISNULL(DFP.Archive_Folder_Path + '\' + J.[Results Folder], '') + '|' + 
       ISNULL(DFP.MyEMSL_Path_Flag + '\' + J.[Results Folder], '') AS Folder,
       J.Dataset_Created,
       J.Job_Finish,
       J.Dataset_Rating
FROM V_Mage_Analysis_Jobs J
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON J.Dataset_ID = DFP.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Analysis_Jobs_MultiFolder] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Analysis_Jobs_MultiFolder] TO [PNL\D3M580] AS [dbo]
GO
