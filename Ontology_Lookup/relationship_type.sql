/****** Object:  Table [dbo].[relationship_type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[relationship_type](
	[relationship_type_id] [int] NOT NULL,
	[relationship_type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_relationship_type] PRIMARY KEY CLUSTERED 
(
	[relationship_type_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[relationship_type] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[relationship_type] ADD  CONSTRAINT [DF_relationship_type_relationship_type]  DEFAULT ('') FOR [relationship_type]
GO
