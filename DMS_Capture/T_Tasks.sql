/****** Object:  Table [dbo].[T_Tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Tasks](
	[Job] [int] IDENTITY(1000,1) NOT NULL,
	[Priority] [int] NULL,
	[Script] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[State] [int] NOT NULL,
	[Dataset] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_ID] [int] NULL,
	[Storage_Server] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_Class] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Max_Simultaneous_Captures] [int] NULL,
	[Results_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Imported] [datetime] NOT NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Archive_Busy] [tinyint] NOT NULL,
	[Transfer_Folder_Path] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Capture_Subfolder] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Tasks] PRIMARY KEY CLUSTERED 
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Tasks] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Tasks_Dataset_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Tasks_Dataset_ID] ON [dbo].[T_Tasks]
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Tasks_Script_Dataset] ******/
CREATE NONCLUSTERED INDEX [IX_T_Tasks_Script_Dataset] ON [dbo].[T_Tasks]
(
	[Script] ASC,
	[Dataset] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Tasks_Script_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Tasks_Script_DatasetID] ON [dbo].[T_Tasks]
(
	[Script] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Tasks_Script_State_include_Dataset_ID_Results_Finish] ******/
CREATE NONCLUSTERED INDEX [IX_T_Tasks_Script_State_include_Dataset_ID_Results_Finish] ON [dbo].[T_Tasks]
(
	[Script] ASC,
	[State] ASC
)
INCLUDE([Dataset_ID],[Results_Folder_Name],[Finish]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Tasks_Script_State_include_JobDatasetDatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Tasks_Script_State_include_JobDatasetDatasetID] ON [dbo].[T_Tasks]
(
	[Script] ASC,
	[State] ASC
)
INCLUDE([Job],[Dataset],[Dataset_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Tasks_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Tasks_State] ON [dbo].[T_Tasks]
(
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Tasks_State_include_Job_Priority_ArchiveBusy] ******/
CREATE NONCLUSTERED INDEX [IX_T_Tasks_State_include_Job_Priority_ArchiveBusy] ON [dbo].[T_Tasks]
(
	[State] ASC
)
INCLUDE([Archive_Busy],[Job],[Priority]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Tasks] ADD  CONSTRAINT [DF_T_Tasks_Priority]  DEFAULT ((4)) FOR [Priority]
GO
ALTER TABLE [dbo].[T_Tasks] ADD  CONSTRAINT [DF_T_Tasks_State]  DEFAULT ((0)) FOR [State]
GO
ALTER TABLE [dbo].[T_Tasks] ADD  CONSTRAINT [DF_T_Tasks_Imported]  DEFAULT (getdate()) FOR [Imported]
GO
ALTER TABLE [dbo].[T_Tasks] ADD  CONSTRAINT [DF_T_Tasks_Archive_Busy]  DEFAULT ((0)) FOR [Archive_Busy]
GO
ALTER TABLE [dbo].[T_Tasks]  WITH CHECK ADD  CONSTRAINT [FK_T_Tasks_T_Scripts] FOREIGN KEY([Script])
REFERENCES [dbo].[T_Scripts] ([Script])
GO
ALTER TABLE [dbo].[T_Tasks] CHECK CONSTRAINT [FK_T_Tasks_T_Scripts]
GO
ALTER TABLE [dbo].[T_Tasks]  WITH CHECK ADD  CONSTRAINT [FK_T_Tasks_T_Task_State_Name] FOREIGN KEY([State])
REFERENCES [dbo].[T_Task_State_Name] ([ID])
GO
ALTER TABLE [dbo].[T_Tasks] CHECK CONSTRAINT [FK_T_Tasks_T_Task_State_Name]
GO
/****** Object:  Trigger [dbo].[trig_d_T_Tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER trig_d_T_Tasks ON dbo.T_Tasks
FOR DELETE
/****************************************************
**
**	Desc:
**		Add new rows to T_Task_Events for deleted tasks
**
**	Auth:	grk
**	Date:	09/15/2009 mem - Initial version
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Task_Events
		(Job, Target_State, Prev_Target_State)
	SELECT deleted.Job, 0 as New_State, deleted.State as Old_State
	FROM deleted
	ORDER BY deleted.Job

GO
ALTER TABLE [dbo].[T_Tasks] ENABLE TRIGGER [trig_d_T_Tasks]
GO
/****** Object:  Trigger [dbo].[trig_i_T_Tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[trig_i_T_Tasks] ON [dbo].[T_Tasks]
FOR INSERT
/****************************************************
**
**	Desc:
**		Add new rows to T_Task_Events for inserted tasks
**
**	Auth:	grk
**	Date:	09/15/2009 mem - Initial version
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Task_Events
		(Job, Target_State, Prev_Target_State)
	SELECT  inserted.Job, inserted.State as New_State, 0 as Old_State
	FROM inserted
	WHERE inserted.State <> 0
	ORDER BY inserted.Job

GO
ALTER TABLE [dbo].[T_Tasks] ENABLE TRIGGER [trig_i_T_Tasks]
GO
/****** Object:  Trigger [dbo].[trig_u_T_Tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_u_T_Tasks] ON [dbo].[T_Tasks]
FOR UPDATE
/****************************************************
**
**	Desc:
**		Add new rows to T_Task_Events for updated tasks
**
**	Auth:	grk
**	Date:	09/15/2009 mem - Initial version
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(State)
	Begin
		INSERT INTO T_Task_Events
			(Job, Target_State, Prev_Target_State)
		SELECT     inserted.Job, inserted.State as New_State, deleted.State as Old_State
		FROM deleted INNER JOIN inserted ON deleted.Job = inserted.Job
		ORDER BY inserted.Job
	End

GO
ALTER TABLE [dbo].[T_Tasks] ENABLE TRIGGER [trig_u_T_Tasks]
GO
