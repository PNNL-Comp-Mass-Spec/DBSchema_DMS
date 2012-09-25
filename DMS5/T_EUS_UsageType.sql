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
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_EUS_UsageType] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_EUS_UsageType] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_EUS_UsageType] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] TO [DMS_User] AS [dbo]
GO
