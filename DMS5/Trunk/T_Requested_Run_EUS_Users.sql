/****** Object:  Table [dbo].[T_Requested_Run_EUS_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run_EUS_Users](
	[EUS_Person_ID] [int] NOT NULL,
	[Request_ID] [int] NOT NULL,
	[Site_Status] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Requested_Run_EUS_Users] PRIMARY KEY CLUSTERED 
(
	[EUS_Person_ID] ASC,
	[Request_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
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
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_EUS_Users] FOREIGN KEY([EUS_Person_ID])
REFERENCES [T_EUS_Users] ([PERSON_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users] CHECK CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_EUS_Users]
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_Requested_Run] FOREIGN KEY([Request_ID])
REFERENCES [T_Requested_Run] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users] CHECK CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_Requested_Run]
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users] ADD  CONSTRAINT [DF_T_Requested_Run_EUS_Users_Site_Status]  DEFAULT ((1)) FOR [Site_Status]
GO
