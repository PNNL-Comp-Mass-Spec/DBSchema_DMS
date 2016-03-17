/****** Object:  View [dbo].[V_Dataset_PSM_And_PM_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Dataset_PSM_And_PM_List_Report as
SELECT 
       PSM.Dataset,
       PSM.[Unique Peptides FDR] AS [Unique Peptides],
       CAST(QCM.XIC_FWHM_Q3 AS decimal(9,2)) AS XIC_FWHM_Q3,
       QCM.MassErrorPPM AS Mass_Error_PPM,
       ISNULL(QCM.MassErrorPPM_VIPER, -PM.PPM_Shift) AS Mass_Error_AMTs,
       ISNULL(QCM.AMTs_10pct_FDR, PM.[AMTs 10pct FDR]) AS AMTs_10pct_FDR,
       DFP.Dataset_URL + 'QC/index.html' AS QC_Link,
       PM.Results_URL AS PM_Results_URL,
	   CAST(QCM.P_4A * 100 AS decimal(9,1)) AS PctTryptic,
	   CAST(QCM.P_4B * 100 AS decimal(9,1)) AS PctMissedClvg,
	   QCM.P_2A AS TrypticPSMs,
	   QCM.Keratin_2A AS KeratinPSMs,
	   QCM.Phos_2C PhosphoPep,
	   QCM.Trypsin_2A AS TrypsinPSMs,
       PSM.Instrument,
       PSM.Dataset_ID,
       DTN.DST_name AS [Dataset Type],
       DS.DS_sec_sep AS [Separation Type],       
       PSM.Rating AS DS_Rating,       
       PSM.[Acq Length] AS DS_Acq_Length,
       PSM.Acq_Time_Start AS [Acq Start],
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
FROM V_Analysis_Job_PSM_List_Report PSM  
     INNER JOIN V_Dataset_Folder_Paths DFP 
       ON PSM.Dataset_ID = DFP.Dataset_ID
     INNER JOIN T_Dataset DS
       ON PSM.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_DatasetTypeName DTN 
       ON DS.DS_type_ID = DTN.DST_Type_ID
     LEFT OUTER JOIN V_Dataset_QC_Metrics QCM
       ON PSM.Dataset_ID = QCM.Dataset_ID
     LEFT OUTER JOIN V_MTS_PM_Results_List_Report PM
       ON PSM.Dataset_ID = PM.Dataset_ID
WHERE PSM.StateID NOT IN (5, 14)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_PSM_And_PM_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_PSM_And_PM_List_Report] TO [PNL\D3M580] AS [dbo]
GO
