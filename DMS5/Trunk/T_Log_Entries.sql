/****** Object:  Table [dbo].[T_Log_Entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Log_Entries](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[posted_by] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[posting_time] [datetime] NULL CONSTRAINT [DF_T_Log_Entries_posting_time]  DEFAULT (getdate()),
	[type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[message] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Log_Entries] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Log_Entries_Posted_By] ******/
CREATE NONCLUSTERED INDEX [IX_T_Log_Entries_Posted_By] ON [dbo].[T_Log_Entries] 
(
	[posted_by] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Log_Entries_Posting_Time] ******/
CREATE NONCLUSTERED INDEX [IX_T_Log_Entries_Posting_Time] ON [dbo].[T_Log_Entries] 
(
	[posting_time] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
