/****** Object:  Table [dbo].[T_Task_Step_Processing_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Task_Step_Processing_Log](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Event_ID] [int] NOT NULL,
	[Job] [int] NOT NULL,
	[Step] [int] NOT NULL,
	[Processor] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Entered] [datetime] NOT NULL,
	[Entered_By] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Task_Step_Processing_Log] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Task_Step_Processing_Log] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Task_Step_Processing_Log_Event_ID] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Task_Step_Processing_Log_Event_ID] ON [dbo].[T_Task_Step_Processing_Log]
(
	[Event_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Task_Step_Processing_Log_JobStep] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Step_Processing_Log_JobStep] ON [dbo].[T_Task_Step_Processing_Log]
(
	[Job] ASC,
	[Step] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Task_Step_Processing_Log_Processor] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Step_Processing_Log_Processor] ON [dbo].[T_Task_Step_Processing_Log]
(
	[Processor] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Task_Step_Processing_Log] ADD  CONSTRAINT [DF_T_Task_Step_Processing_Log_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Task_Step_Processing_Log] ADD  CONSTRAINT [DF_T_Task_Step_Processing_Log_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
