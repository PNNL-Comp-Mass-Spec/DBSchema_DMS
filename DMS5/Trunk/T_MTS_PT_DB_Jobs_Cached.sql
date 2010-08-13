/****** Object:  Table [dbo].[T_MTS_PT_DB_Jobs_Cached] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MTS_PT_DB_Jobs_Cached](
	[CachedInfo_ID] [int] IDENTITY(1,1) NOT NULL,
	[Server_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Peptide_DB_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Job] [int] NOT NULL,
	[ResultType] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
	[Process_State] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_MTS_PT_DB_Jobs_Cached] PRIMARY KEY NONCLUSTERED 
(
	[CachedInfo_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_MTS_PT_DB_Jobs_Cached_DBName_Job] ******/
CREATE CLUSTERED INDEX [IX_T_MTS_PT_DB_Jobs_Cached_DBName_Job] ON [dbo].[T_MTS_PT_DB_Jobs_Cached] 
(
	[Peptide_DB_Name] ASC,
	[Job] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_MTS_PT_DB_Jobs_Cached_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_MTS_PT_DB_Jobs_Cached_Job] ON [dbo].[T_MTS_PT_DB_Jobs_Cached] 
(
	[Job] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
