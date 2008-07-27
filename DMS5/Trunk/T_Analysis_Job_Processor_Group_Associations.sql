/****** Object:  Table [dbo].[T_Analysis_Job_Processor_Group_Associations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processor_Group_Associations](
	[Job_ID] [int] NOT NULL,
	[Group_ID] [int] NOT NULL,
	[Entered] [datetime] NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Associations_Entered]  DEFAULT (getdate()),
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Associations_Entered_By]  DEFAULT (suser_sname()),
 CONSTRAINT [PK_T_Analysis_Job_Processor_Group_Associations] PRIMARY KEY CLUSTERED 
(
	[Job_ID] ASC,
	[Group_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Analysis_Job_Processor_Group_Job_Associations_ID_Gropu_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Processor_Group_Job_Associations_ID_Gropu_ID] ON [dbo].[T_Analysis_Job_Processor_Group_Associations] 
(
	[Job_ID] ASC,
	[Group_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Trigger [trig_u_T_Analysis_Job_Processor_Group_Associations] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE Trigger [dbo].[trig_u_T_Analysis_Job_Processor_Group_Associations] on [dbo].[T_Analysis_Job_Processor_Group_Associations]
For Update
/****************************************************
**
**	Desc: 
**		Updates Entered and Entered_By if Group_ID is changed
**
**	Auth:	mem
**	Date:	04/27/2008
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(Group_ID)
	Begin
		UPDATE T_Analysis_Job_Processor_Group_Associations
		SET Entered = GetDate(),
			Entered_By = suser_sname()
		FROM T_Analysis_Job_Processor_Group_Associations AJPGA
			 INNER JOIN inserted
			   ON inserted.Job_ID = AJPGA.Job_ID

	End


GO
GRANT INSERT ON [dbo].[T_Analysis_Job_Processor_Group_Associations] TO [RBAC-Web_Analysis]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Processor_Group_Associations] TO [RBAC-Web_Analysis]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Processor_Group_Associations] TO [RBAC-Web_Analysis]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Processor_Group_Associations] ([Entered_By]) TO [DMS2_SP_User]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Associations]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Processor_Group_Associations_T_Analysis_Job] FOREIGN KEY([Job_ID])
REFERENCES [T_Analysis_Job] ([AJ_jobID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Associations] CHECK CONSTRAINT [FK_T_Analysis_Job_Processor_Group_Associations_T_Analysis_Job]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Associations]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Processor_Group_Associations_T_Analysis_Job_Processor_Group] FOREIGN KEY([Group_ID])
REFERENCES [T_Analysis_Job_Processor_Group] ([ID])
GO
