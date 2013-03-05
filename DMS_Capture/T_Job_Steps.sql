/****** Object:  Table [dbo].[T_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ARITHABORT ON
GO
CREATE TABLE [dbo].[T_Job_Steps](
	[Job] [int] NOT NULL,
	[Step_Number] [int] NOT NULL,
	[Step_Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CPU_Load] [smallint] NULL,
	[Dependencies] [tinyint] NOT NULL,
	[State] [tinyint] NOT NULL,
	[Input_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Output_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Processor] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Machine] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Completion_Code] [int] NOT NULL,
	[Completion_Message] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Evaluation_Code] [int] NULL,
	[Evaluation_Message] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Job_Plus_Step]  AS ((CONVERT([varchar](12),[Job],(0))+'.')+CONVERT([varchar](6),[Step_Number],(0))) PERSISTED,
	[Holdoff_Interval_Minutes] [smallint] NULL,
	[Next_Try] [datetime] NULL,
	[Retry_Count] [smallint] NULL,
	[Tool_Version_ID] [int] NULL,
 CONSTRAINT [PK_T_Job_Steps] PRIMARY KEY NONCLUSTERED 
(
	[Job] ASC,
	[Step_Number] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Job_Steps] ******/
CREATE CLUSTERED INDEX [IX_T_Job_Steps] ON [dbo].[T_Job_Steps] 
(
	[Job] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF
/****** Object:  Index [IDX_Job_Plus_Step]    Script Date: 03/04/2013 19:30:46 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IDX_Job_Plus_Step] ON [dbo].[T_Job_Steps] 
(
	[Job_Plus_Step] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Job_Steps_Dependencies_State_include_Job_Step] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_Dependencies_State_include_Job_Step] ON [dbo].[T_Job_Steps] 
(
	[Dependencies] ASC,
	[State] ASC
)
INCLUDE ( [Job],
[Step_Number]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Job_Steps_Machine_include_CPULoad_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_Machine_include_CPULoad_State] ON [dbo].[T_Job_Steps] 
(
	[Machine] ASC
)
INCLUDE ( [CPU_Load],
[State]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Job_Steps_OutputFolderName_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_OutputFolderName_State] ON [dbo].[T_Job_Steps] 
(
	[Output_Folder_Name] ASC,
	[State] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Job_Steps_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_State] ON [dbo].[T_Job_Steps] 
(
	[State] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Job_Steps_State_include_Job_Step_CompletionCode] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_State_include_Job_Step_CompletionCode] ON [dbo].[T_Job_Steps] 
(
	[State] ASC
)
INCLUDE ( [Completion_Code],
[Job],
[Step_Number]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Job_Steps_Step_Tool_State_Next_Try_include_JobStepNumber] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_Step_Tool_State_Next_Try_include_JobStepNumber] ON [dbo].[T_Job_Steps] 
(
	[Step_Tool] ASC,
	[State] ASC,
	[Next_Try] ASC
)
INCLUDE ( [Job],
[Step_Number]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_d_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create TRIGGER trig_d_Job_Steps ON T_Job_Steps 
FOR DELETE
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Job_Step_Events
		(Job, Step, Target_State, Prev_Target_State)
	SELECT deleted.Job, deleted.Step_Number, 0 as New_State, deleted.State as Old_State
	FROM deleted
	ORDER BY deleted.Job, deleted.Step_Number

GO
/****** Object:  Trigger [dbo].[trig_i_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_i_Job_Steps] ON [dbo].[T_Job_Steps] 
FOR INSERT
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Job_Step_Events
		(Job, Step, Target_State, Prev_Target_State)
	SELECT     inserted.Job, inserted.Step_Number as Step, inserted.State as New_State, 0 as Old_State
	FROM inserted
	ORDER BY inserted.Job, inserted.Step_Number

GO
/****** Object:  Trigger [dbo].[trig_u_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER trig_u_Job_Steps ON T_Job_Steps 
FOR UPDATE
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(State)
	Begin
		INSERT INTO T_Job_Step_Events
			(Job, Step, Target_State, Prev_Target_State)
		SELECT     inserted.Job, inserted.Step_Number as Step, inserted.State as New_State, deleted.State as Old_State
		FROM deleted INNER JOIN inserted
		       ON deleted.Job = inserted.Job AND
		          deleted.Step_Number = inserted.Step_Number
		ORDER BY inserted.Job, inserted.Step_Number
	
	End

GO
ALTER TABLE [dbo].[T_Job_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Job_Steps_T_Jobs] FOREIGN KEY([Job])
REFERENCES [T_Jobs] ([Job])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Job_Steps] CHECK CONSTRAINT [FK_T_Job_Steps_T_Jobs]
GO
ALTER TABLE [dbo].[T_Job_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Job_Steps_T_Step_State] FOREIGN KEY([State])
REFERENCES [T_Job_Step_State_Name] ([ID])
GO
ALTER TABLE [dbo].[T_Job_Steps] CHECK CONSTRAINT [FK_T_Job_Steps_T_Step_State]
GO
ALTER TABLE [dbo].[T_Job_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Job_Steps_T_Step_Tool_Versions] FOREIGN KEY([Tool_Version_ID])
REFERENCES [T_Step_Tool_Versions] ([Tool_Version_ID])
GO
ALTER TABLE [dbo].[T_Job_Steps] CHECK CONSTRAINT [FK_T_Job_Steps_T_Step_Tool_Versions]
GO
ALTER TABLE [dbo].[T_Job_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Job_Steps_T_Step_Tools] FOREIGN KEY([Step_Tool])
REFERENCES [T_Step_Tools] ([Name])
GO
ALTER TABLE [dbo].[T_Job_Steps] CHECK CONSTRAINT [FK_T_Job_Steps_T_Step_Tools]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_Dependencies]  DEFAULT ((0)) FOR [Dependencies]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_Evaluated]  DEFAULT ((1)) FOR [State]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_Triggered]  DEFAULT ((0)) FOR [Completion_Code]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_Holdoff_Interval_Minutes]  DEFAULT ((0)) FOR [Holdoff_Interval_Minutes]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_NextTry]  DEFAULT (getdate()) FOR [Next_Try]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_RetryCount]  DEFAULT ((0)) FOR [Retry_Count]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_Tool_Version_ID]  DEFAULT ((1)) FOR [Tool_Version_ID]
GO
