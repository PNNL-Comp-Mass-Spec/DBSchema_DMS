/****** Object:  Table [dbo].[T_Event_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Event_Log](
	[Index] [int] IDENTITY(100,1) NOT NULL,
	[Target_Type] [int] NULL,
	[Target_ID] [int] NULL,
	[Target_State] [smallint] NULL,
	[Prev_Target_State] [smallint] NULL,
	[Entered] [datetime] NULL,
	[Entered_By] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Event_Log] PRIMARY KEY CLUSTERED 
(
	[Index] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Event_Log] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Event_Log_Entered] ******/
CREATE NONCLUSTERED INDEX [IX_T_Event_Log_Entered] ON [dbo].[T_Event_Log]
(
	[Entered] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Event_Log_PrevTargetState_TargetState_TargetType] ******/
CREATE NONCLUSTERED INDEX [IX_T_Event_Log_PrevTargetState_TargetState_TargetType] ON [dbo].[T_Event_Log]
(
	[Prev_Target_State] ASC,
	[Target_State] ASC,
	[Target_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Event_Log_Target_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Event_Log_Target_ID] ON [dbo].[T_Event_Log]
(
	[Target_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Event_Log_TargetID_PrevTargetState_TargetState] ******/
CREATE NONCLUSTERED INDEX [IX_T_Event_Log_TargetID_PrevTargetState_TargetState] ON [dbo].[T_Event_Log]
(
	[Target_ID] ASC,
	[Prev_Target_State] ASC,
	[Target_State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Event_Log_TargetType_TargetState_Entered] ******/
CREATE NONCLUSTERED INDEX [IX_T_Event_Log_TargetType_TargetState_Entered] ON [dbo].[T_Event_Log]
(
	[Target_Type] ASC,
	[Target_State] ASC,
	[Entered] ASC
)
INCLUDE([Index]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Event_Log] ADD  CONSTRAINT [DF_T_Event_Log_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Event_Log] ADD  CONSTRAINT [DF_T_Event_Log_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
ALTER TABLE [dbo].[T_Event_Log]  WITH CHECK ADD  CONSTRAINT [FK_T_Event_Log_T_Event_Target1] FOREIGN KEY([Target_Type])
REFERENCES [dbo].[T_Event_Target] ([ID])
GO
ALTER TABLE [dbo].[T_Event_Log] CHECK CONSTRAINT [FK_T_Event_Log_T_Event_Target1]
GO
