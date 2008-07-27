/****** Object:  Table [dbo].[T_EUS_Site_Status] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EUS_Site_Status](
	[ID] [tinyint] NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ShortName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_EUS_Site_Status] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_EUS_Site_Status] TO [DMS_EUS_Admin]
GO
GRANT INSERT ON [dbo].[T_EUS_Site_Status] TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_Site_Status] TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_Site_Status] TO [DMS_EUS_Admin]
GO
