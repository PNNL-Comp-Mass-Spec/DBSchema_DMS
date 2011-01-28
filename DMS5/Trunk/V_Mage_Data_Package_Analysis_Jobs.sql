/****** Object:  View [dbo].[V_Mage_Data_Package_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view V_Mage_Data_Package_Analysis_Jobs as   
SELECT        VMA.Job, VMA.State, VMA.Dataset, VMA.Dataset_ID, VMA.Tool, VMA.Parameter_File, VMA.Settings_File, VMA.Instrument, VMA.Experiment, VMA.Campaign, 
                         VMA.Organism, VMA.[Organism DB], VMA.[Protein Collection List], VMA.[Protein Options], VMA.Comment, VMA.[Results Folder], VMA.Folder, TPA.Data_Package_ID, 
                         TPA.[Package Comment]
FROM            V_Mage_Analysis_Jobs AS VMA INNER JOIN
                         DMS_Data_Package.dbo.T_Data_Package_Analysis_Jobs AS TPA ON VMA.Job = TPA.Job
GO
