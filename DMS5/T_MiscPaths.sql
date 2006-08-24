/****** Object:  Table [dbo].[T_MiscPaths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MiscPaths](
	[TMP_ID] [int] IDENTITY(1,1) NOT NULL,
	[Server] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Client] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Function] [char](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_MiscPaths] PRIMARY KEY CLUSTERED 
(
	[TMP_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
