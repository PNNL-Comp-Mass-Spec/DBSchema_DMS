/****** Object:  View [dbo].[V_Mage_Data_Package_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Mage_Data_Package_Analysis_Jobs] as   
SELECT VMA.Job,
       VMA.State,
       VMA.Dataset,
       VMA.Dataset_ID,
       VMA.Tool,
       VMA.Parameter_File,
       VMA.Settings_File,
       VMA.Instrument,
       VMA.Experiment,
       VMA.Campaign,
       VMA.Organism,
       VMA.[Organism DB],
       VMA.[Protein Collection List],
       VMA.[Protein Options],
       VMA.Comment AS [Comment],
       VMA.[Results Folder],
       VMA.Folder,
       DPJ.Data_Package_ID,
       DPJ.[Package Comment],
       InstName.IN_class AS Instrument_Class,
       DTN.DST_name AS Dataset_Type
FROM V_Mage_Analysis_Jobs VMA
     INNER JOIN S_V_Data_Package_Analysis_Jobs_Export DPJ
       ON VMA.Job = DPJ.Job
     INNER JOIN T_Dataset DS
       ON VMA.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Data_Package_Analysis_Jobs] TO [PNL\D3M578] AS [dbo]
GO
