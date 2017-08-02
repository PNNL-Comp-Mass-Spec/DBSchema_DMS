/****** Object:  Table [dbo].[T_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Job_Steps](
	[Job] [int] NOT NULL,
	[Step_Number] [int] NOT NULL,
	[Step_Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CPU_Load] [tinyint] NULL,
	[Actual_CPU_Load] [tinyint] NULL,
	[Dependencies] [tinyint] NOT NULL,
	[Shared_Result_Version] [smallint] NULL,
	[Signature] [int] NULL,
	[State] [tinyint] NOT NULL,
	[Input_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Output_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Processor] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Completion_Code] [int] NULL,
	[Completion_Message] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Evaluation_Code] [int] NULL,
	[Evaluation_Message] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Job_Plus_Step]  AS ((CONVERT([varchar](12),[Job],(0))+'.')+CONVERT([varchar](6),[Step_Number],(0))) PERSISTED,
	[Tool_Version_ID] [int] NULL,
	[Memory_Usage_MB] [int] NULL,
	[Next_Try] [datetime] NOT NULL,
	[Retry_Count] [smallint] NOT NULL,
	[Remote_Info_ID] [int] NOT NULL,
	[Remote_Timestamp] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Remote_Start] [smalldatetime] NULL,
	[Remote_Finish] [smalldatetime] NULL,
	[Remote_Progress] [real] NULL,
 CONSTRAINT [PK_T_Job_Steps] PRIMARY KEY CLUSTERED 
(
	[Job] ASC,
	[Step_Number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Job_Steps] TO [DDL_Viewer] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Job_Steps] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Job_Steps] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Job_Steps] TO [Limited_Table_Write] AS [dbo]
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
CREATE UNIQUE NONCLUSTERED INDEX [IX_Job_Plus_Step] ON [dbo].[T_Job_Steps]
(
	[Job_Plus_Step] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Job_Steps] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps] ON [dbo].[T_Job_Steps]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Job_Steps_Dependencies_State_include_Job_Step] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_Dependencies_State_include_Job_Step] ON [dbo].[T_Job_Steps]
(
	[Dependencies] ASC,
	[State] ASC
)
INCLUDE ( 	[Job],
	[Step_Number]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Job_Steps_OutputFolderName_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_OutputFolderName_State] ON [dbo].[T_Job_Steps]
(
	[Output_Folder_Name] ASC,
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Job_Steps_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_State] ON [dbo].[T_Job_Steps]
(
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Job_Steps_State_include_Job_Step_CompletionCode] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_State_include_Job_Step_CompletionCode] ON [dbo].[T_Job_Steps]
(
	[State] ASC
)
INCLUDE ( 	[Job],
	[Step_Number],
	[Completion_Code]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Job_Steps_State_Job_Step_Dependencies_SharedResultVer_Signature_StepTool] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_State_Job_Step_Dependencies_SharedResultVer_Signature_StepTool] ON [dbo].[T_Job_Steps]
(
	[State] ASC,
	[Job] ASC,
	[Step_Number] ASC,
	[Dependencies] ASC,
	[Shared_Result_Version] ASC,
	[Signature] ASC,
	[Step_Tool] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Job_Steps_Step_Tool_State_Next_Try_include_Job_StepNumber_MemoryUsage_RemoteInfo] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_Step_Tool_State_Next_Try_include_Job_StepNumber_MemoryUsage_RemoteInfo] ON [dbo].[T_Job_Steps]
(
	[Step_Tool] ASC,
	[State] ASC,
	[Next_Try] ASC
)
INCLUDE ( 	[Job],
	[Step_Number],
	[Memory_Usage_MB],
	[Remote_Info_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Job_Steps_StepTool_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_StepTool_State] ON [dbo].[T_Job_Steps]
(
	[Step_Tool] ASC,
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_Dependencies]  DEFAULT ((0)) FOR [Dependencies]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_Evaluated]  DEFAULT ((1)) FOR [State]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_Triggered]  DEFAULT ((0)) FOR [Completion_Code]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_Tool_Version_ID]  DEFAULT ((1)) FOR [Tool_Version_ID]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_NextTry]  DEFAULT (getdate()) FOR [Next_Try]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_RetryCount]  DEFAULT ((0)) FOR [Retry_Count]
GO
ALTER TABLE [dbo].[T_Job_Steps] ADD  CONSTRAINT [DF_T_Job_Steps_Remote_Info_ID]  DEFAULT ((1)) FOR [Remote_Info_ID]
GO
ALTER TABLE [dbo].[T_Job_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Job_Steps_T_Jobs] FOREIGN KEY([Job])
REFERENCES [dbo].[T_Jobs] ([Job])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Job_Steps] CHECK CONSTRAINT [FK_T_Job_Steps_T_Jobs]
GO
ALTER TABLE [dbo].[T_Job_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Job_Steps_T_Remote_Info] FOREIGN KEY([Remote_Info_ID])
REFERENCES [dbo].[T_Remote_Info] ([Remote_Info_ID])
GO
ALTER TABLE [dbo].[T_Job_Steps] CHECK CONSTRAINT [FK_T_Job_Steps_T_Remote_Info]
GO
ALTER TABLE [dbo].[T_Job_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Job_Steps_T_Signatures] FOREIGN KEY([Signature])
REFERENCES [dbo].[T_Signatures] ([Reference])
GO
ALTER TABLE [dbo].[T_Job_Steps] CHECK CONSTRAINT [FK_T_Job_Steps_T_Signatures]
GO
ALTER TABLE [dbo].[T_Job_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Job_Steps_T_Step_State] FOREIGN KEY([State])
REFERENCES [dbo].[T_Job_Step_State_Name] ([ID])
GO
ALTER TABLE [dbo].[T_Job_Steps] CHECK CONSTRAINT [FK_T_Job_Steps_T_Step_State]
GO
ALTER TABLE [dbo].[T_Job_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Job_Steps_T_Step_Tool_Versions] FOREIGN KEY([Tool_Version_ID])
REFERENCES [dbo].[T_Step_Tool_Versions] ([Tool_Version_ID])
GO
ALTER TABLE [dbo].[T_Job_Steps] CHECK CONSTRAINT [FK_T_Job_Steps_T_Step_Tool_Versions]
GO
ALTER TABLE [dbo].[T_Job_Steps]  WITH CHECK ADD  CONSTRAINT [FK_T_Job_Steps_T_Step_Tools] FOREIGN KEY([Step_Tool])
REFERENCES [dbo].[T_Step_Tools] ([Name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Job_Steps] CHECK CONSTRAINT [FK_T_Job_Steps_T_Step_Tools]
GO
/****** Object:  Trigger [dbo].[trig_d_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_d_Job_Steps] ON [dbo].[T_Job_Steps] 
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
CREATE TRIGGER [dbo].[trig_u_Job_Steps] ON [dbo].[T_Job_Steps] 
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
/****** Object:  Trigger [dbo].[trig_ud_T_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_ud_T_Job_Steps]
ON [dbo].[T_Job_Steps]
FOR UPDATE, DELETE AS
/****************************************************
**
**	Desc: 
**		Prevents updating or deleting all rows in the table
**
**	Auth:	mem
**	Date:	02/08/2011
**			07/08/2012 mem - Added row counts to the error message
**			09/11/2015 mem - Added support for the table being empty
**
*****************************************************/
BEGIN

     DECLARE @Count int
    SET @Count = @@ROWCOUNT;

	DECLARE @ExistingRows int=0
	SELECT @ExistingRows = i.rowcnt
    FROM dbo.sysobjects o INNER JOIN dbo.sysindexes i ON o.id = i.id
    WHERE o.name = 'T_Job_Steps' AND o.type = 'u' AND i.indid < 2
	
    IF @Count > 0 AND @ExistingRows > 1 AND @Count >= @ExistingRows
    BEGIN
    
		Declare @msg varchar(512)      
		Set @msg = 'Cannot update or delete all ' + Convert(varchar(12), @Count) + ' rows ' + 
		           '(@ExistingRows=' + CONVERT(varchar(12), @ExistingRows) + '). Use a WHERE clause (see trigger trig_ud_T_Job_Steps)'               
		
		RAISERROR(@msg,16,1)
		ROLLBACK TRANSACTION
		RETURN;
			
    END

END

GO
