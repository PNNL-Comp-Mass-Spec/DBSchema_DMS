/****** Object:  Table [dbo].[T_Processor_Tool] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Processor_Tool](
	[Processor_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Tool_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Priority] [tinyint] NOT NULL,
	[Enabled] [smallint] NOT NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Processor_Tool] PRIMARY KEY CLUSTERED 
(
	[Processor_Name] ASC,
	[Tool_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Processor_Tool] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Processor_Tool] ADD  CONSTRAINT [DF_T_Processor_Tool_Priority]  DEFAULT ((3)) FOR [Priority]
GO
ALTER TABLE [dbo].[T_Processor_Tool] ADD  CONSTRAINT [DF_T_Processor_Tool_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[T_Processor_Tool] ADD  CONSTRAINT [DF_T_Processor_Tool_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Processor_Tool] ADD  CONSTRAINT [DF_T_Processor_Tool_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Processor_Tool]  WITH CHECK ADD  CONSTRAINT [FK_T_Processor_Tool_T_Step_Tools] FOREIGN KEY([Tool_Name])
REFERENCES [dbo].[T_Step_Tools] ([Name])
GO
ALTER TABLE [dbo].[T_Processor_Tool] CHECK CONSTRAINT [FK_T_Processor_Tool_T_Step_Tools]
GO
/****** Object:  Trigger [dbo].[trig_u_Processor_Tool] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Trigger [dbo].[trig_u_Processor_Tool] on [dbo].[T_Processor_Tool]
For Update
/****************************************************
**
**	Desc: 
**		Updates column Last_Affected
**
**	Auth:	mem
**	Date:	03/24/2012 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(Priority) OR Update(Enabled)
	Begin
		UPDATE T_Processor_Tool
		SET Last_Affected = GetDate()
		FROM T_Processor_Tool PT
		     INNER JOIN inserted
		       ON PT.Processor_Name = inserted.Processor_Name AND
		          PT.Tool_Name = inserted.Tool_Name

	End



GO
