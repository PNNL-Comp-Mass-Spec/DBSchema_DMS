/****** Object:  View [dbo].[V_DMS_Data_Package_Aggregation_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Data_Package_Aggregation_Jobs]
AS
SELECT TPJ.Data_Package_ID,
       JobInfo.Job,
       JobInfo.Tool,
       JobInfo.Dataset,
       JobInfo.ArchiveStoragePath,
       JobInfo.ServerStoragePath,
       JobInfo.DatasetFolder,
       JobInfo.ResultsFolder,
       JobInfo.DatasetID,
       JobInfo.Organism,
       JobInfo.InstrumentName,
       JobInfo.InstrumentGroup,
       JobInfo.InstrumentClass,
       JobInfo.Completed,
       JobInfo.ParameterFileName,
       JobInfo.SettingsFileName,
       JobInfo.OrganismDBName,
       JobInfo.ProteinCollectionList,
       JobInfo.ProteinOptions,
       JobInfo.ResultType,
       JobInfo.DS_created,
       TPJ.[Package Comment] AS PackageComment,
       JobInfo.RawDataType,
       JobInfo.Experiment,
       JobInfo.Experiment_Reason,
       JobInfo.Experiment_Comment,
       JobInfo.Experiment_NEWT_ID,
       JobInfo.Experiment_NEWT_Name
FROM S_V_Analysis_Job_Export_DataPkg JobInfo
     INNER JOIN dbo.T_Data_Package_Analysis_Jobs AS TPJ
       ON TPJ.Job = JobInfo.Job


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Data_Package_Aggregation_Jobs] TO [DDL_Viewer] AS [dbo]
GO
