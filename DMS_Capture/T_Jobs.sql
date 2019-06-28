/****** Object:  Table [dbo].[T_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Jobs](
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
 CONSTRAINT [PK_T_Jobs] PRIMARY KEY CLUSTERED 
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Jobs] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Jobs_Dataset_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_Dataset_ID] ON [dbo].[T_Jobs]
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Jobs_Script_Dataset] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_Script_Dataset] ON [dbo].[T_Jobs]
(
	[Script] ASC,
	[Dataset] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Jobs_Script_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_Script_DatasetID] ON [dbo].[T_Jobs]
(
	[Script] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Jobs_Script_State_include_DatasetID_ResultsFolder_Finish] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_Script_State_include_DatasetID_ResultsFolder_Finish] ON [dbo].[T_Jobs]
(
	[Script] ASC,
	[State] ASC
)
INCLUDE ( 	[Dataset_ID],
	[Results_Folder_Name],
	[Finish]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Jobs_Script_State_include_JobDatasetDatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_Script_State_include_JobDatasetDatasetID] ON [dbo].[T_Jobs]
(
	[Script] ASC,
	[State] ASC
)
INCLUDE ( 	[Job],
	[Dataset],
	[Dataset_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Jobs_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_State] ON [dbo].[T_Jobs]
(
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Jobs_State_include_Job_Priority_ArchiveBusy] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_State_include_Job_Priority_ArchiveBusy] ON [dbo].[T_Jobs]
(
	[State] ASC
)
INCLUDE ( 	[Archive_Busy],
	[Job],
	[Priority]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Jobs] ADD  CONSTRAINT [DF_T_Jobs_Priority]  DEFAULT ((4)) FOR [Priority]
GO
ALTER TABLE [dbo].[T_Jobs] ADD  CONSTRAINT [DF_T_Jobs_State]  DEFAULT ((0)) FOR [State]
GO
ALTER TABLE [dbo].[T_Jobs] ADD  CONSTRAINT [DF_T_Jobs_Imported]  DEFAULT (getdate()) FOR [Imported]
GO
ALTER TABLE [dbo].[T_Jobs] ADD  CONSTRAINT [DF_T_Jobs_Archive_Busy]  DEFAULT ((0)) FOR [Archive_Busy]
GO
ALTER TABLE [dbo].[T_Jobs]  WITH CHECK ADD  CONSTRAINT [FK_T_Jobs_T_Job_State_Name] FOREIGN KEY([State])
REFERENCES [dbo].[T_Job_State_Name] ([ID])
GO
ALTER TABLE [dbo].[T_Jobs] CHECK CONSTRAINT [FK_T_Jobs_T_Job_State_Name]
GO
ALTER TABLE [dbo].[T_Jobs]  WITH CHECK ADD  CONSTRAINT [FK_T_Jobs_T_Scripts] FOREIGN KEY([Script])
REFERENCES [dbo].[T_Scripts] ([Script])
GO
ALTER TABLE [dbo].[T_Jobs] CHECK CONSTRAINT [FK_T_Jobs_T_Scripts]
GO
/****** Object:  Trigger [dbo].[trig_d_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create TRIGGER trig_d_Jobs ON dbo.T_Jobs 
FOR DELETE
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Job_Events
		(Job, Target_State, Prev_Target_State)
	SELECT     deleted.Job, 0 as New_State, deleted.State as Old_State
	FROM deleted
	ORDER BY deleted.Job

GO
ALTER TABLE [dbo].[T_Jobs] ENABLE TRIGGER [trig_d_Jobs]
GO
/****** Object:  Trigger [dbo].[trig_i_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[trig_i_Jobs] ON [dbo].[T_Jobs] 
FOR INSERT
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Job_Events
		(Job, Target_State, Prev_Target_State)
	SELECT  inserted.Job, inserted.State as New_State, 0 as Old_State
	FROM inserted
	WHERE inserted.State <> 0
	ORDER BY inserted.Job


GO
ALTER TABLE [dbo].[T_Jobs] ENABLE TRIGGER [trig_i_Jobs]
GO
/****** Object:  Trigger [dbo].[trig_u_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_u_Jobs] ON [dbo].[T_Jobs] 
FOR UPDATE
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(State)
	Begin
		INSERT INTO T_Job_Events
			(Job, Target_State, Prev_Target_State)
		SELECT     inserted.Job, inserted.State as New_State, deleted.State as Old_State
		FROM deleted INNER JOIN inserted ON deleted.Job = inserted.Job
		ORDER BY inserted.Job
	End

GO
ALTER TABLE [dbo].[T_Jobs] ENABLE TRIGGER [trig_u_Jobs]
GO
