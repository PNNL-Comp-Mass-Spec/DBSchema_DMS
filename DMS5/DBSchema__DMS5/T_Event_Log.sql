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
 CONSTRAINT [PK_T_Event_Log] PRIMARY KEY CLUSTERED 
(
	[Index] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Event_Log_Target_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Event_Log_Target_ID] ON [dbo].[T_Event_Log] 
(
	[Target_ID] ASC
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Event_Log]  WITH CHECK ADD  CONSTRAINT [FK_T_Event_Log_T_Event_Target1] FOREIGN KEY([Target_Type])
REFERENCES [T_Event_Target] ([ID])
GO
