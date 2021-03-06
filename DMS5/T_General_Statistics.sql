/****** Object:  Table [dbo].[T_General_Statistics] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_General_Statistics](
	[Entry_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Category] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Label] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Value] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Last_Affected] [datetime] NULL,
 CONSTRAINT [PK_T_General_Statistics] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_General_Statistics] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_General_Statistics_Category_Label] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_General_Statistics_Category_Label] ON [dbo].[T_General_Statistics]
(
	[Category] ASC,
	[Label] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_General_Statistics] ADD  CONSTRAINT [DF_T_General_Statistics_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
