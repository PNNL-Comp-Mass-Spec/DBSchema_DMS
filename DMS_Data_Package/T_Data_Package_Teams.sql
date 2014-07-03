/****** Object:  Table [dbo].[T_Data_Package_Teams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Package_Teams](
	[Team_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Data_Package_Teams_Team_Name] PRIMARY KEY CLUSTERED 
(
	[Team_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Data_Package_Teams] TO [DMS_SP_User] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Data_Package_Teams] TO [DMS_SP_User] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Data_Package_Teams] TO [DMS_SP_User] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Data_Package_Teams] TO [DMS_SP_User] AS [dbo]
GO
