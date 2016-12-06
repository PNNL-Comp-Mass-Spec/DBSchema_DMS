/****** Object:  View [dbo].[V_Job_Step_Backlog_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Job_Step_Backlog_Crosstab]
AS
SELECT PivotData.Posting_Time,
	IsNull([ArchiveStatusCheck], 0) AS [ArchiveStatusCheck],
	IsNull([ArchiveVerify], 0) AS [ArchiveVerify],
	IsNull([ArchiveUpdate], 0) AS [ArchiveUpdate],
	IsNull([DatasetArchive], 0) AS [DatasetArchive],
	IsNull([DatasetCapture], 0) AS [DatasetCapture],
	IsNull([DatasetIntegrity], 0) AS [DatasetIntegrity],
	IsNull([DatasetInfo], 0) AS [DatasetInfo],
	IsNull([DatasetQuality], 0) AS [DatasetQuality],
	IsNull([SourceFileRename], 0) AS [SourceFileRename],
	IsNull([ImsDeMultiplex], 0) AS [ImsDeMultiplex]
FROM ( SELECT Convert(smalldatetime, Posting_time) AS Posting_Time,
              Step_Tool,
              Backlog_Count
       FROM V_Job_Step_Backlog_History 
     ) AS SourceTable
     PIVOT ( SUM(Backlog_Count)
             FOR Step_Tool
             IN ( [ArchiveStatusCheck], [ArchiveVerify], [ArchiveUpdate],
				  [DatasetArchive], [DatasetCapture], [DatasetIntegrity],
				  [DatasetInfo], [DatasetQuality], [SourceFileRename],
				  [ImsDeMultiplex] 
             ) ) AS PivotData


GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_Backlog_Crosstab] TO [DDL_Viewer] AS [dbo]
GO
