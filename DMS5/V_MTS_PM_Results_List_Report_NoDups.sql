/****** Object:  View [dbo].[V_MTS_PM_Results_List_Report_NoDups] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_MTS_PM_Results_List_Report_NoDups]
AS
SELECT Dataset,
       Job,
       Tool_Name,
       Task_Start,
       Results_URL,
       Task_ID,
       Task_State_ID,
       Task_Finish,
       Task_Server,
       Task_Database,
       Tool_Version,
       Output_Folder_Path
FROM ( SELECT DS.Dataset_Num AS Dataset,
              AJ.AJ_jobID AS Job,
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
              Row_Number() OVER ( PARTITION BY PM.Task_ID, AJ.AJ_jobID ORDER BY IsNull(PM.Job_Start, '') DESC ) AS FinishRank
       FROM T_Dataset DS
            INNER JOIN T_Analysis_Job AJ
              ON DS.Dataset_ID = AJ.AJ_datasetID
            INNER JOIN T_MTS_Peak_Matching_Tasks_Cached PM
              ON AJ.AJ_jobID = PM.DMS_Job
       GROUP BY DS.Dataset_Num, AJ.AJ_jobID, PM.Tool_Name, PM.Job_Start, PM.Results_URL, PM.Task_ID, PM.State_ID,
                PM.Job_Finish, PM.Task_Server, PM.Task_Database, PM.Tool_Version,
                PM.Output_Folder_Path, dms_job ) FilterQ
WHERE FinishRank = 1

GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_PM_Results_List_Report_NoDups] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_PM_Results_List_Report_NoDups] TO [PNL\D3M580] AS [dbo]
GO
