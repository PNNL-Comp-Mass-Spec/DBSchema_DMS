/****** Object:  Table [dbo].[T_Task_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Task_Steps](
	[Job] [int] NOT NULL,
	[Step] [int] NOT NULL,
	[Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CPU_Load] [smallint] NULL,
	[Dependencies] [tinyint] NOT NULL,
	[State] [tinyint] NOT NULL,
	[Input_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Output_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Processor] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Completion_Code] [int] NOT NULL,
	[Completion_Message] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Evaluation_Code] [int] NULL,
	[Evaluation_Message] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Job_Plus_Step]  AS ((CONVERT([varchar](12),[Job],(0))+'.')+CONVERT([varchar](6),[Step],(0))) PERSISTED,
	[Holdoff_Interval_Minutes] [smallint] NULL,
	[Next_Try] [datetime] NULL,
	[Retry_Count] [smallint] NULL,
	[Tool_Version_ID] [int] NULL,
	[Step_Number]  AS ([Step]),
	[Step_Tool]  AS ([Tool]),
 CONSTRAINT [PK_T_Task_Steps] PRIMARY KEY CLUSTERED
(
	[Job] ASC,
	[Step] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Task_Steps] TO [DDL_Viewer] AS [dbo]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IX_Job_Plus_Step] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Job_Plus_Step] ON [dbo].[T_Task_Steps]
(
	[Job_Plus_Step] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Task_Steps] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Steps] ON [dbo].[T_Task_Steps]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Task_Steps_Dependencies_State_include_Job_Step] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Steps_Dependencies_State_include_Job_Step] ON [dbo].[T_Task_Steps]
(
	[Dependencies] ASC,
	[State] ASC
)
INCLUDE([Job],[Step]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Task_Steps_OutputFolderName_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Steps_OutputFolderName_State] ON [dbo].[T_Task_Steps]
(
	[Output_Folder_Name] ASC,
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Task_Steps_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Steps_State] ON [dbo].[T_Task_Steps]
(
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Task_Steps_State_include_Job_Step_CompletionCode] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Steps_State_include_Job_Step_CompletionCode] ON [dbo].[T_Task_Steps]
(
	[State] ASC
)
INCLUDE([Completion_Code],[Job],[Step]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Task_Steps_Tool_State_Next_Try_include_Job_Step] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Steps_Tool_State_Next_Try_include_Job_Step] ON [dbo].[T_Task_Steps]
(
	[Tool] ASC,
	[State] ASC,
	[Next_Try] ASC
)
INCLUDE([Job],[Step]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Task_Steps] ADD  CONSTRAINT [DF_T_Task_Steps_Dependencies]  DEFAULT ((0)) FOR [Dependencies]
GO
ALTER TABLE [dbo].[T_Task_Steps] ADD  CONSTRAINT [DF_T_Task_Steps_Evaluated]  DEFAULT ((1)) FOR [State]
GO
ALTER TABLE [dbo].[T_Task_Steps] ADD  CONSTRAINT [DF_T_Task_Steps_Triggered]  DEFAULT ((0)) FOR [Completion_Code]
GO
ALTER TABLE [dbo].[T_Task_Steps] ADD  CONSTRAINT [DF_T_Task_Steps_Holdoff_Interval_Minutes]  DEFAULT ((0)) FOR [Holdoff_Interval_Minutes]
GO
ALTER TABLE [dbo].[T_Task_Steps] ADD  CONSTRAINT [DF_T_Task_Steps_NextTry]  DEFAULT (getdate()) FOR [Next_Try]
GO
ALTER TABLE [dbo].[T_Task_Steps] ADD  CONSTRAINT [DF_T_Task_Steps_RetryCount]  DEFAULT ((0)) FOR [Retry_Count]
GO
ALTER TABLE [dbo].[T_Task_Steps] ADD  CONSTRAINT [DF_T_Task_Steps_Tool_Version_ID]  DEFAULT ((1)) FOR [Tool_Version_ID]
GO
ALTER TABLE [dbo].[T_Task_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Task_Steps_T_Local_Processors] FOREIGN KEY([Processor])
REFERENCES [dbo].[T_Local_Processors] ([Processor_Name])
GO
ALTER TABLE [dbo].[T_Task_Steps] CHECK CONSTRAINT [FK_T_Task_Steps_T_Local_Processors]
GO
ALTER TABLE [dbo].[T_Task_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Task_Steps_T_Step_State] FOREIGN KEY([State])
REFERENCES [dbo].[T_Task_Step_State_Name] ([ID])
GO
ALTER TABLE [dbo].[T_Task_Steps] CHECK CONSTRAINT [FK_T_Task_Steps_T_Step_State]
GO
ALTER TABLE [dbo].[T_Task_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Task_Steps_T_Step_Tool_Versions] FOREIGN KEY([Tool_Version_ID])
REFERENCES [dbo].[T_Step_Tool_Versions] ([Tool_Version_ID])
GO
ALTER TABLE [dbo].[T_Task_Steps] CHECK CONSTRAINT [FK_T_Task_Steps_T_Step_Tool_Versions]
GO
ALTER TABLE [dbo].[T_Task_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Task_Steps_T_Step_Tools] FOREIGN KEY([Tool])
REFERENCES [dbo].[T_Step_Tools] ([Name])
GO
ALTER TABLE [dbo].[T_Task_Steps] CHECK CONSTRAINT [FK_T_Task_Steps_T_Step_Tools]
GO
ALTER TABLE [dbo].[T_Task_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Task_Steps_T_Tasks] FOREIGN KEY([Job])
REFERENCES [dbo].[T_Tasks] ([Job])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Task_Steps] CHECK CONSTRAINT [FK_T_Task_Steps_T_Tasks]
GO
/****** Object:  Trigger [dbo].[trig_d_T_Task_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER trig_d_T_Task_Steps ON T_Task_Steps
FOR DELETE
/****************************************************
**
**	Desc:
**		Add new rows to T_Task_Step_Events for deleted task steps
**
**	Auth:	grk
**	Date:	09/15/2009 grk - Initial version
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Task_Step_Events
		(Job, Step, Target_State, Prev_Target_State)
	SELECT deleted.Job, deleted.Step, 0 as New_State, deleted.State as Old_State
	FROM deleted
	ORDER BY deleted.Job, deleted.Step

GO
ALTER TABLE [dbo].[T_Task_Steps] ENABLE TRIGGER [trig_d_T_Task_Steps]
GO
/****** Object:  Trigger [dbo].[trig_i_T_Task_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_i_T_Task_Steps] ON [dbo].[T_Task_Steps]
FOR INSERT
/****************************************************
**
**	Desc:
**		Add new rows to T_Task_Step_Events for inserted task steps
**
**	Auth:	grk
**	Date:	09/15/2009 grk - Initial version
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Task_Step_Events
		(Job, Step, Target_State, Prev_Target_State)
	SELECT inserted.Job, inserted.Step as Step, inserted.State as New_State, 0 as Old_State
	FROM inserted
	ORDER BY inserted.Job, inserted.Step

GO
ALTER TABLE [dbo].[T_Task_Steps] ENABLE TRIGGER [trig_i_T_Task_Steps]
GO
/****** Object:  Trigger [dbo].[trig_u_T_Task_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER trig_u_T_Task_Steps ON T_Task_Steps
FOR UPDATE
/****************************************************
**
**	Desc:
**		Add new rows to T_Task_Step_Events for updated task steps
**
**	Auth:	grk
**	Date:	09/15/2009 grk - Initial version
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(State)
	Begin
		INSERT INTO T_Task_Step_Events
			(Job, Step, Target_State, Prev_Target_State)
		SELECT inserted.Job, inserted.Step as Step, inserted.State as New_State, deleted.State as Old_State
		FROM deleted INNER JOIN inserted
		       ON deleted.Job = inserted.Job AND
		          deleted.Step = inserted.Step
		ORDER BY inserted.Job, inserted.Step

	End

GO
ALTER TABLE [dbo].[T_Task_Steps] ENABLE TRIGGER [trig_u_T_Task_Steps]
GO
