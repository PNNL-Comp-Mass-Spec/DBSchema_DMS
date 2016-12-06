/****** Object:  View [dbo].[V_DMS_PipelineJobParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_DMS_PipelineJobParameters]
AS
SELECT Job
      ,Dataset
      ,Dataset_Folder_Name
      ,Archive_Folder_Path
      ,ParamFileName
      ,SettingsFileName
      ,ParamFileStoragePath
      ,OrganismDBName
      ,ProteinCollectionList
      ,ProteinOptionsList
      ,InstrumentClass
      ,InstrumentGroup
      ,Instrument
      ,RawDataType
      ,SearchEngineInputFileFormats
      ,Organism
      ,OrgDBRequired
      ,ToolName
      ,ResultType
      ,Dataset_ID
      ,Dataset_Storage_Path
      ,Transfer_Folder_Path
      ,Special_Processing
      ,DatasetType
      ,Experiment
	  ,InstrumentDataPurged
  FROM S_DMS_V_GetPipelineJobParameters




GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_PipelineJobParameters] TO [DDL_Viewer] AS [dbo]
GO
