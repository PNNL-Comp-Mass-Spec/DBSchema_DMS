/****** Object:  Table [dbo].[T_Log_Entries_Data_Package] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Log_Entries_Data_Package](
	[Entry_ID] [int] NOT NULL,
	[posted_by] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NULL,
	[type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[message] [varchar](4096) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Log_Entries_Data_Package] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Log_Entries_Data_Package] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Log_Entries_Data_Package_Entered] ******/
CREATE NONCLUSTERED INDEX [IX_T_Log_Entries_Data_Package_Entered] ON [dbo].[T_Log_Entries_Data_Package]
(
	[Entered] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Log_Entries_Data_Package_Posted_By] ******/
CREATE NONCLUSTERED INDEX [IX_T_Log_Entries_Data_Package_Posted_By] ON [dbo].[T_Log_Entries_Data_Package]
(
	[posted_by] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Log_Entries_Data_Package] ADD  CONSTRAINT [DF_T_Log_Entries_Data_Package_posting_time]  DEFAULT (getdate()) FOR [Entered]
GO
