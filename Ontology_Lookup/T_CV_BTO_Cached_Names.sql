/****** Object:  Table [dbo].[T_CV_BTO_Cached_Names] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_CV_BTO_Cached_Names](
	[Identifier] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Term_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_CV_BTO_Cached_Names] PRIMARY KEY CLUSTERED 
(
	[Identifier] ASC,
	[Term_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_CV_BTO_Cached_Names] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_CV_BTO_Cached_Names_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_BTO_Cached_Names_Term_Name] ON [dbo].[T_CV_BTO_Cached_Names]
(
	[Term_Name] ASC
)
INCLUDE([Identifier]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
