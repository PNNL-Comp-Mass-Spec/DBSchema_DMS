/****** Object:  Table [dbo].[T_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Users](
	[U_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[U_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[U_HID] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ID] [int] IDENTITY(2000,1) NOT NULL,
	[U_Status] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[U_email] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[U_domain] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[U_Payroll] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[U_active] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[U_update] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[U_created] [datetime] NULL,
	[U_comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Last_Affected] [datetime] NULL,
	[Name_with_PRN]  AS ((([U_Name]+' (')+[U_PRN])+')') PERSISTED NOT NULL,
	[HID_Number]  AS (substring([U_HID],(2),(20))) PERSISTED,
 CONSTRAINT [PK_T_Users] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY],
 CONSTRAINT [IX_T_Users_U_PRN] UNIQUE CLUSTERED 
(
	[U_PRN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Users] TO [DDL_Viewer] AS [dbo]
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
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Users_U_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Users_U_Name] ON [dbo].[T_Users]
(
	[U_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
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
ALTER TABLE [dbo].[T_Users] ADD  CONSTRAINT [DF_T_Users_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Users]  WITH CHECK ADD  CONSTRAINT [CK_T_User_Status] CHECK  (([U_Status]='Inactive' OR [U_Status]='Active'))
GO
ALTER TABLE [dbo].[T_Users] CHECK CONSTRAINT [CK_T_User_Status]
GO
ALTER TABLE [dbo].[T_Users]  WITH CHECK ADD  CONSTRAINT [CK_T_Users_Active] CHECK  (([U_Active]='N' OR [U_Active]='Y'))
GO
ALTER TABLE [dbo].[T_Users] CHECK CONSTRAINT [CK_T_Users_Active]
GO
ALTER TABLE [dbo].[T_Users]  WITH CHECK ADD  CONSTRAINT [CK_T_Users_Update] CHECK  (([U_Update]='N' OR [U_Update]='Y'))
GO
ALTER TABLE [dbo].[T_Users] CHECK CONSTRAINT [CK_T_Users_Update]
GO
ALTER TABLE [dbo].[T_Users]  WITH CHECK ADD  CONSTRAINT [CK_T_Users_UserName_NotEmpty] CHECK  (([U_Name]<>''))
GO
ALTER TABLE [dbo].[T_Users] CHECK CONSTRAINT [CK_T_Users_UserName_NotEmpty]
GO
ALTER TABLE [dbo].[T_Users]  WITH CHECK ADD  CONSTRAINT [CK_T_Users_UserName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([U_Name],(1))=(0)))
GO
ALTER TABLE [dbo].[T_Users] CHECK CONSTRAINT [CK_T_Users_UserName_WhiteSpace]
GO
