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
       Src.ArchiveStoragePath,
       Src.ServerStoragePath,
       Src.DatasetFolder,
       Src.ResultsFolder,
       IsNull(JSH.Step_Number, 1) AS Step,
       IsNull(JSH.Output_Folder_Name, '') AS SharedResultsFolder,
       Src.DatasetID,
       Src.Organism,
       Src.InstrumentName AS Instrument,
       Src.InstrumentGroup,
       Src.InstrumentClass,
       Src.Completed,
       Src.ParameterFileName,
       Src.SettingsFileName,
       Src.OrganismDBName,
       Src.ProteinCollectionList,
       Src.ProteinOptions,
       Src.ResultType,
       Src.DS_created,
       IsNull(Src.PackageComment, '') AS PackageComment,
       Src.RawDataType,
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
