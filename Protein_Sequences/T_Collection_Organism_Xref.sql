/****** Object:  Table [dbo].[T_Collection_Organism_Xref] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Collection_Organism_Xref](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Protein_Collection_ID] [int] NOT NULL,
	[Organism_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Collection_Organism_Xref] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Collection_Organism_Xref_ProtCollectionID_OrganismID] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Collection_Organism_Xref_ProtCollectionID_OrganismID] ON [dbo].[T_Collection_Organism_Xref]
(
	[Protein_Collection_ID] ASC,
	[Organism_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
