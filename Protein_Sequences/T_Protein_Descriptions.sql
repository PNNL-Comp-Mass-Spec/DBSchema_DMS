/****** Object:  Table [dbo].[T_Protein_Descriptions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Protein_Descriptions](
	[Description_ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](900) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Fingerprint] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DateAdded] [datetime] NULL,
	[Reference_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Protein_Descriptions] PRIMARY KEY CLUSTERED 
(
	[Description_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Descriptions] ******/
CREATE NONCLUSTERED INDEX [IX_Descriptions] ON [dbo].[T_Protein_Descriptions]
(
	[Description] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_TPD_Ref_ID] ******/
CREATE NONCLUSTERED INDEX [IX_TPD_Ref_ID] ON [dbo].[T_Protein_Descriptions]
(
	[Reference_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Protein_Descriptions] ADD  CONSTRAINT [DF__T_Protein__DateA__2AC04CAA]  DEFAULT (getdate()) FOR [DateAdded]
GO
ALTER TABLE [dbo].[T_Protein_Descriptions]  WITH CHECK ADD  CONSTRAINT [FK_T_Protein_Descriptions_T_Protein_Names] FOREIGN KEY([Reference_ID])
REFERENCES [dbo].[T_Protein_Names] ([Reference_ID])
GO
ALTER TABLE [dbo].[T_Protein_Descriptions] CHECK CONSTRAINT [FK_T_Protein_Descriptions_T_Protein_Names]
GO
