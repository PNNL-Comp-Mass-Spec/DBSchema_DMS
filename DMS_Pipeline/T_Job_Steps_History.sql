/****** Object:  Table [dbo].[T_Job_Steps_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Job_Steps_History](
	[Job] [int] NOT NULL,
	[Step] [int] NOT NULL,
	[Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Shared_Result_Version] [smallint] NULL,
	[Signature] [int] NULL,
	[State] [tinyint] NULL,
	[Input_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Output_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Processor] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Completion_Code] [int] NULL,
	[Completion_Message] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Evaluation_Code] [int] NULL,
	[Evaluation_Message] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Saved] [datetime] NOT NULL,
	[JobStepSavedCombo]  AS ((((CONVERT([varchar](12),[Job],(0))+'.')+CONVERT([varchar](6),[Step],(0)))+'.')+CONVERT([varchar](32),[Saved],(126))) PERSISTED,
	[Most_Recent_Entry] [tinyint] NOT NULL,
	[Tool_Version_ID] [int] NULL,
	[Memory_Usage_MB] [int] NULL,
	[Remote_Info_ID] [int] NULL,
	[Remote_Start] [smalldatetime] NULL,
	[Remote_Finish] [smalldatetime] NULL,
 CONSTRAINT [PK_T_Job_Steps_History] PRIMARY KEY NONCLUSTERED 
(
	[Job] ASC,
	[Step] ASC,
	[Saved] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Job_Steps_History] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Job_Steps_History_Job_Step] ******/
CREATE CLUSTERED INDEX [IX_T_Job_Steps_History_Job_Step] ON [dbo].[T_Job_Steps_History]
(
	[Job] ASC,
	[Step] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Job_Steps_History_Finish] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_History_Finish] ON [dbo].[T_Job_Steps_History]
(
	[Finish] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IX_T_Job_Steps_History_JobStepSavedCombo] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Job_Steps_History_JobStepSavedCombo] ON [dbo].[T_Job_Steps_History]
(
	[JobStepSavedCombo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Job_Steps_History_MostRecentEntry] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_History_MostRecentEntry] ON [dbo].[T_Job_Steps_History]
(
	[Most_Recent_Entry] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Job_Steps_History_State_OutputFolderName] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_History_State_OutputFolderName] ON [dbo].[T_Job_Steps_History]
(
	[State] ASC,
	[Output_Folder_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Job_Steps_History_Step_Tool_Start] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_History_Step_Tool_Start] ON [dbo].[T_Job_Steps_History]
(
	[Tool] ASC,
	[Start] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [T_Job_Steps_History_ToolVersionID] ******/
CREATE NONCLUSTERED INDEX [T_Job_Steps_History_ToolVersionID] ON [dbo].[T_Job_Steps_History]
(
	[Tool_Version_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Job_Steps_History] ADD  CONSTRAINT [DF_T_Job_Steps_History_Saved]  DEFAULT (getdate()) FOR [Saved]
GO
ALTER TABLE [dbo].[T_Job_Steps_History] ADD  CONSTRAINT [DF_T_Job_Steps_History_Most_Recent_Entry]  DEFAULT ((0)) FOR [Most_Recent_Entry]
GO
/****** Object:  Trigger [dbo].[trig_d_T_Job_Steps_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_d_T_Job_Steps_History] ON [dbo].[T_Job_Steps_History]
FOR DELETE
/****************************************************
**
**	Desc: 
**		Updates column MostRecentEntry for the affected jobs
**
**	Auth:	mem
**	Date:	01/25/2011
**          03/09/2023 mem - Use new column names
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	UPDATE T_Job_Steps_History
	SET Most_Recent_Entry = CASE WHEN SaveRank = 1 THEN 1 ELSE 0 END
	FROM ( SELECT Job,
	              Step,
	              Saved,
	              Row_Number() OVER ( PARTITION BY Job, Step ORDER BY Saved DESC ) AS SaveRank
	       FROM T_Job_Steps_History
	       WHERE Job IN (SELECT Job FROM deleted)
	     ) LookupQ
	     INNER JOIN T_Job_Steps_History Target
	       ON LookupQ.Job = Target.Job AND
	          LookupQ.Step = Target.Step AND
	          LookupQ.Saved = Target.Saved

GO
ALTER TABLE [dbo].[T_Job_Steps_History] ENABLE TRIGGER [trig_d_T_Job_Steps_History]
GO
/****** Object:  Trigger [dbo].[trig_iu_T_Job_Steps_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_iu_T_Job_Steps_History] ON [dbo].[T_Job_Steps_History]
FOR INSERT, UPDATE
/****************************************************
**
**	Desc: 
**		Updates column MostRecentEntry for the affected jobs
**
**	Auth:	mem
**	Date:	01/25/2011
**          03/09/2023 mem - Use new column names
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(Saved)
	Begin
		UPDATE T_Job_Steps_History
		SET Most_Recent_Entry = CASE WHEN SaveRank = 1 THEN 1 ELSE 0 END
		FROM ( SELECT Job,
		              Step,
		              Saved,
		              Row_Number() OVER ( PARTITION BY Job, Step ORDER BY Saved DESC ) AS SaveRank
		       FROM T_Job_Steps_History
		       WHERE Job IN (SELECT Job FROM inserted)
		     ) LookupQ
		     INNER JOIN T_Job_Steps_History Target
		       ON LookupQ.Job = Target.Job AND
		          LookupQ.Step = Target.Step AND
		          LookupQ.Saved = Target.Saved
	End

GO
ALTER TABLE [dbo].[T_Job_Steps_History] ENABLE TRIGGER [trig_iu_T_Job_Steps_History]
GO
