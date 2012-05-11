/****** Object:  Table [dbo].[T_Archived_Output_File_Collections_XRef] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Archived_Output_File_Collections_XRef](
	[Archived_File_Member_ID] [int] IDENTITY(1,1) NOT NULL,
	[Archived_File_ID] [int] NOT NULL,
	[Protein_Collection_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Archived_Output_File_Collections_XRef] PRIMARY KEY CLUSTERED 
(
	[Archived_File_Member_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Archived_Output_File_Collections_XRef_Archived_File_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Archived_Output_File_Collections_XRef_Archived_File_ID] ON [dbo].[T_Archived_Output_File_Collections_XRef] 
(
	[Archived_File_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Archived_Output_File_Collections_XRef_Protein_Collection_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Archived_Output_File_Collections_XRef_Protein_Collection_ID] ON [dbo].[T_Archived_Output_File_Collections_XRef] 
(
	[Protein_Collection_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Archived_Output_File_Collections_XRef]  WITH CHECK ADD  CONSTRAINT [FK_T_Archived_Output_File_Collections_XRef_T_Archived_Output_Files] FOREIGN KEY([Archived_File_ID])
REFERENCES [T_Archived_Output_Files] ([Archived_File_ID])
GO
ALTER TABLE [dbo].[T_Archived_Output_File_Collections_XRef] CHECK CONSTRAINT [FK_T_Archived_Output_File_Collections_XRef_T_Archived_Output_Files]
GO
ALTER TABLE [dbo].[T_Archived_Output_File_Collections_XRef]  WITH CHECK ADD  CONSTRAINT [FK_T_Archived_Output_File_Collections_XRef_T_Protein_Collections] FOREIGN KEY([Protein_Collection_ID])
REFERENCES [T_Protein_Collections] ([Protein_Collection_ID])
GO
ALTER TABLE [dbo].[T_Archived_Output_File_Collections_XRef] CHECK CONSTRAINT [FK_T_Archived_Output_File_Collections_XRef_T_Protein_Collections]
GO
