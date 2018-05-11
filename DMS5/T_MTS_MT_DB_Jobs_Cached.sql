/****** Object:  Table [dbo].[T_MTS_MT_DB_Jobs_Cached] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MTS_MT_DB_Jobs_Cached](
	[CachedInfo_ID] [int] IDENTITY(1,1) NOT NULL,
	[Server_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MT_DB_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Job] [int] NOT NULL,
	[ResultType] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
	[Process_State] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SortKey] [int] NULL,
 CONSTRAINT [PK_T_MTS_MT_DB_Jobs_Cached] PRIMARY KEY NONCLUSTERED 
(
	[CachedInfo_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_MTS_MT_DB_Jobs_Cached] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_MTS_MT_DB_Jobs_Cached_SortKey] ******/
CREATE CLUSTERED INDEX [IX_T_MTS_MT_DB_Jobs_Cached_SortKey] ON [dbo].[T_MTS_MT_DB_Jobs_Cached]
(
	[SortKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_MTS_MT_DB_Jobs_Cached_DBName_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_MTS_MT_DB_Jobs_Cached_DBName_Job] ON [dbo].[T_MTS_MT_DB_Jobs_Cached]
(
	[MT_DB_Name] ASC,
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_MTS_MT_DB_Jobs_Cached_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_MTS_MT_DB_Jobs_Cached_Job] ON [dbo].[T_MTS_MT_DB_Jobs_Cached]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_MTS_MT_DB_Jobs_Cached_Server_DB_include_ResultType] ******/
CREATE NONCLUSTERED INDEX [IX_T_MTS_MT_DB_Jobs_Cached_Server_DB_include_ResultType] ON [dbo].[T_MTS_MT_DB_Jobs_Cached]
(
	[Server_Name] ASC,
	[MT_DB_Name] ASC
)
INCLUDE ( 	[ResultType]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_iu_MTS_MT_DB_Jobs_Cached] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_iu_MTS_MT_DB_Jobs_Cached] on [dbo].[T_MTS_MT_DB_Jobs_Cached]
For Insert, Update
/****************************************************
**
**	Desc: 
**		Updates the SortKey column
**
**	Auth:	mem
**	Date:	11/21/2012 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update (Job)
		UPDATE T_MTS_MT_DB_Jobs_Cached
		SET SortKey = CASE WHEN AJ_JobID IS NULL 
		                   THEN -MTDBJobs.Job
		                   ELSE MTDBJobs.Job
		              END
		FROM T_MTS_MT_DB_Jobs_Cached MTDBJobs
		     INNER JOIN inserted
		       ON MTDBJobs.job = inserted.job
		     LEFT OUTER JOIN T_Analysis_Job AJ
		       ON AJ.AJ_jobID = inserted.Job


GO
ALTER TABLE [dbo].[T_MTS_MT_DB_Jobs_Cached] ENABLE TRIGGER [trig_iu_MTS_MT_DB_Jobs_Cached]
GO
