/****** Object:  Table [dbo].[T_CV_NEWT] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_CV_NEWT](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Term_PK] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Term_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Identifier] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Is_Leaf] [tinyint] NOT NULL,
	[Parent_term_name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Parent_term_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[GrandParent_term_name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GrandParent_term_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_CV_NEWT] PRIMARY KEY NONCLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_CV_NEWT_Term_Name] ******/
CREATE CLUSTERED INDEX [IX_T_CV_NEWT_Term_Name] ON [dbo].[T_CV_NEWT] 
(
	[Term_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_CV_NEWT_GrandParent_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_NEWT_GrandParent_Term_Name] ON [dbo].[T_CV_NEWT] 
(
	[GrandParent_term_name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_CV_NEWT_Parent_Term_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_CV_NEWT_Parent_Term_Name] ON [dbo].[T_CV_NEWT] 
(
	[Parent_term_name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
