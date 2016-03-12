/****** Object:  View [dbo].[V_MTS_PM_Results_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[V_MTS_PM_Results_List_Report]
AS
SELECT PM.DMS_Job AS Job,
       DS.Dataset_Num AS Dataset,
       PM.Tool_Name,
       PM.Job_Start AS Task_Start,
       PM.Results_URL,
       PM.Task_ID,
       PM.State_ID AS Task_State_ID,
       PM.Job_Finish AS Task_Finish,
       PM.Task_Server,
       PM.Task_Database,
       PM.Tool_Version,
       PM.Output_Folder_Path,
       PM.MTS_Job_ID,
       Inst.IN_name AS Instrument,
       PM.AMT_Count_1pct_FDR AS [AMTs 1pct FDR],
       PM.AMT_Count_5pct_FDR AS [AMTs 5pct FDR],
       PM.AMT_Count_10pct_FDR AS [AMTs 10pct FDR],
       PM.AMT_Count_25pct_FDR AS [AMTs 25pct FDR],
       PM.AMT_Count_50pct_FDR AS [AMTs 50pct FDR],
       Refine_Mass_Cal_PPMShift AS PPM_Shift,
       PM.QID,
       PM.MD_ID,
       AJ.AJ_parmFileName AS [Parm File],
       AJ.AJ_settingsFileName AS Settings_File,
       PM.Ini_File_Name, 
       PM.Comparison_Mass_Tag_Count, 
       PM.MD_State,
       DS.Dataset_ID,
       DS.Acq_Length_Minutes AS [Acq Length],
       DS.Acq_Time_Start
FROM T_Dataset DS
     INNER JOIN T_Analysis_Job AJ
       ON DS.Dataset_ID = AJ.AJ_datasetID
     INNER JOIN T_Instrument_Name Inst
       ON DS.DS_instrument_name_ID = Inst.Instrument_ID
     RIGHT OUTER JOIN T_MTS_Peak_Matching_Tasks_Cached PM
       ON AJ.AJ_jobID = PM.DMS_Job






GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_PM_Results_List_Report] TO [PNL\D3M578] AS [dbo]
GO
