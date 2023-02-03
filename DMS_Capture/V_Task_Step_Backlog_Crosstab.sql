/****** Object:  View [dbo].[V_Task_Step_Backlog_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Task_Step_Backlog_Crosstab]
AS
SELECT PivotData.posting_time,
	IsNull([ArchiveStatusCheck], 0) AS archive_status_check,
	IsNull([ArchiveVerify], 0) AS archive_verify,
	IsNull([ArchiveUpdate], 0) AS archive_update,
	IsNull([DatasetArchive], 0) AS dataset_archive,
	IsNull([DatasetCapture], 0) AS dataset_capture,
	IsNull([DatasetIntegrity], 0) AS dataset_integrity,
	IsNull([DatasetInfo], 0) AS dataset_info,
	IsNull([DatasetQuality], 0) AS dataset_quality,
	IsNull([SourceFileRename], 0) AS source_file_rename,
	IsNull([ImsDeMultiplex], 0) AS ims_demultiplex
FROM ( SELECT Convert(smalldatetime, posting_time) AS Posting_Time,
              step_tool,
              backlog_count
       FROM V_Task_Step_Backlog_History 
     ) AS SourceTable
     PIVOT ( SUM(backlog_count)
             FOR step_tool
             IN ( [ArchiveStatusCheck], [ArchiveVerify], [ArchiveUpdate],
				  [DatasetArchive], [DatasetCapture], [DatasetIntegrity],
				  [DatasetInfo], [DatasetQuality], [SourceFileRename],
				  [ImsDeMultiplex] 
             ) ) AS PivotData


GO
GRANT VIEW DEFINITION ON [dbo].[V_Task_Step_Backlog_Crosstab] TO [DDL_Viewer] AS [dbo]
GO
