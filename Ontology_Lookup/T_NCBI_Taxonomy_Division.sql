/****** Object:  Table [dbo].[T_NCBI_Taxonomy_Division] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_NCBI_Taxonomy_Division](
	[Division_ID] [smallint] NOT NULL,
	[Division_Code] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Division_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comments] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_NCBI_Taxonomy_Division] PRIMARY KEY CLUSTERED 
(
	[Division_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
