/****** Object:  Table [dbo].[T_NCBI_Taxonomy_Nodes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_NCBI_Taxonomy_Nodes](
	[Tax_ID] [int] NOT NULL,
	[Parent_Tax_ID] [int] NOT NULL,
	[Rank] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EMBL_Code] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Division_ID] [smallint] NOT NULL,
	[Inherited_Div] [tinyint] NOT NULL,
	[Genetic_Code_ID] [smallint] NOT NULL,
	[Inherited_GC] [tinyint] NOT NULL,
	[Mito_Genetic_Code_ID] [smallint] NOT NULL,
	[Inherited_MitoGC] [tinyint] NOT NULL,
	[GenBank_Hidden] [tinyint] NOT NULL,
	[Hidden_Subtree] [tinyint] NOT NULL,
	[Comments] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_NCBI_Taxonomy_Nodes] PRIMARY KEY CLUSTERED 
(
	[Tax_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_NCBI_Taxonomy_Nodes_Parent_Tax_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_NCBI_Taxonomy_Nodes_Parent_Tax_ID] ON [dbo].[T_NCBI_Taxonomy_Nodes]
(
	[Parent_Tax_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_NCBI_Taxonomy_Nodes]  WITH CHECK ADD  CONSTRAINT [FK_T_NCBI_Taxonomy_Nodes_T_NCBI_Taxonomy_Division] FOREIGN KEY([Division_ID])
REFERENCES [dbo].[T_NCBI_Taxonomy_Division] ([Division_ID])
GO
ALTER TABLE [dbo].[T_NCBI_Taxonomy_Nodes] CHECK CONSTRAINT [FK_T_NCBI_Taxonomy_Nodes_T_NCBI_Taxonomy_Division]
GO
ALTER TABLE [dbo].[T_NCBI_Taxonomy_Nodes]  WITH CHECK ADD  CONSTRAINT [FK_T_NCBI_Taxonomy_Nodes_T_NCBI_Taxonomy_GenCode] FOREIGN KEY([Genetic_Code_ID])
REFERENCES [dbo].[T_NCBI_Taxonomy_GenCode] ([Genetic_Code_ID])
GO
ALTER TABLE [dbo].[T_NCBI_Taxonomy_Nodes] CHECK CONSTRAINT [FK_T_NCBI_Taxonomy_Nodes_T_NCBI_Taxonomy_GenCode]
GO
