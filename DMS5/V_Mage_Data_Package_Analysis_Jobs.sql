/****** Object:  View [dbo].[V_Mage_Data_Package_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Mage_Data_Package_Analysis_Jobs] AS
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
       VMA.[Organism DB] AS Organism_DB,
       VMA.[Protein Collection List] AS Protein_Collection_List,
       VMA.[Protein Options] AS Protein_Options,
       VMA.Comment,
       VMA.[Results Folder] AS Results_Folder,
       VMA.Folder,
       DPJ.Data_Pkg_ID,
       DPJ.Package_Comment,
       InstName.IN_class AS Instrument_Class,
       DTN.DST_name AS Dataset_Type,
       VMA.[Organism DB],                   -- Included for compatibility with older versions of Mage
       VMA.[Protein Collection List],       -- Included for compatibility with older versions of Mage
       VMA.[Protein Options],               -- Included for compatibility with older versions of Mage
       VMA.[Results Folder],                -- Included for compatibility with older versions of Mage
       DPJ.Data_Pkg_ID AS Data_Package_ID   -- Included for compatibility with older versions of Mage
FROM V_Mage_Analysis_Jobs VMA
     INNER JOIN S_V_Data_Package_Analysis_Jobs_Export DPJ
       ON VMA.Job = DPJ.Job
     INNER JOIN T_Dataset DS
       ON VMA.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Dataset_Type_Name DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Data_Package_Analysis_Jobs] TO [DDL_Viewer] AS [dbo]
GO
