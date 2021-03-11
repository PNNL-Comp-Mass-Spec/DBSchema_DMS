/****** Object:  Table [dbo].[T_Processor_Tool_Group_Details] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Processor_Tool_Group_Details](
	[Group_ID] [int] NOT NULL,
	[Mgr_ID] [smallint] NOT NULL,
	[Tool_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Priority] [tinyint] NOT NULL,
	[Enabled] [smallint] NOT NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Max_Step_Cost] [tinyint] NOT NULL,
	[Max_Job_Priority] [tinyint] NOT NULL,
	[Last_Affected] [datetime] NULL,
 CONSTRAINT [PK_T_Processor_Tool_Group_Details] PRIMARY KEY CLUSTERED 
(
	[Group_ID] ASC,
	[Mgr_ID] ASC,
	[Tool_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Processor_Tool_Group_Details] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Processor_Tool_Group_Details] ADD  CONSTRAINT [DF_T_Processor_Tool_Group_Details_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Processor_Tool_Group_Details] ADD  CONSTRAINT [DF_T_Processor_Tool_Group_Details_Max_Step_Cost]  DEFAULT ((100)) FOR [Max_Step_Cost]
GO
ALTER TABLE [dbo].[T_Processor_Tool_Group_Details] ADD  CONSTRAINT [DF_T_Processor_Tool_Group_Details_Max_Job_Priority]  DEFAULT ((50)) FOR [Max_Job_Priority]
GO
ALTER TABLE [dbo].[T_Processor_Tool_Group_Details] ADD  CONSTRAINT [DF_T_Processor_Tool_Group_Details_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Processor_Tool_Group_Details]  WITH CHECK ADD  CONSTRAINT [FK_T_Processor_Tool_Group_Details_T_Processor_Tool_Groups] FOREIGN KEY([Group_ID])
REFERENCES [dbo].[T_Processor_Tool_Groups] ([Group_ID])
GO
ALTER TABLE [dbo].[T_Processor_Tool_Group_Details] CHECK CONSTRAINT [FK_T_Processor_Tool_Group_Details_T_Processor_Tool_Groups]
GO
ALTER TABLE [dbo].[T_Processor_Tool_Group_Details]  WITH CHECK ADD  CONSTRAINT [FK_T_Processor_Tool_Group_Details_T_Step_Tools] FOREIGN KEY([Tool_Name])
REFERENCES [dbo].[T_Step_Tools] ([Name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Processor_Tool_Group_Details] CHECK CONSTRAINT [FK_T_Processor_Tool_Group_Details_T_Step_Tools]
GO
/****** Object:  Trigger [dbo].[trig_u_Processor_Tool_Group_Details] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_u_Processor_Tool_Group_Details] on [dbo].[T_Processor_Tool_Group_Details]
For Update
/****************************************************
**
**	Desc: 
**		Updates column Last_Affected
**
**	Auth:	mem
**	Date:	07/26/2011 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(Priority) OR Update(Enabled)
	Begin
		UPDATE T_Processor_Tool_Group_Details
		SET Last_Affected = GetDate()
		FROM T_Processor_Tool_Group_Details PTGD
		     INNER JOIN inserted
		       ON PTGD.Group_ID = inserted.Group_ID AND
		          PTGD.Mgr_ID = inserted.Mgr_ID AND
		          PTGD.Tool_Name = inserted.Tool_Name

	End

GO
ALTER TABLE [dbo].[T_Processor_Tool_Group_Details] ENABLE TRIGGER [trig_u_Processor_Tool_Group_Details]
GO
