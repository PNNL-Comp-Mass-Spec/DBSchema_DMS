/****** Object:  Table [dbo].[T_NCBI_Taxonomy_Name_Class] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_NCBI_Taxonomy_Name_Class](
	[Name_Class] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Sort_Weight] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_NCBI_Taxonomy_Name_Class] PRIMARY KEY CLUSTERED 
(
	[Name_Class] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_NCBI_Taxonomy_Name_Class_Sort_Weight] ******/
CREATE NONCLUSTERED INDEX [IX_T_NCBI_Taxonomy_Name_Class_Sort_Weight] ON [dbo].[T_NCBI_Taxonomy_Name_Class]
(
	[Sort_Weight] ASC
)
INCLUDE ( 	[Name_Class]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
