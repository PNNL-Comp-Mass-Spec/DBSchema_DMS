/****** Object:  Table [dbo].[term] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[term](
	[term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ontology_id] [int] NOT NULL,
	[term_name] [varchar](1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[identifier] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[definition] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[namespace] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[is_obsolete] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[is_root_term] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[is_leaf] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_term] PRIMARY KEY CLUSTERED 
(
	[term_pk] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

/****** Object:  Index [IX_term_identifier] ******/
CREATE NONCLUSTERED INDEX [IX_term_identifier] ON [dbo].[term] 
(
	[identifier] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_term_is_leaf] ******/
CREATE NONCLUSTERED INDEX [IX_term_is_leaf] ON [dbo].[term] 
(
	[is_leaf] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_term_namespace] ******/
CREATE NONCLUSTERED INDEX [IX_term_namespace] ON [dbo].[term] 
(
	[namespace] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_term_ontology_id] ******/
CREATE NONCLUSTERED INDEX [IX_term_ontology_id] ON [dbo].[term] 
(
	[ontology_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
