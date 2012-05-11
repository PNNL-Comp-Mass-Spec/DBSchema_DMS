/****** Object:  Table [dbo].[T_Job_Steps_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Job_Steps_History](
	[Job] [int] NOT NULL,
	[Step_Number] [int] NOT NULL,
	[Priority] [int] NULL,
	[Step_Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Shared_Result_Version] [smallint] NULL,
	[Signature] [int] NULL,
	[State] [tinyint] NULL,
	[Input_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Output_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Processor] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Machine] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Completion_Code] [int] NULL,
	[Completion_Message] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Evaluation_Code] [int] NULL,
	[Evaluation_Message] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Saved] [datetime] NULL,
	[Tool_Version_ID] [int] NULL
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Job_Steps_History_Job_Step] ******/
CREATE CLUSTERED INDEX [IX_T_Job_Steps_History_Job_Step] ON [dbo].[T_Job_Steps_History] 
(
	[Job] ASC,
	[Step_Number] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Job_Steps_History_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_History_State] ON [dbo].[T_Job_Steps_History] 
(
	[State] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Job_Steps_History_State_OutputFolderName] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Steps_History_State_OutputFolderName] ON [dbo].[T_Job_Steps_History] 
(
	[State] ASC,
	[Output_Folder_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
