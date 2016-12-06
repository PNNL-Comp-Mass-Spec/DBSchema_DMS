/****** Object:  View [dbo].[V_DMS_PipelineJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_PipelineJobs]
AS
SELECT Job,
       Priority,
       Tool,
       Dataset,
       Dataset_ID,
       Settings_File_Name,
       Parameter_File_Name,
       State,
       Transfer_Folder_Path,
       Comment,
       Special_Processing,
       Owner       
FROM S_DMS_V_GetPipelineJobs


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_PipelineJobs] TO [DDL_Viewer] AS [dbo]
GO
