/****** Object:  Table [dbo].[T_Processor_Status] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Processor_Status](
	[Processor_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Mgr_Status] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Status_Date] [datetime] NOT NULL,
	[Last_Start_Time] [datetime] NULL,
	[CPU_Utilization] [real] NULL,
	[Free_Memory_MB] [real] NULL,
	[Process_ID] [int] NULL,
	[ProgRunner_ProcessID] [int] NULL,
	[ProgRunner_CoreUsage] [real] NULL,
	[Most_Recent_Error_Message] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Step_Tool] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Task_Status] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Duration_Hours] [real] NULL,
	[Progress] [real] NULL,
	[Current_Operation] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Task_Detail_Status] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Job] [int] NULL,
	[Job_Step] [int] NULL,
	[Dataset] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Most_Recent_Log_Message] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Most_Recent_Job_Info] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Spectrum_Count] [int] NULL,
	[Monitor_Processor] [tinyint] NOT NULL,
	[Remote_Manager] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Remote_Processor] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Processor_Status] PRIMARY KEY CLUSTERED 
(
	[Processor_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Processor_Status] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Processor_Status_Monitor_Processor] ******/
CREATE NONCLUSTERED INDEX [IX_T_Processor_Status_Monitor_Processor] ON [dbo].[T_Processor_Status]
(
	[Monitor_Processor] ASC
)
INCLUDE ( 	[Processor_Name]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Processor_Status] ADD  CONSTRAINT [DF_T_Processor_Status_Status_Date]  DEFAULT (getdate()) FOR [Status_Date]
GO
ALTER TABLE [dbo].[T_Processor_Status] ADD  CONSTRAINT [DF_T_Processor_Status_Monitor_Processor]  DEFAULT ((1)) FOR [Monitor_Processor]
GO
ALTER TABLE [dbo].[T_Processor_Status] ADD  CONSTRAINT [DF_T_Processor_Status_Remote_Manager]  DEFAULT ('') FOR [Remote_Manager]
GO
ALTER TABLE [dbo].[T_Processor_Status] ADD  CONSTRAINT [DF_T_Processor_Status_Remote_Processor]  DEFAULT ((0)) FOR [Remote_Processor]
GO
