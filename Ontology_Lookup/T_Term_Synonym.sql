/****** Object:  Table [dbo].[T_Term_Synonym] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Term_Synonym](
	[synonym_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[synonym_type_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[synonym_value] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_term_synonym] PRIMARY KEY CLUSTERED 
(
	[synonym_pk] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Term_Synonym] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Term_Synonym]  WITH CHECK ADD  CONSTRAINT [FK_term_synonym_term] FOREIGN KEY([term_pk])
REFERENCES [dbo].[T_Term] ([term_pk])
GO
ALTER TABLE [dbo].[T_Term_Synonym] CHECK CONSTRAINT [FK_term_synonym_term]
GO
