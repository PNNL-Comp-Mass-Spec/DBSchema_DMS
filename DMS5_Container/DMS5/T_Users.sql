/****** Object:  Table [dbo].[T_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Users](
	[U_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[U_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[U_HID] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ID] [int] IDENTITY(2000,1) NOT NULL,
	[U_Status] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[U_Access_Lists] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[U_email] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[U_domain] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[U_netid] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[U_active] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[U_update] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[U_created] [datetime] NULL,
	[U_comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Users] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY],
 CONSTRAINT [IX_T_Users] UNIQUE CLUSTERED 
(
	[U_PRN] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Users] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Users] TO [Limited_Table_Write] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[T_Users] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Users] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Users] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Users]  WITH CHECK ADD  CONSTRAINT [CK_T_User_Status] CHECK  (([U_Status]='Active' OR [U_Status]='Inactive'))
GO
ALTER TABLE [dbo].[T_Users] CHECK CONSTRAINT [CK_T_User_Status]
GO
ALTER TABLE [dbo].[T_Users]  WITH CHECK ADD  CONSTRAINT [CK_T_Users_UserName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([U_Name],(1))=(0)))
GO
ALTER TABLE [dbo].[T_Users] CHECK CONSTRAINT [CK_T_Users_UserName_WhiteSpace]
GO
ALTER TABLE [dbo].[T_Users] ADD  CONSTRAINT [DF_T_Users_U_status]  DEFAULT ('Active') FOR [U_Status]
GO
ALTER TABLE [dbo].[T_Users] ADD  CONSTRAINT [DF_T_Users_U_active]  DEFAULT ('Y') FOR [U_active]
GO
ALTER TABLE [dbo].[T_Users] ADD  CONSTRAINT [DF_T_Users_U_update]  DEFAULT ('Y') FOR [U_update]
GO
ALTER TABLE [dbo].[T_Users] ADD  CONSTRAINT [DF_T_Users_U_created]  DEFAULT (getdate()) FOR [U_created]
GO
ALTER TABLE [dbo].[T_Users] ADD  CONSTRAINT [DF_T_Users_U_comment]  DEFAULT ('') FOR [U_comment]
GO
