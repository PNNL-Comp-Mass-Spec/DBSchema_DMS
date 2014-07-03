/****** Object:  Table [dbo].[T_Annotation_Groups] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Annotation_Groups](
	[Annotation_Group_ID] [int] IDENTITY(1,1) NOT NULL,
	[Protein_Collection_ID] [int] NOT NULL,
	[Annotation_Group] [smallint] NOT NULL,
	[Annotation_Type_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Annotation_Groups] PRIMARY KEY CLUSTERED 
(
	[Annotation_Group_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Annotation_Groups]  WITH CHECK ADD  CONSTRAINT [FK_T_Annotation_Groups_T_Annotation_Types] FOREIGN KEY([Annotation_Type_ID])
REFERENCES [dbo].[T_Annotation_Types] ([Annotation_Type_ID])
GO
ALTER TABLE [dbo].[T_Annotation_Groups] CHECK CONSTRAINT [FK_T_Annotation_Groups_T_Annotation_Types]
GO
ALTER TABLE [dbo].[T_Annotation_Groups]  WITH CHECK ADD  CONSTRAINT [FK_T_Annotation_Groups_T_Protein_Collections] FOREIGN KEY([Protein_Collection_ID])
REFERENCES [dbo].[T_Protein_Collections] ([Protein_Collection_ID])
GO
ALTER TABLE [dbo].[T_Annotation_Groups] CHECK CONSTRAINT [FK_T_Annotation_Groups_T_Protein_Collections]
GO
