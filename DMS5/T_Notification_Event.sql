/****** Object:  Table [dbo].[T_Notification_Event] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Notification_Event](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Event_Type] [int] NOT NULL,
	[Target_ID] [int] NOT NULL,
	[Entered] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Notification_Event] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Notification_Event] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Notification_Event_Event_Type_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Notification_Event_Event_Type_ID] ON [dbo].[T_Notification_Event]
(
	[Event_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Notification_Event_Target_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Notification_Event_Target_ID] ON [dbo].[T_Notification_Event]
(
	[Target_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Notification_Event] ADD  CONSTRAINT [DF_T_Notification_Event_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Notification_Event]  WITH CHECK ADD  CONSTRAINT [FK_T_Notification_Event_T_Notification_Event_Type] FOREIGN KEY([Event_Type])
REFERENCES [dbo].[T_Notification_Event_Type] ([ID])
GO
ALTER TABLE [dbo].[T_Notification_Event] CHECK CONSTRAINT [FK_T_Notification_Event_T_Notification_Event_Type]
GO
