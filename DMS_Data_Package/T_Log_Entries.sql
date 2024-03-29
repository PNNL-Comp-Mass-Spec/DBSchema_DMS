/****** Object:  Table [dbo].[T_Log_Entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Log_Entries](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[posted_by] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NOT NULL,
	[type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[message] [varchar](4096) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[posting_time]  AS ([Entered]),
 CONSTRAINT [PK_T_Log_Entries] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Log_Entries] TO [DDL_Viewer] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Log_Entries] ([Entered_By]) TO [DMS_SP_User] AS [dbo]
GO
/****** Object:  Index [IX_T_Log_Entries_Entered] ******/
CREATE NONCLUSTERED INDEX [IX_T_Log_Entries_Entered] ON [dbo].[T_Log_Entries]
(
	[Entered] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Log_Entries_Posted_By] ******/
CREATE NONCLUSTERED INDEX [IX_T_Log_Entries_Posted_By] ON [dbo].[T_Log_Entries]
(
	[posted_by] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Log_Entries] ADD  CONSTRAINT [DF_T_Log_Entries_posting_time]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Log_Entries] ADD  CONSTRAINT [DF_T_Log_Entries_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
