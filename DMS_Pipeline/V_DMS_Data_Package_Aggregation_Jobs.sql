/****** Object:  View [dbo].[V_DMS_Data_Package_Aggregation_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_DMS_Data_Package_Aggregation_Jobs]
AS
-- This view is used by function LoadDataPackageJobInfo in the DMS Analysis Manager
SELECT Src.Data_Package_ID,
       Src.Job,
       Src.Tool,
       Src.Dataset,
       Src.Archive_Storage_Path,
       Src.Server_Storage_Path,
       Src.Dataset_Folder,
       Src.Results_Folder,
       IsNull(JSH.Step, 1) AS Step,
       IsNull(JSH.Output_Folder_Name, '') AS Shared_Results_Folder,
       Src.Dataset_ID,
       Src.Organism,
       Src.Instrument_Name,
       Src.Instrument_Group,
       Src.Instrument_Class,
       Src.Completed,
       Src.Parameter_File_Name,
       Src.Settings_File_Name,
       Src.Organism_DB_Name,
       Src.Protein_Collection_List,
       Src.Protein_Options,
       Src.Result_Type,
       Src.Dataset_Created,
       IsNull(Src.Package_Comment, '') AS Package_Comment,
       Src.Raw_Data_Type,
       Src.Experiment,
       Src.Experiment_Reason,
       Src.Experiment_Comment,
       Src.Experiment_NEWT_ID,
       Src.Experiment_NEWT_Name
FROM dbo.S_Data_Package_Aggregation_Jobs Src
     LEFT OUTER JOIN dbo.T_Job_Steps_History JSH
       ON Src.Job = JSH.Job AND
          JSH.Most_Recent_Entry = 1 AND
          JSH.Shared_Result_Version > 0 AND
          JSH.State IN (3, 5)

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Data_Package_Aggregation_Jobs] TO [DDL_Viewer] AS [dbo]
GO
