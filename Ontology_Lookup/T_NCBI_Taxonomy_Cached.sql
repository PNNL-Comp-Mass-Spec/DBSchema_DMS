/****** Object:  Table [dbo].[T_NCBI_Taxonomy_Cached] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_NCBI_Taxonomy_Cached](
	[Tax_ID] [int] NOT NULL,
	[Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Rank] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Parent_Tax_ID] [int] NOT NULL,
	[Synonyms] [int] NOT NULL,
	[Synonym_List] [varchar](2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_NCBI_Taxonomy_Cached] PRIMARY KEY CLUSTERED 
(
	[Tax_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_NCBI_Taxonomy_Cached] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_NCBI_Taxonomy_Cached_Tax_ID_include_NameAndSynomyms] ******/
CREATE NONCLUSTERED INDEX [IX_T_NCBI_Taxonomy_Cached_Tax_ID_include_NameAndSynomyms] ON [dbo].[T_NCBI_Taxonomy_Cached]
(
	[Tax_ID] ASC
)
INCLUDE([Name],[Synonyms]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_NCBI_Taxonomy_Cached] ADD  DEFAULT ((0)) FOR [Synonyms]
GO
