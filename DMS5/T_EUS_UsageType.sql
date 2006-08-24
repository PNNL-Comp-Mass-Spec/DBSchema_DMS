/****** Object:  Table [dbo].[T_EUS_UsageType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EUS_UsageType](
	[ID] [int] IDENTITY(10,1) NOT NULL,
	[Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_EUS_UsageType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] TO [DMS_EUS_Admin]
GO
GRANT INSERT ON [dbo].[T_EUS_UsageType] TO [DMS_EUS_Admin]
GO
GRANT DELETE ON [dbo].[T_EUS_UsageType] TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_UsageType] TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] TO [DMS_User]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] TO [DMSReader]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] TO [DMSWebUser]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([ID]) TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_UsageType] ([ID]) TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([ID]) TO [DMS_User]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([ID]) TO [DMSReader]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([ID]) TO [DMSWebUser]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([Name]) TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_UsageType] ([Name]) TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([Name]) TO [DMS_User]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([Name]) TO [DMSReader]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([Name]) TO [DMSWebUser]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([Description]) TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_UsageType] ([Description]) TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([Description]) TO [DMS_User]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([Description]) TO [DMSReader]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] ([Description]) TO [DMSWebUser]
GO
