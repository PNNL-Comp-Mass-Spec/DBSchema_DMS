/****** Object:  Table [dbo].[T_Job_Step_Dependencies_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Job_Step_Dependencies_History](
	[Job] [int] NOT NULL,
	[Step_Number] [int] NOT NULL,
	[Target_Step_Number] [int] NOT NULL,
	[Condition_Test] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Test_Value] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Evaluated] [tinyint] NOT NULL,
	[Triggered] [tinyint] NOT NULL,
	[Enable_Only] [tinyint] NOT NULL,
	[Saved] [datetime] NOT NULL,
	[Initial_Save] [smalldatetime] NULL,
 CONSTRAINT [PK_T_Job_Step_Dependencies_History] PRIMARY KEY NONCLUSTERED 
(
	[Job] ASC,
	[Step_Number] ASC,
	[Target_Step_Number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Job_Step_Dependencies_History] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Job_Step_Dependencies_History] ******/
CREATE CLUSTERED INDEX [IX_T_Job_Step_Dependencies_History] ON [dbo].[T_Job_Step_Dependencies_History]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Job_Step_Dependencies_History_JobID_Step_Evaluated_Triggered] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Step_Dependencies_History_JobID_Step_Evaluated_Triggered] ON [dbo].[T_Job_Step_Dependencies_History]
(
	[Job] ASC,
	[Step_Number] ASC
)
INCLUDE ( 	[Evaluated],
	[Triggered]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Job_Step_Dependencies_History] ADD  CONSTRAINT [DF_T_Job_Step_Dependencies_History_Evaluated]  DEFAULT ((0)) FOR [Evaluated]
GO
ALTER TABLE [dbo].[T_Job_Step_Dependencies_History] ADD  CONSTRAINT [DF_T_Job_Step_Dependencies_History_Triggered]  DEFAULT ((0)) FOR [Triggered]
GO
ALTER TABLE [dbo].[T_Job_Step_Dependencies_History] ADD  CONSTRAINT [DF_T_Job_Step_Dependencies_History_Enable_Only]  DEFAULT ((0)) FOR [Enable_Only]
GO
ALTER TABLE [dbo].[T_Job_Step_Dependencies_History] ADD  CONSTRAINT [DF_T_Job_Step_Dependencies_History_Saved]  DEFAULT (getdate()) FOR [Saved]
GO
ALTER TABLE [dbo].[T_Job_Step_Dependencies_History] ADD  CONSTRAINT [DF_T_Job_Step_Dependencies_History_Initial_Save]  DEFAULT (getdate()) FOR [Initial_Save]
GO
