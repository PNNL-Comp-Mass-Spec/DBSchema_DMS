/****** Object:  Table [dbo].[T_MiscPaths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MiscPaths](
	[path_id] [int] IDENTITY(1,1) NOT NULL,
	[Function] [char](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Server] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Client] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_MiscPaths] PRIMARY KEY CLUSTERED 
(
	[path_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_MiscPaths] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_MiscPaths_Function] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_MiscPaths_Function] ON [dbo].[T_MiscPaths]
(
	[Function] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_MiscPaths] ADD  CONSTRAINT [DF_T_MiscPaths_Comment]  DEFAULT ('') FOR [Comment]
GO
