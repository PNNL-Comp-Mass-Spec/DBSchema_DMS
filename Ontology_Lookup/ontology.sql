/****** Object:  Table [dbo].[ontology] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ontology](
	[ontology_id] [int] NOT NULL,
	[shortName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fully_loaded] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[uses_imports] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fullName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[query_url] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[source_url] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[definition] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[load_date] [datetime] NULL,
	[version] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_ontology] PRIMARY KEY CLUSTERED 
(
	[ontology_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

/****** Object:  Index [IX_ontology_shortName] ******/
CREATE NONCLUSTERED INDEX [IX_ontology_shortName] ON [dbo].[ontology] 
(
	[shortName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ontology] ADD  CONSTRAINT [DF_ontology_fully_loaded]  DEFAULT ('0') FOR [fully_loaded]
GO
