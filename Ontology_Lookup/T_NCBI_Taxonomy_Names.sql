/****** Object:  Table [dbo].[T_NCBI_Taxonomy_Names] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_NCBI_Taxonomy_Names](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Tax_ID] [int] NOT NULL,
	[Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Unique_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Name_Class] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_NCBI_Taxonomy_Names] PRIMARY KEY NONCLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_NCBI_Taxonomy_Names] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_NCBI_Taxonomy_Names_Tax_ID] ******/
CREATE CLUSTERED INDEX [IX_T_NCBI_Taxonomy_Names_Tax_ID] ON [dbo].[T_NCBI_Taxonomy_Names]
(
	[Tax_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_NCBI_Taxonomy_Names_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_NCBI_Taxonomy_Names_Name] ON [dbo].[T_NCBI_Taxonomy_Names]
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_NCBI_Taxonomy_Names_NameClass_Name_include_TaxID] ******/
CREATE NONCLUSTERED INDEX [IX_T_NCBI_Taxonomy_Names_NameClass_Name_include_TaxID] ON [dbo].[T_NCBI_Taxonomy_Names]
(
	[Name_Class] ASC,
	[Name] ASC
)
INCLUDE([Tax_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_NCBI_Taxonomy_Names]  WITH CHECK ADD  CONSTRAINT [FK_T_NCBI_Taxonomy_Names_T_NCBI_Taxonomy_Nodes] FOREIGN KEY([Tax_ID])
REFERENCES [dbo].[T_NCBI_Taxonomy_Nodes] ([Tax_ID])
GO
ALTER TABLE [dbo].[T_NCBI_Taxonomy_Names] CHECK CONSTRAINT [FK_T_NCBI_Taxonomy_Names_T_NCBI_Taxonomy_Nodes]
GO
