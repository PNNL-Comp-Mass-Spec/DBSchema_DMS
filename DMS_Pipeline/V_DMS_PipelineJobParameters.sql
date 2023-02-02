/****** Object:  View [dbo].[V_DMS_PipelineJobParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_DMS_PipelineJobParameters]
AS
SELECT job,
       dataset,
       dataset_folder_name,
       archive_folder_path,
       param_file_name,
       settings_file_name,
       param_file_storage_path,
       organism_db_name,
       protein_collection_list,
       protein_options_list,
       instrument_class,
       instrument_group,
       instrument,
       raw_data_type,
       search_engine_input_file_formats,
       organism,
       org_db_required,
       tool_name,
       result_type,
       dataset_id,
       dataset_storage_path,
       transfer_folder_path,
       results_folder_name,
       special_processing,
       dataset_type,
       experiment,
       instrument_data_purged
FROM S_DMS_V_Get_Pipeline_Job_Parameters


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_PipelineJobParameters] TO [DDL_Viewer] AS [dbo]
GO
