/****** Object:  Table [dbo].[T_NCBI_Taxonomy_Citations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_NCBI_Taxonomy_Citations](
	[Citation_ID] [int] NOT NULL,
	[Citation_Key] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PubMed_ID] [int] NOT NULL,
	[MedLine_ID] [int] NOT NULL,
	[URL] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Article_Text] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TaxID_List] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_NCBI_Taxonomy_Citations] PRIMARY KEY CLUSTERED 
(
	[Citation_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_NCBI_Taxonomy_Citations] TO [DDL_Viewer] AS [dbo]
GO
