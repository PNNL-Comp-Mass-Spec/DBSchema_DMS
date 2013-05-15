/****** Object:  Table [dbo].[T_Step_Tool_Versions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Step_Tool_Versions](
	[Tool_Version_ID] [int] IDENTITY(1,1) NOT NULL,
	[Tool_Version] [varchar](900) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Most_Recent_Job] [int] NULL,
	[Last_Used] [datetime] NULL,
	[Entered] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Step_Tool_Versions] PRIMARY KEY CLUSTERED 
(
	[Tool_Version_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Step_Tool_Versions] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Step_Tool_Versions] ON [dbo].[T_Step_Tool_Versions] 
(
	[Tool_Version] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Step_Tool_Versions] ADD  CONSTRAINT [DF_T_Step_Tool_Versions_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
