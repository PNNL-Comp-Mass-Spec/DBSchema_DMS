/****** Object:  Table [dbo].[T_Permissions_Test_Table] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Permissions_Test_Table](
	[ID] [int] NOT NULL,
	[Setting] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Value] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Permissions_Test_Table] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
DENY SELECT ON [dbo].[T_Permissions_Test_Table] TO [DMSReader] AS [dbo]
GO
