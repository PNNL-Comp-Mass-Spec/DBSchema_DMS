/****** Object:  View [dbo].[V_Dataset_PM_and_PSM_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_Dataset_PM_and_PSM_List_Report] as
SELECT 
       PM.Dataset,
       PSM.[Unique Peptides FDR] AS [Unique Peptides],
       CONVERT(decimal(9,2), QCM.XIC_FWHM_Q3) AS XIC_FWHM_Q3,
       QCM.MassErrorPPM AS Mass_Error_PPM,
       ISNULL(QCM.MassErrorPPM_VIPER, -PM.PPM_Shift) AS Mass_Error_AMTs,
       ISNULL(QCM.AMTs_10pct_FDR, PM.[AMTs 10pct FDR]) AS AMTs_10pct_FDR,
       DFP.Dataset_URL + 'QC/index.html' AS QC_Link,
       PM.Results_URL AS PM_Results_URL,
	   QCM.Phos_2C PhosphoPep,
       PM.Instrument,
       PM.Dataset_ID,
       DTN.DST_name AS [Dataset Type],
       DS.DS_sec_sep AS [Separation Type], 
       DR.DRN_name AS DS_Rating,
       PM.[Acq Length] AS DS_Acq_Length,
       PM.Acq_Time_Start AS [Acq Start],      
       PSM.Job AS PSM_Job,
       PSM.Tool AS PSM_Tool,
       PSM.Campaign,
       PSM.Experiment,
       PSM.[Parm File] AS PSM_Job_Param_File,
       PSM.Settings_File AS PSM_Job_Settings_File,
       PSM.Organism,
       PSM.[Organism DB] AS PSM_Job_Org_DB,
       PSM.[Protein Collection List] AS PSM_Job_Protein_Collection,
       PSM.[Results Folder Path],
       PM.Task_ID AS PM_Task_ID,
       PM.Task_Server AS PM_Server,
       PM.Task_Database AS PM_Database,
       PM.Ini_File_Name AS PM_Ini_File_Name
FROM V_MTS_PM_Results_List_Report PM
     INNER JOIN V_Dataset_Folder_Paths DFP 
       ON PM.Dataset_ID = DFP.Dataset_ID
     INNER JOIN T_Dataset DS
       ON PM.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_DatasetTypeName DTN 
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_DatasetRatingName DR 
       ON DS.DS_rating = DR.DRN_state_ID
     LEFT OUTER JOIN V_Dataset_QC_Metrics QCM
       ON PM.Dataset_ID = QCM.Dataset_ID
     LEFT OUTER JOIN V_Analysis_Job_PSM_List_Report PSM
       ON PSM.Dataset_ID = PM.Dataset_ID AND PSM.StateID NOT IN (5, 14)



GO
