/****** Object:  Table [dbo].[dbxref] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dbxref](
	[dbxref_id] [int] NOT NULL,
	[parent_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ojb_xref_type] [int] NOT NULL,
	[dbname] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[accession] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[description] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[xref_type] [int] NULL,
 CONSTRAINT [PK_dbxref] PRIMARY KEY CLUSTERED 
(
	[dbxref_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_dbxref_dbname] ******/
CREATE NONCLUSTERED INDEX [IX_dbxref_dbname] ON [dbo].[dbxref] 
(
	[dbname] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_dbxref_parent_pk] ******/
CREATE NONCLUSTERED INDEX [IX_dbxref_parent_pk] ON [dbo].[dbxref] 
(
	[parent_pk] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
