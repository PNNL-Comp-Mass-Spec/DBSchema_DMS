/****** Object:  Table [dbo].[T_Migrate_Protein_Headers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Migrate_Protein_Headers](
	[Protein_ID] [int] NOT NULL,
	[Sequence_Head] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Migrate_Protein_Headers] PRIMARY KEY CLUSTERED 
(
	[Protein_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Migrate_Protein_Headers] ******/
CREATE NONCLUSTERED INDEX [IX_T_Migrate_Protein_Headers] ON [dbo].[T_Migrate_Protein_Headers]
(
	[Sequence_Head] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
