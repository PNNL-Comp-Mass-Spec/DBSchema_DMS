/****** Object:  Table [dbo].[T_Cached_Protein_Collection_List_Members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Protein_Collection_List_Members](
	[ProtCollectionList_ID] [int] NOT NULL,
	[Protein_Collection_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Cached_Protein_Collection_List_Members] PRIMARY KEY CLUSTERED 
(
	[ProtCollectionList_ID] ASC,
	[Protein_Collection_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Cached_Protein_Collection_List_Members] TO [DDL_Viewer] AS [dbo]
GO
