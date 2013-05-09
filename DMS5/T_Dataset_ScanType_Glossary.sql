/****** Object:  Table [dbo].[T_Dataset_ScanType_Glossary] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_ScanType_Glossary](
	[ScanType] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SortKey] [int] NOT NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Dataset_ScanType_Glossary] PRIMARY KEY CLUSTERED 
(
	[ScanType] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Dataset_ScanType_Glossary] ADD  CONSTRAINT [DF_T_Dataset_ScanType_Glossary_SortKey]  DEFAULT ((0)) FOR [SortKey]
GO
ALTER TABLE [dbo].[T_Dataset_ScanType_Glossary] ADD  CONSTRAINT [DF_T_Dataset_ScanType_Glossary_Comment]  DEFAULT ('') FOR [Comment]
GO
