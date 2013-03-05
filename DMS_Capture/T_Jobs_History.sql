/****** Object:  Table [dbo].[T_Jobs_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Jobs_History](
	[Job] [int] NOT NULL,
	[Priority] [int] NULL,
	[Script] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[State] [int] NOT NULL,
	[Dataset] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_ID] [int] NULL,
	[Results_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Organism_DB_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Imported] [datetime] NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Saved] [datetime] NULL
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Jobs_History_Job] ******/
CREATE CLUSTERED INDEX [IX_T_Jobs_History_Job] ON [dbo].[T_Jobs_History] 
(
	[Job] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Jobs_History_Script_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_History_Script_Job] ON [dbo].[T_Jobs_History] 
(
	[Script] ASC
)
INCLUDE ( [Job]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Jobs_History_State_include_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_History_State_include_Job] ON [dbo].[T_Jobs_History] 
(
	[State] ASC
)
INCLUDE ( [Job]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
