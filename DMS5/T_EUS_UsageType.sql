/****** Object:  Table [dbo].[T_EUS_UsageType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EUS_UsageType](
	[ID] [smallint] IDENTITY(10,1) NOT NULL,
	[Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Enabled] [tinyint] NOT NULL,
	[Enabled_Campaign] [tinyint] NOT NULL,
	[Enabled_Prep_Request] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_EUS_UsageType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_EUS_UsageType] TO [DDL_Viewer] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_EUS_UsageType] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_EUS_UsageType] TO [DMS_EUS_Admin] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_EUS_UsageType_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_EUS_UsageType_Name] ON [dbo].[T_EUS_UsageType]
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_EUS_UsageType] ADD  CONSTRAINT [DF_T_EUS_UsageType_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[T_EUS_UsageType] ADD  CONSTRAINT [DF_T_EUS_UsageType_Enabled_Campaign]  DEFAULT ((1)) FOR [Enabled_Campaign]
GO
ALTER TABLE [dbo].[T_EUS_UsageType] ADD  CONSTRAINT [DF_T_EUS_UsageType_Enabled_Prep_Request]  DEFAULT ((1)) FOR [Enabled_Prep_Request]
GO
