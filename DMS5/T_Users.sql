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
) ON [PRIMARY],
 CONSTRAINT [IX_T_Users] UNIQUE NONCLUSTERED 
(
	[U_PRN] ASC
) ON [PRIMARY],
 CONSTRAINT [IX_T_Users_1] UNIQUE NONCLUSTERED 
(
	[U_PRN] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
