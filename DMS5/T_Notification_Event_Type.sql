/****** Object:  Table [dbo].[T_Notification_Event_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Notification_Event_Type](
	[ID] [int] NOT NULL,
	[Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Target_Entity_Type] [int] NOT NULL,
	[Link_Template] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Visible] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Notification_Event_Type] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Notification_Event_Type] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Notification_Event_Type] ADD  CONSTRAINT [DF_T_Notification_Event_Type_Visible]  DEFAULT ('Y') FOR [Visible]
GO
ALTER TABLE [dbo].[T_Notification_Event_Type]  WITH CHECK ADD  CONSTRAINT [FK_T_Notification_Event_Type_T_Notification_Entity_Type] FOREIGN KEY([Target_Entity_Type])
REFERENCES [dbo].[T_Notification_Entity_Type] ([ID])
GO
ALTER TABLE [dbo].[T_Notification_Event_Type] CHECK CONSTRAINT [FK_T_Notification_Event_Type_T_Notification_Entity_Type]
GO
