/****** Object:  Table [dbo].[T_Task_Step_Dependencies] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Task_Step_Dependencies](
	[Job] [int] NOT NULL,
	[Step] [int] NOT NULL,
	[Target_Step] [int] NOT NULL,
	[Condition_Test] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Test_Value] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Evaluated] [tinyint] NOT NULL,
	[Triggered] [tinyint] NOT NULL,
	[Enable_Only] [tinyint] NOT NULL,
	[Step_Number]  AS ([Step]),
	[Target_Step_Number]  AS ([Target_Step]),
 CONSTRAINT [PK_T_Task_Step_Dependencies] PRIMARY KEY NONCLUSTERED 
(
	[Job] ASC,
	[Step] ASC,
	[Target_Step] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Task_Step_Dependencies] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Task_Step_Dependencies] ******/
CREATE CLUSTERED INDEX [IX_T_Task_Step_Dependencies] ON [dbo].[T_Task_Step_Dependencies]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Task_Step_Dependencies_JobID_Step_Evaluated_Triggered] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Step_Dependencies_JobID_Step_Evaluated_Triggered] ON [dbo].[T_Task_Step_Dependencies]
(
	[Job] ASC,
	[Step] ASC
)
INCLUDE([Evaluated],[Triggered]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Task_Step_Dependencies] ADD  CONSTRAINT [DF_T_Task_Step_Dependencies_Evaluated]  DEFAULT ((0)) FOR [Evaluated]
GO
ALTER TABLE [dbo].[T_Task_Step_Dependencies] ADD  CONSTRAINT [DF_T_Task_Step_Dependencies_Triggered]  DEFAULT ((0)) FOR [Triggered]
GO
ALTER TABLE [dbo].[T_Task_Step_Dependencies] ADD  CONSTRAINT [DF_T_Task_Step_Dependencies_Enable_Only]  DEFAULT ((0)) FOR [Enable_Only]
GO
ALTER TABLE [dbo].[T_Task_Step_Dependencies]  WITH CHECK ADD  CONSTRAINT [FK_T_Task_Step_Dependencies_T_Task_Steps] FOREIGN KEY([Job], [Step])
REFERENCES [dbo].[T_Task_Steps] ([Job], [Step])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Task_Step_Dependencies] CHECK CONSTRAINT [FK_T_Task_Step_Dependencies_T_Task_Steps]
GO
