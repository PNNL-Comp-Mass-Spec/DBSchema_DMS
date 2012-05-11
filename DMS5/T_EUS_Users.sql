/****** Object:  Table [dbo].[T_EUS_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EUS_Users](
	[PERSON_ID] [int] NOT NULL,
	[NAME_FM] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[HID] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Site_Status] [tinyint] NOT NULL,
	[Last_Affected] [datetime] NULL,
 CONSTRAINT [PK_T_EUS_Users] PRIMARY KEY CLUSTERED 
(
	[PERSON_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_EUS_Users] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_EUS_Users] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_EUS_Users] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_EUS_Users] TO [DMS_EUS_Admin] AS [dbo]
GO
ALTER TABLE [dbo].[T_EUS_Users]  WITH CHECK ADD  CONSTRAINT [FK_T_EUS_Users_T_EUS_Site_Status] FOREIGN KEY([Site_Status])
REFERENCES [T_EUS_Site_Status] ([ID])
GO
ALTER TABLE [dbo].[T_EUS_Users] CHECK CONSTRAINT [FK_T_EUS_Users_T_EUS_Site_Status]
GO
ALTER TABLE [dbo].[T_EUS_Users] ADD  CONSTRAINT [DF_T_EUS_Users_PERSON_ID]  DEFAULT ('0') FOR [PERSON_ID]
GO
ALTER TABLE [dbo].[T_EUS_Users] ADD  CONSTRAINT [DF_T_EUS_Users_EUS_Users]  DEFAULT (NULL) FOR [NAME_FM]
GO
ALTER TABLE [dbo].[T_EUS_Users] ADD  CONSTRAINT [DF_T_EUS_Users_Stie_Status]  DEFAULT ((2)) FOR [Site_Status]
GO
ALTER TABLE [dbo].[T_EUS_Users] ADD  CONSTRAINT [DF_T_EUS_Users_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
