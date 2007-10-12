/****** Object:  Table [dbo].[T_Requested_Run_EUS_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run_EUS_Users](
	[EUS_Person_ID] [int] NULL,
	[Request_ID] [int] NULL
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write]
GO
GRANT INSERT ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write]
GO
GRANT DELETE ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run_EUS_Users] ([EUS_Person_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_EUS_Users] ([EUS_Person_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run_EUS_Users] ([Request_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_EUS_Users] ([Request_ID]) TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_EUS_Users] FOREIGN KEY([EUS_Person_ID])
REFERENCES [T_EUS_Users] ([PERSON_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users] CHECK CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_EUS_Users]
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_Requested_Run] FOREIGN KEY([Request_ID])
REFERENCES [T_Requested_Run] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users] CHECK CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_Requested_Run]
GO
