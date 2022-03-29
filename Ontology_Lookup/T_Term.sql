/****** Object:  Table [dbo].[T_Term] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Term](
	[term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ontology_id] [int] NOT NULL,
	[term_name] [varchar](1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[identifier] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[definition] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[namespace] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[is_obsolete] [smallint] NULL,
	[is_root_term] [smallint] NULL,
	[is_leaf] [smallint] NULL,
	[Updated] [smalldatetime] NULL,
 CONSTRAINT [PK_term] PRIMARY KEY CLUSTERED 
(
	[term_pk] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Term] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Term_identifier] ******/
CREATE NONCLUSTERED INDEX [IX_T_Term_identifier] ON [dbo].[T_Term]
(
	[identifier] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Term_is_leaf] ******/
CREATE NONCLUSTERED INDEX [IX_T_Term_is_leaf] ON [dbo].[T_Term]
(
	[is_leaf] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Term_namespace] ******/
CREATE NONCLUSTERED INDEX [IX_T_Term_namespace] ON [dbo].[T_Term]
(
	[namespace] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_term_ontology_id] ******/
CREATE NONCLUSTERED INDEX [IX_term_ontology_id] ON [dbo].[T_Term]
(
	[ontology_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
