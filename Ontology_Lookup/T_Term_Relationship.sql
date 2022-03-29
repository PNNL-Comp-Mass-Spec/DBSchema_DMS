/****** Object:  Table [dbo].[T_Term_Relationship] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Term_Relationship](
	[term_relationship_id] [int] NOT NULL,
	[subject_term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[predicate_term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[object_term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ontology_id] [int] NOT NULL,
 CONSTRAINT [PK_term_relationship] PRIMARY KEY CLUSTERED 
(
	[term_relationship_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Term_Relationship] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Term_relationship_object_term_pk] ******/
CREATE NONCLUSTERED INDEX [IX_T_Term_relationship_object_term_pk] ON [dbo].[T_Term_Relationship]
(
	[object_term_pk] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Term_relationship_ontology_id] ******/
CREATE NONCLUSTERED INDEX [IX_T_Term_relationship_ontology_id] ON [dbo].[T_Term_Relationship]
(
	[ontology_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Term_relationship_predicate_term_pk] ******/
CREATE NONCLUSTERED INDEX [IX_T_Term_relationship_predicate_term_pk] ON [dbo].[T_Term_Relationship]
(
	[predicate_term_pk] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Term_relationship_subject_term_pk] ******/
CREATE NONCLUSTERED INDEX [IX_T_Term_relationship_subject_term_pk] ON [dbo].[T_Term_Relationship]
(
	[subject_term_pk] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Term_Relationship] ADD  CONSTRAINT [DF_term_relationship_ontology_id]  DEFAULT ((0)) FOR [ontology_id]
GO
