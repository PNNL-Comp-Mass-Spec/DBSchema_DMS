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
	[U_Access_Lists] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[U_email] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[U_domain] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[U_netid] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[U_active] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Users_U_active]  DEFAULT ('Y'),
	[U_update] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Users_U_update]  DEFAULT ('Y'),
 CONSTRAINT [PK_T_Users] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY],
 CONSTRAINT [IX_T_Users] UNIQUE NONCLUSTERED 
(
	[U_PRN] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY],
 CONSTRAINT [IX_T_Users_1] UNIQUE NONCLUSTERED 
(
	[U_PRN] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_Users] TO [Limited_Table_Write]
GO
GRANT INSERT ON [dbo].[T_Users] TO [Limited_Table_Write]
GO
GRANT DELETE ON [dbo].[T_Users] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Users] TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Users] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Users] ([U_PRN]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Users] ([U_PRN]) TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Users] ([U_PRN]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Users] ([U_Name]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Users] ([U_Name]) TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Users] ([U_Name]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Users] ([U_HID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Users] ([U_HID]) TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Users] ([U_HID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Users] ([ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Users] ([ID]) TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Users] ([ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Users] ([U_Access_Lists]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Users] ([U_Access_Lists]) TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Users] ([U_Access_Lists]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Users] ([U_email]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Users] ([U_email]) TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Users] ([U_email]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Users] ([U_domain]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Users] ([U_domain]) TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Users] ([U_domain]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Users] ([U_netid]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Users] ([U_netid]) TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Users] ([U_netid]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Users] ([U_active]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Users] ([U_active]) TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Users] ([U_active]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Users] ([U_update]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Users] ([U_update]) TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Users] ([U_update]) TO [Limited_Table_Write]
GO
