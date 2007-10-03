/****** Object:  Table [dbo].[T_Cell_Culture_Annotations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cell_Culture_Annotations](
	[CC_ID] [int] NOT NULL,
	[Key_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Value] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NULL CONSTRAINT [DF_T_Cell_Culture_Annotations_Entered]  DEFAULT (getdate()),
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Cell_Culture_Annotations_Entered_By]  DEFAULT (suser_sname()),
 CONSTRAINT [PK_T_Cell_Culture_Annotations] PRIMARY KEY CLUSTERED 
(
	[CC_ID] ASC,
	[Key_Name] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Trigger [dbo].[trig_u_T_Cell_Culture_Annotations] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[trig_u_T_Cell_Culture_Annotations] ON [dbo].[T_Cell_Culture_Annotations] 
FOR UPDATE
AS
/****************************************************
**
**	Desc: 
**		Updates the Entered and Entered_By fields if any of the fields are changed
**
**		Auth: mem
**		Date: 05/04/2007 (Ticket:431)
**    
*****************************************************/
	
	If @@RowCount = 0
		Return

	If Update(CC_ID) OR
	   Update(Key_Name) OR
	   Update(Value)
	Begin

		UPDATE T_Cell_Culture_Annotations
		SET Entered = GetDate(),
			Entered_By = SYSTEM_USER
		FROM T_Cell_Culture_Annotations EA INNER JOIN
			 inserted ON EA.CC_ID = inserted.CC_ID AND EA.Key_Name = inserted.Key_Name
	End


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
GRANT UPDATE ON [dbo].[T_Cell_Culture_Annotations] ([Entered]) TO [DMS_Annotation_User]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture_Annotations] ([Entered_By]) TO [DMS_Annotation_User]
GO
ALTER TABLE [dbo].[T_Cell_Culture_Annotations]  WITH CHECK ADD  CONSTRAINT [FK_T_Cell_Culture_Annotations_T_Annotation_Keys] FOREIGN KEY([Key_Name])
REFERENCES [T_Annotation_Keys] ([Key_Name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Cell_Culture_Annotations]  WITH CHECK ADD  CONSTRAINT [FK_T_Cell_Culture_Annotations_T_Cell_Culture] FOREIGN KEY([CC_ID])
REFERENCES [T_Cell_Culture] ([CC_ID])
ON DELETE CASCADE
GO
