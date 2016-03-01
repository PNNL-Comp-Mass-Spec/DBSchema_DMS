/****** Object:  Table [dbo].[T_NCBI_Taxonomy_GenCode] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_NCBI_Taxonomy_GenCode](
	[Genetic_Code_ID] [smallint] NOT NULL,
	[Abbreviation] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Genetic_Code_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Code_Table] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Starts] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_NCBI_Taxonomy_GenCode] PRIMARY KEY CLUSTERED 
(
	[Genetic_Code_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
