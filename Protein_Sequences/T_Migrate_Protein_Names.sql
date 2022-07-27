/****** Object:  Table [dbo].[T_Migrate_Protein_Names] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Migrate_Protein_Names](
	[Reference_ID] [int] NOT NULL,
	[Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Annotation_Type_ID] [int] NOT NULL,
	[Reference_Fingerprint] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DateAdded] [datetime] NULL,
	[Protein_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Migrate_Protein_Names] PRIMARY KEY NONCLUSTERED 
(
	[Reference_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Migrate_Protein_Names_Protein_ID_Reference_ID] ******/
CREATE UNIQUE CLUSTERED INDEX [IX_T_Migrate_Protein_Names_Protein_ID_Reference_ID] ON [dbo].[T_Migrate_Protein_Names]
(
	[Protein_ID] ASC,
	[Reference_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Migrate_Protein_Names_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Migrate_Protein_Names_Name] ON [dbo].[T_Migrate_Protein_Names]
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Migrate_Protein_Names_ProteinID_include_RefID_Name_Desc_Annotn] ******/
CREATE NONCLUSTERED INDEX [IX_T_Migrate_Protein_Names_ProteinID_include_RefID_Name_Desc_Annotn] ON [dbo].[T_Migrate_Protein_Names]
(
	[Protein_ID] ASC
)
INCLUDE([Reference_ID],[Name],[Description],[Annotation_Type_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Migrate_Protein_Names_Ref_Fingerprint] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Migrate_Protein_Names_Ref_Fingerprint] ON [dbo].[T_Migrate_Protein_Names]
(
	[Reference_Fingerprint] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Migrate_Protein_Names]  WITH CHECK ADD  CONSTRAINT [FK_T_Migrate_Protein_Names_T_Annotation_Types] FOREIGN KEY([Annotation_Type_ID])
REFERENCES [dbo].[T_Annotation_Types] ([Annotation_Type_ID])
GO
ALTER TABLE [dbo].[T_Migrate_Protein_Names] CHECK CONSTRAINT [FK_T_Migrate_Protein_Names_T_Annotation_Types]
GO
ALTER TABLE [dbo].[T_Migrate_Protein_Names]  WITH CHECK ADD  CONSTRAINT [FK_T_Migrate_Protein_Names_T_Migrate_Proteins] FOREIGN KEY([Protein_ID])
REFERENCES [dbo].[T_Migrate_Proteins] ([Protein_ID])
GO
ALTER TABLE [dbo].[T_Migrate_Protein_Names] CHECK CONSTRAINT [FK_T_Migrate_Protein_Names_T_Migrate_Proteins]
GO
