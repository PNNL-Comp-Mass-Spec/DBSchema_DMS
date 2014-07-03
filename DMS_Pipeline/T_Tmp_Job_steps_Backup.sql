/****** Object:  Table [dbo].[T_Tmp_Job_steps_Backup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Tmp_Job_steps_Backup](
	[Job] [int] NOT NULL,
	[Step_Number] [int] NOT NULL,
	[Step_Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CPU_Load] [smallint] NULL,
	[Dependencies] [tinyint] NOT NULL,
	[Shared_Result_Version] [smallint] NULL,
	[Signature] [int] NULL,
	[State] [tinyint] NOT NULL,
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
	[Job_Plus_Step] [varchar](19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Tool_Version_ID] [int] NULL,
	[Memory_Usage_MB] [int] NULL
) ON [PRIMARY]

GO
