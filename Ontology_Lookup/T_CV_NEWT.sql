/****** Object:  Table [dbo].[T_CV_NEWT] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_CV_NEWT](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Term_PK] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Term_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Identifier] [int] NOT NULL,
	[Is_Leaf] [tinyint] NOT NULL,
	[Rank] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Parent_Term_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Parent_Term_ID] [int] NOT NULL,
	[Grandparent_Term_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Grandparent_Term_ID] [int] NULL,
	[Common_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Synonym] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mnemonic] [varchar](16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Children] [int] NOT NULL,
	[Entered] [smalldatetime] NOT NULL,
	[Updated] [smalldatetime] NULL,
	[Identifier_Text]  AS (CONVERT([varchar](12),[Identifier])) PERSISTED,
	[Parent_Term_ID_Text]  AS (CONVERT([varchar](12),[Parent_Term_ID])) PERSISTED,
	[Grandparent_Term_ID_Text]  AS (CONVERT([varchar](12),[Grandparent_Term_ID])) PERSISTED,
 CONSTRAINT [PK_T_CV_NEWT] PRIMARY KEY NONCLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_CV_NEWT] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_NEWT_Term_Name] ******/
CREATE CLUSTERED INDEX [IX_T_CV_NEWT_Term_Name] ON [dbo].[T_CV_NEWT]
(
	[Term_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_NEWT_Common_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_NEWT_Common_Name] ON [dbo].[T_CV_NEWT]
(
	[Common_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_CV_Newt_Grandparent_Term_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Newt_Grandparent_Term_ID] ON [dbo].[T_CV_NEWT]
(
	[Grandparent_Term_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IX_T_CV_Newt_Grandparent_Term_ID_Text_Computed_Column] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Newt_Grandparent_Term_ID_Text_Computed_Column] ON [dbo].[T_CV_NEWT]
(
	[Grandparent_Term_ID_Text] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_NEWT_Grandparent_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_NEWT_Grandparent_Term_Name] ON [dbo].[T_CV_NEWT]
(
	[Grandparent_Term_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_CV_NEWT_Identifier] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_NEWT_Identifier] ON [dbo].[T_CV_NEWT]
(
	[Identifier] ASC
)
INCLUDE([Term_Name]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IX_T_CV_Newt_Identifier_Text_Computed_Column] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Newt_Identifier_Text_Computed_Column] ON [dbo].[T_CV_NEWT]
(
	[Identifier_Text] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_CV_Newt_Parent_Term_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Newt_Parent_Term_ID] ON [dbo].[T_CV_NEWT]
(
	[Parent_Term_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IX_T_CV_Newt_Parent_Term_ID_Text_Computed_Column] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_Newt_Parent_Term_ID_Text_Computed_Column] ON [dbo].[T_CV_NEWT]
(
	[Parent_Term_ID_Text] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_NEWT_Parent_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_NEWT_Parent_Term_Name] ON [dbo].[T_CV_NEWT]
(
	[Parent_Term_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_NEWT_Synonym] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_NEWT_Synonym] ON [dbo].[T_CV_NEWT]
(
	[Synonym] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_NEWT_Term_PK] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_NEWT_Term_PK] ON [dbo].[T_CV_NEWT]
(
	[Term_PK] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_CV_NEWT] ADD  CONSTRAINT [DF_T_CV_NEWT_Rank]  DEFAULT ('') FOR [Rank]
GO
ALTER TABLE [dbo].[T_CV_NEWT] ADD  CONSTRAINT [DF_T_CV_NEWT_Children]  DEFAULT ((0)) FOR [Children]
GO
ALTER TABLE [dbo].[T_CV_NEWT] ADD  CONSTRAINT [DF_T_CV_NEWT_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
