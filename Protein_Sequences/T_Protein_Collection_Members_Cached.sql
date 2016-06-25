/****** Object:  Table [dbo].[T_Protein_Collection_Members_Cached] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Protein_Collection_Members_Cached](
	[Protein_Collection_ID] [int] NOT NULL,
	[Reference_ID] [int] NOT NULL,
	[Protein_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Residue_Count] [int] NOT NULL,
	[Monoisotopic_Mass] [float] NULL,
	[Protein_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Protein_Collection_Members_Cached] PRIMARY KEY CLUSTERED 
(
	[Protein_Collection_ID] ASC,
	[Reference_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Protein_Collection_Members_Cached_Protein_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Protein_Collection_Members_Cached_Protein_ID] ON [dbo].[T_Protein_Collection_Members_Cached]
(
	[Protein_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Protein_Collection_Members_Cached]  WITH CHECK ADD  CONSTRAINT [FK_T_Protein_Collection_Members_Cached_T_Protein_Collections] FOREIGN KEY([Protein_Collection_ID])
REFERENCES [dbo].[T_Protein_Collections] ([Protein_Collection_ID])
GO
ALTER TABLE [dbo].[T_Protein_Collection_Members_Cached] CHECK CONSTRAINT [FK_T_Protein_Collection_Members_Cached_T_Protein_Collections]
GO
