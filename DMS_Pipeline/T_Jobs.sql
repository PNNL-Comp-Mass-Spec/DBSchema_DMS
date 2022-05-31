/****** Object:  Table [dbo].[T_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Jobs](
	[Job] [int] NOT NULL,
	[Priority] [int] NULL,
	[Script] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[State] [int] NOT NULL,
	[Dataset] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_ID] [int] NULL,
	[Results_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Organism_DB_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Imported] [datetime] NOT NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Runtime_Minutes] [real] NULL,
	[Archive_Busy] [tinyint] NOT NULL,
	[Transfer_Folder_Path] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Storage_Server] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Special_Processing] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Owner] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DataPkgID] [int] NULL,
 CONSTRAINT [PK_T_Jobs] PRIMARY KEY CLUSTERED 
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Jobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Jobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Jobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Jobs] TO [Limited_Table_Write] AS [dbo]
GO
/****** Object:  Index [IX_T_Jobs_Dataset_ID_include_Job_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_Dataset_ID_include_Job_State] ON [dbo].[T_Jobs]
(
	[Dataset_ID] ASC
)
INCLUDE([Job],[State]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Jobs_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_State] ON [dbo].[T_Jobs]
(
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Jobs_State_include_Job_Priority_Arch_Busy_Storage_Server] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_State_include_Job_Priority_Arch_Busy_Storage_Server] ON [dbo].[T_Jobs]
(
	[State] ASC
)
INCLUDE([Job],[Priority],[Archive_Busy],[Storage_Server]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
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
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Jobs] CHECK CONSTRAINT [FK_T_Jobs_T_Scripts]
GO
/****** Object:  Trigger [dbo].[trig_d_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_d_Jobs] ON [dbo].[T_Jobs] 
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
	SELECT inserted.Job, inserted.State as New_State, 0 as Old_State
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
/****************************************************
**
**	Desc: 
**		Makes entry in T_Job_Events
**		Calls AddUpdateJobParameter for any entries in which the Data Package ID value changed

**	Return values: 0:  success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	08/11/2008 mem - Initial version
**			01/19/2012 mem - Now verifying that the State actually changed
**
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(State)
	Begin
		INSERT INTO T_Job_Events( Job,
		                          Target_State,
		                          Prev_Target_State )
		SELECT inserted.Job,
		       inserted.State AS New_State,
		       deleted.State AS Old_State
		FROM deleted
		     INNER JOIN inserted
		       ON deleted.Job = inserted.Job
		WHERE inserted.State <> deleted.State
		ORDER BY inserted.Job

	End

GO
ALTER TABLE [dbo].[T_Jobs] ENABLE TRIGGER [trig_u_Jobs]
GO
/****** Object:  Trigger [dbo].[trig_ud_T_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_ud_T_Jobs]
ON [dbo].[T_Jobs]
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
    WHERE o.name = 'T_Jobs' AND o.type = 'u' AND i.indid < 2

    IF @Count > 0 AND @ExistingRows > 1 AND @Count >= @ExistingRows
    BEGIN

		Declare @msg varchar(512)
		Set @msg = 'Cannot update or delete all ' + Convert(varchar(12), @Count) + ' rows ' + 
		           '(@ExistingRows=' + CONVERT(varchar(12), @ExistingRows) + '). Use a WHERE clause (see trigger trig_ud_T_Jobs)'
		
        RAISERROR(@msg,16,1)
        ROLLBACK TRANSACTION
        RETURN;

    END

END

GO
ALTER TABLE [dbo].[T_Jobs] ENABLE TRIGGER [trig_ud_T_Jobs]
GO
