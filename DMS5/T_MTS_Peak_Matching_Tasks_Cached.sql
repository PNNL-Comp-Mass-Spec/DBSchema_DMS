/****** Object:  Table [dbo].[T_MTS_Peak_Matching_Tasks_Cached] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MTS_Peak_Matching_Tasks_Cached](
	[CachedInfo_ID] [int] IDENTITY(1,1) NOT NULL,
	[Tool_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MTS_Job_ID] [int] NOT NULL,
	[Job_Start] [datetime] NULL,
	[Job_Finish] [datetime] NULL,
	[Comment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[State_ID] [int] NOT NULL,
	[Task_Server] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Task_Database] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Task_ID] [int] NOT NULL,
	[Assigned_Processor_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Tool_Version] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DMS_Job_Count] [int] NULL,
	[DMS_Job] [int] NOT NULL,
	[Output_Folder_Path] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Results_URL] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AMT_Count_1pct_FDR] [int] NULL,
	[AMT_Count_5pct_FDR] [int] NULL,
	[AMT_Count_10pct_FDR] [int] NULL,
	[AMT_Count_25pct_FDR] [int] NULL,
	[AMT_Count_50pct_FDR] [int] NULL,
	[Refine_Mass_Cal_PPMShift] [numeric](9, 4) NULL,
	[MD_ID] [int] NULL,
	[QID] [int] NULL,
	[Ini_File_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comparison_Mass_Tag_Count] [int] NULL,
	[MD_State] [tinyint] NULL,
 CONSTRAINT [PK_T_MTS_Peak_Matching_Tasks_Cached] PRIMARY KEY NONCLUSTERED 
(
	[CachedInfo_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_MTS_Peak_Matching_Tasks_Cached_MTSJob_DMSJob] ******/
CREATE CLUSTERED INDEX [IX_T_MTS_Peak_Matching_Tasks_Cached_MTSJob_DMSJob] ON [dbo].[T_MTS_Peak_Matching_Tasks_Cached] 
(
	[MTS_Job_ID] ASC,
	[DMS_Job] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_MTS_Peak_Matching_Tasks_Cached_DMSJob] ******/
CREATE NONCLUSTERED INDEX [IX_T_MTS_Peak_Matching_Tasks_Cached_DMSJob] ON [dbo].[T_MTS_Peak_Matching_Tasks_Cached] 
(
	[DMS_Job] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_MTS_Peak_Matching_Tasks_Cached_JobStart] ******/
CREATE NONCLUSTERED INDEX [IX_T_MTS_Peak_Matching_Tasks_Cached_JobStart] ON [dbo].[T_MTS_Peak_Matching_Tasks_Cached] 
(
	[Job_Start] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_MTS_Peak_Matching_Tasks_Cached_TaskDB] ******/
CREATE NONCLUSTERED INDEX [IX_T_MTS_Peak_Matching_Tasks_Cached_TaskDB] ON [dbo].[T_MTS_Peak_Matching_Tasks_Cached] 
(
	[Task_Database] ASC
)
INCLUDE ( [DMS_Job]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_MTS_Peak_Matching_Tasks_Cached_Tool_DMSJob] ******/
CREATE NONCLUSTERED INDEX [IX_T_MTS_Peak_Matching_Tasks_Cached_Tool_DMSJob] ON [dbo].[T_MTS_Peak_Matching_Tasks_Cached] 
(
	[Tool_Name] ASC,
	[DMS_Job] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
