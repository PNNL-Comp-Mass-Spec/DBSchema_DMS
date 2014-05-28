/****** Object:  Table [dbo].[T_Requested_Run_EUS_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run_EUS_Users](
	[EUS_Person_ID] [int] NOT NULL,
	[Request_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Requested_Run_EUS_Users] PRIMARY KEY CLUSTERED 
(
	[EUS_Person_ID] ASC,
	[Request_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write] AS [dbo]
GO
/****** Object:  Index [IX_T_Requested_Run_EUS_Users_Request_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_EUS_Users_Request_ID] ON [dbo].[T_Requested_Run_EUS_Users]
(
	[Request_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_EUS_Users] FOREIGN KEY([EUS_Person_ID])
REFERENCES [dbo].[T_EUS_Users] ([PERSON_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users] CHECK CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_EUS_Users]
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_Requested_Run] FOREIGN KEY([Request_ID])
REFERENCES [dbo].[T_Requested_Run] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users] CHECK CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_Requested_Run]
GO
