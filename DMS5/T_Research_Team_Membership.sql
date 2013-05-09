/****** Object:  Table [dbo].[T_Research_Team_Membership] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Research_Team_Membership](
	[Team_ID] [int] NOT NULL,
	[Role_ID] [int] NOT NULL,
	[User_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Research_Team_Membership] PRIMARY KEY CLUSTERED 
(
	[Team_ID] ASC,
	[Role_ID] ASC,
	[User_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Research_Team_Membership]  WITH CHECK ADD  CONSTRAINT [FK_T_Research_Team_Membership_T_Research_Team] FOREIGN KEY([Team_ID])
REFERENCES [T_Research_Team] ([ID])
GO
ALTER TABLE [dbo].[T_Research_Team_Membership] CHECK CONSTRAINT [FK_T_Research_Team_Membership_T_Research_Team]
GO
ALTER TABLE [dbo].[T_Research_Team_Membership]  WITH CHECK ADD  CONSTRAINT [FK_T_Research_Team_Membership_T_Research_Team_Roles] FOREIGN KEY([Role_ID])
REFERENCES [T_Research_Team_Roles] ([ID])
GO
ALTER TABLE [dbo].[T_Research_Team_Membership] CHECK CONSTRAINT [FK_T_Research_Team_Membership_T_Research_Team_Roles]
GO
ALTER TABLE [dbo].[T_Research_Team_Membership]  WITH CHECK ADD  CONSTRAINT [FK_T_Research_Team_Membership_T_Users] FOREIGN KEY([User_ID])
REFERENCES [T_Users] ([ID])
GO
ALTER TABLE [dbo].[T_Research_Team_Membership] CHECK CONSTRAINT [FK_T_Research_Team_Membership_T_Users]
GO
