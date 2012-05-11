/****** Object:  Table [dbo].[T_Protein_Collection_Members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Protein_Collection_Members](
	[Member_ID] [int] IDENTITY(1,1) NOT NULL,
	[Original_Reference_ID] [int] NOT NULL,
	[Protein_ID] [int] NOT NULL,
	[Protein_Collection_ID] [int] NOT NULL,
	[Sorting_Index] [int] NULL,
	[Original_Description_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Protein_Collection_Members] PRIMARY KEY NONCLUSTERED 
(
	[Member_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Protein_Collection_Members_Coll_ID] ******/
CREATE CLUSTERED INDEX [IX_T_Protein_Collection_Members_Coll_ID] ON [dbo].[T_Protein_Collection_Members] 
(
	[Protein_Collection_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Protein_Collection_Members] ******/
CREATE NONCLUSTERED INDEX [IX_T_Protein_Collection_Members] ON [dbo].[T_Protein_Collection_Members] 
(
	[Protein_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Protein_Collection_Members_Ref_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Protein_Collection_Members_Ref_ID] ON [dbo].[T_Protein_Collection_Members] 
(
	[Original_Reference_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Protein_Collection_Members_Sorting_Index] ******/
CREATE NONCLUSTERED INDEX [IX_T_Protein_Collection_Members_Sorting_Index] ON [dbo].[T_Protein_Collection_Members] 
(
	[Protein_Collection_ID] ASC,
	[Sorting_Index] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Protein_Collection_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Protein_Collection_Members_T_Protein_Collections] FOREIGN KEY([Protein_Collection_ID])
REFERENCES [T_Protein_Collections] ([Protein_Collection_ID])
GO
ALTER TABLE [dbo].[T_Protein_Collection_Members] CHECK CONSTRAINT [FK_T_Protein_Collection_Members_T_Protein_Collections]
GO
ALTER TABLE [dbo].[T_Protein_Collection_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Protein_Collection_Members_T_Protein_Names] FOREIGN KEY([Original_Reference_ID])
REFERENCES [T_Protein_Names] ([Reference_ID])
GO
ALTER TABLE [dbo].[T_Protein_Collection_Members] CHECK CONSTRAINT [FK_T_Protein_Collection_Members_T_Protein_Names]
GO
ALTER TABLE [dbo].[T_Protein_Collection_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Protein_Collection_Members_T_Proteins] FOREIGN KEY([Protein_ID])
REFERENCES [T_Proteins] ([Protein_ID])
GO
ALTER TABLE [dbo].[T_Protein_Collection_Members] CHECK CONSTRAINT [FK_T_Protein_Collection_Members_T_Proteins]
GO
ALTER TABLE [dbo].[T_Protein_Collection_Members] ADD  CONSTRAINT [DF_Protein_Collection_Members_Original_Description_ID]  DEFAULT ((0)) FOR [Original_Description_ID]
GO
