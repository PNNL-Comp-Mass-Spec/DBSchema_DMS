/****** Object:  Table [dbo].[T_Query_Row_Counts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Query_Row_Counts](
	[Query_ID] [int] IDENTITY(1,1) NOT NULL,
	[Object_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Where_Clause] [varchar](4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Row_Count] [bigint] NOT NULL,
	[Last_Used] [datetime] NOT NULL,
	[Last_Refresh] [datetime] NOT NULL,
	[Usage] [int] NOT NULL,
	[Refresh_Interval_Hours] [numeric](9, 3) NOT NULL,
	[Entered] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Query_Row_Counts] PRIMARY KEY CLUSTERED 
(
	[Query_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Query_Row_Counts_Object_Name_include_Where_Clause] ******/
CREATE NONCLUSTERED INDEX [IX_T_Query_Row_Counts_Object_Name_include_Where_Clause] ON [dbo].[T_Query_Row_Counts]
(
	[Object_Name] ASC
)
INCLUDE([Where_Clause]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Query_Row_Counts_Usage] ******/
CREATE NONCLUSTERED INDEX [IX_T_Query_Row_Counts_Usage] ON [dbo].[T_Query_Row_Counts]
(
	[Usage] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Query_Row_Counts] ADD  CONSTRAINT [DF_T_Query_Row_Counts_Where_Clause]  DEFAULT ('') FOR [Where_Clause]
GO
ALTER TABLE [dbo].[T_Query_Row_Counts] ADD  CONSTRAINT [DF_T_Query_Row_Counts_Row_Count]  DEFAULT ((0)) FOR [Row_Count]
GO
ALTER TABLE [dbo].[T_Query_Row_Counts] ADD  CONSTRAINT [DF_T_Query_Row_Counts_Last_Used]  DEFAULT (getdate()) FOR [Last_Used]
GO
ALTER TABLE [dbo].[T_Query_Row_Counts] ADD  CONSTRAINT [DF_T_Query_Row_Counts_Last_Refresh]  DEFAULT (getdate()) FOR [Last_Refresh]
GO
ALTER TABLE [dbo].[T_Query_Row_Counts] ADD  CONSTRAINT [DF_T_Query_Row_Counts_Usage]  DEFAULT ((0)) FOR [Usage]
GO
ALTER TABLE [dbo].[T_Query_Row_Counts] ADD  CONSTRAINT [DF_T_Query_Row_Counts_Refresh_Interval_Hours]  DEFAULT ((4)) FOR [Refresh_Interval_Hours]
GO
ALTER TABLE [dbo].[T_Query_Row_Counts] ADD  CONSTRAINT [DF_T_Query_Row_Counts_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
