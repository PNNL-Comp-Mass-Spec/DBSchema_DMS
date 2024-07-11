/****** Object:  Table [dbo].[T_CV_Union_Cached] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_CV_Union_Cached](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Source] [varchar](16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Term_PK] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Term_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Identifier] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Is_Leaf] [tinyint] NOT NULL,
	[Parent_Term_Name] [varchar](400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Parent_Term_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Grandparent_Term_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Grandparent_Term_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_CV_Union_Cached] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_Union_Cached_Grandparent_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Union_Cached_Grandparent_Term_Name] ON [dbo].[T_CV_Union_Cached]
(
	[Grandparent_Term_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_Union_Cached_Identifier_Include_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Union_Cached_Identifier_Include_Term_Name] ON [dbo].[T_CV_Union_Cached]
(
	[Identifier] ASC
)
INCLUDE([Term_Name]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_Union_Cached_Parent_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Union_Cached_Parent_Term_Name] ON [dbo].[T_CV_Union_Cached]
(
	[Parent_Term_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_Union_Cached_Source] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Union_Cached_Source] ON [dbo].[T_CV_Union_Cached]
(
	[Source] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_Union_Cached_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Union_Cached_Term_Name] ON [dbo].[T_CV_Union_Cached]
(
	[Term_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_Union_Cached_Term_Name_Include_Identifier] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Union_Cached_Term_Name_Include_Identifier] ON [dbo].[T_CV_Union_Cached]
(
	[Term_Name] ASC
)
INCLUDE([Identifier]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_Union_Cached_Term_PK] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Union_Cached_Term_PK] ON [dbo].[T_CV_Union_Cached]
(
	[Term_PK] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
