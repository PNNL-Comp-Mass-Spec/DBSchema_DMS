/****** Object:  Table [dbo].[T_Cell_Culture_Annotations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cell_Culture_Annotations](
	[CC_ID] [int] NOT NULL,
	[Key_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Value] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Cell_Culture_Annotations] PRIMARY KEY CLUSTERED 
(
	[CC_ID] ASC,
	[Key_Name] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT INSERT ON [dbo].[T_Cell_Culture_Annotations] TO [DMS_Annotation_User]
GO
GRANT DELETE ON [dbo].[T_Cell_Culture_Annotations] TO [DMS_Annotation_User]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture_Annotations] TO [DMS_Annotation_User]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture_Annotations] ([CC_ID]) TO [DMS_Annotation_User]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture_Annotations] ([Key_Name]) TO [DMS_Annotation_User]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture_Annotations] ([Value]) TO [DMS_Annotation_User]
GO
ALTER TABLE [dbo].[T_Cell_Culture_Annotations]  WITH CHECK ADD  CONSTRAINT [FK_T_Cell_Culture_Annotations_T_Annotation_Keys] FOREIGN KEY([Key_Name])
REFERENCES [T_Annotation_Keys] ([Key_Name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Cell_Culture_Annotations]  WITH CHECK ADD  CONSTRAINT [FK_T_Cell_Culture_Annotations_T_Cell_Culture] FOREIGN KEY([CC_ID])
REFERENCES [T_Cell_Culture] ([CC_ID])
ON DELETE CASCADE
GO
