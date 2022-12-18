/****** Object:  View [dbo].[V_DMS_Data_Package_Aggregation_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Data_Package_Aggregation_Jobs]
AS
-- Note that this view is used by V_DMS_Data_Package_Aggregation_Jobs in DMS_Pipeline
-- and the PRIDE converter plugin uses that view to retrieve metadata for data package jobs
SELECT TPJ.Data_Package_ID,
       JobInfo.Job,
       JobInfo.Tool,
       JobInfo.Dataset,
       JobInfo.Archive_Storage_Path,
       JobInfo.Server_Storage_Path,
       JobInfo.Dataset_Folder,
       JobInfo.Results_Folder,
       JobInfo.Dataset_ID,
       JobInfo.Organism,
       JobInfo.Instrument_Name,
       JobInfo.Instrument_Group,
       JobInfo.Instrument_Class,
       JobInfo.Completed,
       JobInfo.Parameter_File_Name,
       JobInfo.Settings_File_Name,
       JobInfo.Organism_DB_Name,
       JobInfo.Protein_Collection_List,
       JobInfo.Protein_Options,
       JobInfo.Result_Type,
       JobInfo.Dataset_Created,
       TPJ.Package_Comment,
       JobInfo.Raw_Data_Type,
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
