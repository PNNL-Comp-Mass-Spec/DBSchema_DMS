/****** Object:  Table [dbo].[T_Remote_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Remote_Info](
	[Remote_Info_ID] [int] IDENTITY(1,1) NOT NULL,
	[Remote_Info] [varchar](900) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Most_Recent_Job] [int] NULL,
	[Last_Used] [datetime] NULL,
	[Entered] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Remote_Info] PRIMARY KEY CLUSTERED 
(
	[Remote_Info_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Remote_Info] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Remote_Info] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Remote_Info] ON [dbo].[T_Remote_Info]
(
	[Remote_Info] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Remote_Info] ADD  CONSTRAINT [DF_T_Remote_Info_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
