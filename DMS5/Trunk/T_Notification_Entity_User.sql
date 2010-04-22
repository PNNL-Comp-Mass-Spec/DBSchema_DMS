/****** Object:  Table [dbo].[T_Notification_Entity_User] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Notification_Entity_User](
	[User_ID] [int] NOT NULL,
	[Entity_Type_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Notification_Entity_User] PRIMARY KEY CLUSTERED 
(
	[User_ID] ASC,
	[Entity_Type_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Notification_Entity_User]  WITH CHECK ADD  CONSTRAINT [FK_T_Notification_Entity_User_T_Notification_Entity_Type] FOREIGN KEY([Entity_Type_ID])
REFERENCES [T_Notification_Entity_Type] ([ID])
GO
ALTER TABLE [dbo].[T_Notification_Entity_User] CHECK CONSTRAINT [FK_T_Notification_Entity_User_T_Notification_Entity_Type]
GO
ALTER TABLE [dbo].[T_Notification_Entity_User]  WITH CHECK ADD  CONSTRAINT [FK_T_Notification_Entity_User_T_Users] FOREIGN KEY([User_ID])
REFERENCES [T_Users] ([ID])
GO
ALTER TABLE [dbo].[T_Notification_Entity_User] CHECK CONSTRAINT [FK_T_Notification_Entity_User_T_Users]
GO
