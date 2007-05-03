/****** Object:  Table [dbo].[T_Requested_Run_History_EUS_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run_History_EUS_Users](
	[EUS_Person_ID] [int] NOT NULL,
	[Request_ID] [int] NOT NULL,
	[Site_Status] [tinyint] NOT NULL CONSTRAINT [DF_T_Requested_Run_History_EUS_Users_Site_Status]  DEFAULT (1),
 CONSTRAINT [PK_T_Requested_Run_History_EUS_Users] PRIMARY KEY CLUSTERED 
(
	[EUS_Person_ID] ASC,
	[Request_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_Requested_Run_History_EUS_Users] TO [Limited_Table_Write]
GO
GRANT INSERT ON [dbo].[T_Requested_Run_History_EUS_Users] TO [Limited_Table_Write]
GO
GRANT DELETE ON [dbo].[T_Requested_Run_History_EUS_Users] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_History_EUS_Users] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run_History_EUS_Users] ([EUS_Person_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_History_EUS_Users] ([EUS_Person_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run_History_EUS_Users] ([Request_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_History_EUS_Users] ([Request_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run_History_EUS_Users] ([Site_Status]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_History_EUS_Users] ([Site_Status]) TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Requested_Run_History_EUS_Users]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Requested_Run_History_EUS_Users_T_EUS_Site_Status] FOREIGN KEY([Site_Status])
REFERENCES [T_EUS_Site_Status] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_History_EUS_Users] CHECK CONSTRAINT [FK_T_Requested_Run_History_EUS_Users_T_EUS_Site_Status]
GO
ALTER TABLE [dbo].[T_Requested_Run_History_EUS_Users]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Requested_Run_History_EUS_Users_T_EUS_Users] FOREIGN KEY([EUS_Person_ID])
REFERENCES [T_EUS_Users] ([PERSON_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_History_EUS_Users] CHECK CONSTRAINT [FK_T_Requested_Run_History_EUS_Users_T_EUS_Users]
GO
ALTER TABLE [dbo].[T_Requested_Run_History_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_History_EUS_Users_T_Requested_Run_History] FOREIGN KEY([Request_ID])
REFERENCES [T_Requested_Run_History] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
