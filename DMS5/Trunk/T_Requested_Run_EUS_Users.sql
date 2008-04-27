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
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write]
GO
GRANT INSERT ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_EUS_Users] TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_EUS_Users] FOREIGN KEY([EUS_Person_ID])
REFERENCES [T_EUS_Users] ([PERSON_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_EUS_Users_T_Requested_Run] FOREIGN KEY([Request_ID])
REFERENCES [T_Requested_Run] ([ID])
GO
