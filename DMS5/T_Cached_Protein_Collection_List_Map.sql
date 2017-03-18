/****** Object:  Table [dbo].[T_Cached_Protein_Collection_List_Map] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Protein_Collection_List_Map](
	[ProtCollectionList_ID] [int] IDENTITY(1,1) NOT NULL,
	[Protein_Collection_List] [varchar](8000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_T_Cached_Protein_Collection_List_Map] PRIMARY KEY CLUSTERED 
(
	[ProtCollectionList_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Cached_Protein_Collection_List_Map] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Cached_Protein_Collection_List_Map] ADD  CONSTRAINT [DF_T_Cached_Protein_Collection_List_Map_Created]  DEFAULT (getdate()) FOR [Created]
GO
