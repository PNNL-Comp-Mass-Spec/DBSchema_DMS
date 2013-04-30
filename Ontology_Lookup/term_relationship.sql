/****** Object:  Table [dbo].[term_relationship] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[term_relationship](
	[term_relationship_id] [int] NOT NULL,
	[subject_term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[predicate_term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[object_term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ontology_id] [int] NOT NULL,
 CONSTRAINT [PK_term_relationship] PRIMARY KEY CLUSTERED 
(
	[term_relationship_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_term_relationship_object_term_pk] ******/
CREATE NONCLUSTERED INDEX [IX_term_relationship_object_term_pk] ON [dbo].[term_relationship] 
(
	[object_term_pk] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_term_relationship_ontology_id] ******/
CREATE NONCLUSTERED INDEX [IX_term_relationship_ontology_id] ON [dbo].[term_relationship] 
(
	[ontology_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_term_relationship_predicate_term_pk] ******/
CREATE NONCLUSTERED INDEX [IX_term_relationship_predicate_term_pk] ON [dbo].[term_relationship] 
(
	[predicate_term_pk] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_term_relationship_subject_term_pk] ******/
CREATE NONCLUSTERED INDEX [IX_term_relationship_subject_term_pk] ON [dbo].[term_relationship] 
(
	[subject_term_pk] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[term_relationship] ADD  CONSTRAINT [DF_term_relationship_ontology_id]  DEFAULT ((0)) FOR [ontology_id]
GO
