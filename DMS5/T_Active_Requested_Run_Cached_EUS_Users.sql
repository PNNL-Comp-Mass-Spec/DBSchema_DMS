/****** Object:  Table [dbo].[T_Active_Requested_Run_Cached_EUS_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Active_Requested_Run_Cached_EUS_Users](
	[Request_ID] [int] NOT NULL,
	[User_List] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Active_Requested_Run_Cached_EUS_Users] PRIMARY KEY CLUSTERED 
(
	[Request_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Active_Requested_Run_Cached_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_Active_Requested_Run_Cached_EUS_Users_T_Requested_Run] FOREIGN KEY([Request_ID])
REFERENCES [dbo].[T_Requested_Run] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Active_Requested_Run_Cached_EUS_Users] CHECK CONSTRAINT [FK_T_Active_Requested_Run_Cached_EUS_Users_T_Requested_Run]
GO
