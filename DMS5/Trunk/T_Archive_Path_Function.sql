/****** Object:  Table [dbo].[T_Archive_Path_Function] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Archive_Path_Function](
	[APF_Function] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Archive_Path_Function] PRIMARY KEY CLUSTERED 
(
	[APF_Function] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_Archive_Path_Function] TO [DMS_SP_User] AS [dbo]
GO
