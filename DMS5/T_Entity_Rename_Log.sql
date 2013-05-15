/****** Object:  Table [dbo].[T_Entity_Rename_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Entity_Rename_Log](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Target_Type] [int] NOT NULL,
	[Target_ID] [int] NOT NULL,
	[Old_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[New_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NULL,
	[Entered_By] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Entity_Rename_Log] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Entity_Rename_Log_Target_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Entity_Rename_Log_Target_ID] ON [dbo].[T_Entity_Rename_Log] 
(
	[Target_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Entity_Rename_Log_Target_Type] ******/
CREATE NONCLUSTERED INDEX [IX_T_Entity_Rename_Log_Target_Type] ON [dbo].[T_Entity_Rename_Log] 
(
	[Target_Type] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Entity_Rename_Log]  WITH CHECK ADD  CONSTRAINT [FK_T_Entity_Rename_Log_T_Event_Target] FOREIGN KEY([Target_Type])
REFERENCES [T_Event_Target] ([ID])
GO
ALTER TABLE [dbo].[T_Entity_Rename_Log] CHECK CONSTRAINT [FK_T_Entity_Rename_Log_T_Event_Target]
GO
ALTER TABLE [dbo].[T_Entity_Rename_Log] ADD  CONSTRAINT [DF_T_Entity_Rename_Log_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Entity_Rename_Log] ADD  CONSTRAINT [DF_T_Entity_Rename_Log_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
