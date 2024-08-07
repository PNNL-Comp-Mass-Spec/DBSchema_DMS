/****** Object:  Table [dbo].[T_CV_BTO] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_CV_BTO](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Term_PK] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Term_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Identifier] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Is_Leaf] [tinyint] NOT NULL,
	[Synonyms] [varchar](900) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Parent_term_name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Parent_term_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Grandparent_term_name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Grandparent_term_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Children] [int] NULL,
	[Usage_Last_12_Months] [int] NOT NULL,
	[Usage_All_Time] [int] NOT NULL,
	[Entered] [smalldatetime] NOT NULL,
	[Updated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_T_CV_BTO] PRIMARY KEY NONCLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_CV_BTO] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_BTO_Term_Name] ******/
CREATE CLUSTERED INDEX [IX_T_CV_BTO_Term_Name] ON [dbo].[T_CV_BTO]
(
	[Term_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_BTO_Grandparent_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_BTO_Grandparent_Term_Name] ON [dbo].[T_CV_BTO]
(
	[Grandparent_term_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_BTO_Identifier] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_BTO_Identifier] ON [dbo].[T_CV_BTO]
(
	[Identifier] ASC
)
INCLUDE([Term_Name]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_BTO_Parent_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_BTO_Parent_Term_Name] ON [dbo].[T_CV_BTO]
(
	[Parent_term_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_BTO_Synonyms] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_BTO_Synonyms] ON [dbo].[T_CV_BTO]
(
	[Synonyms] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_BTO_Term_Name_include_Identifier] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_BTO_Term_Name_include_Identifier] ON [dbo].[T_CV_BTO]
(
	[Term_Name] ASC
)
INCLUDE([Identifier]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_CV_BTO] ADD  CONSTRAINT [DF_T_CV_BTO_Usage_Last_12_Months]  DEFAULT ((0)) FOR [Usage_Last_12_Months]
GO
ALTER TABLE [dbo].[T_CV_BTO] ADD  CONSTRAINT [DF_T_CV_BTO_Usage_All_Time]  DEFAULT ((0)) FOR [Usage_All_Time]
GO
ALTER TABLE [dbo].[T_CV_BTO] ADD  CONSTRAINT [DF_T_CV_BTO_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_CV_BTO] ADD  CONSTRAINT [DF_T_CV_BTO_Updated]  DEFAULT (getdate()) FOR [Updated]
GO
