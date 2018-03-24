/****** Object:  Table [dbo].[T_Cached_Protein_Collections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Protein_Collections](
	[ID] [int] NOT NULL,
	[Organism_ID] [int] NOT NULL,
	[Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](900) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entries] [int] NULL,
	[Residues] [int] NULL,
	[Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Filesize] [bigint] NULL,
	[Created] [datetime] NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Cached_Protein_Collections] PRIMARY KEY CLUSTERED 
(
	[ID] ASC,
	[Organism_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Cached_Protein_Collections] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Cached_Protein_Collections_Organism] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cached_Protein_Collections_Organism] ON [dbo].[T_Cached_Protein_Collections]
(
	[Organism_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Cached_Protein_Collections] ADD  CONSTRAINT [DF_T_Cached_Protein_Collections_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Cached_Protein_Collections] ADD  CONSTRAINT [DF_T_Cached_Protein_Collections_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
