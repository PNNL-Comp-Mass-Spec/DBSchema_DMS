/****** Object:  Table [dbo].[T_Ontology] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Ontology](
	[ontology_id] [int] NOT NULL,
	[shortName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fully_loaded] [smallint] NOT NULL,
	[uses_imports] [smallint] NOT NULL,
	[fullName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[query_url] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[source_url] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[definition] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[load_date] [datetime] NULL,
	[version] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_ontology] PRIMARY KEY CLUSTERED 
(
	[ontology_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Ontology] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Ontology_shortName] ******/
CREATE NONCLUSTERED INDEX [IX_T_Ontology_shortName] ON [dbo].[T_Ontology]
(
	[shortName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Ontology] ADD  CONSTRAINT [DF_ontology_fully_loaded]  DEFAULT ((0)) FOR [fully_loaded]
GO
