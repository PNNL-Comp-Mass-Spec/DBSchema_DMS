/****** Object:  Table [dbo].[term_path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[term_path](
	[term_path_id] [int] NOT NULL,
	[subject_term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[predicate_term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[object_term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ontology_id] [int] NOT NULL,
	[relationship_type_id] [int] NOT NULL,
	[distance] [int] NULL,
 CONSTRAINT [PK_term_path] PRIMARY KEY CLUSTERED 
(
	[term_path_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_term_path_object_term_pk] ******/
CREATE NONCLUSTERED INDEX [IX_term_path_object_term_pk] ON [dbo].[term_path] 
(
	[object_term_pk] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_term_path_ontology_id] ******/
CREATE NONCLUSTERED INDEX [IX_term_path_ontology_id] ON [dbo].[term_path] 
(
	[ontology_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_term_path_predicate_term_pk] ******/
CREATE NONCLUSTERED INDEX [IX_term_path_predicate_term_pk] ON [dbo].[term_path] 
(
	[predicate_term_pk] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_term_path_relationship_type_id] ******/
CREATE NONCLUSTERED INDEX [IX_term_path_relationship_type_id] ON [dbo].[term_path] 
(
	[relationship_type_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_term_path_subject_term_pk] ******/
CREATE NONCLUSTERED INDEX [IX_term_path_subject_term_pk] ON [dbo].[term_path] 
(
	[subject_term_pk] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[term_path] ADD  CONSTRAINT [DF_term_path_ontology_id]  DEFAULT ((0)) FOR [ontology_id]
GO
ALTER TABLE [dbo].[term_path] ADD  CONSTRAINT [DF_term_path_relationship_type_id]  DEFAULT ((0)) FOR [relationship_type_id]
GO
