/****** Object:  Table [dbo].[T_Dataset_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Files](
	[Dataset_File_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Dataset_ID] [int] NOT NULL,
	[File_Path] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[File_Size_Bytes] [bigint] NULL,
	[File_Hash] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[File_Size_Rank] [smallint] NULL,
	[Allow_Duplicates] [bit] NULL,
	[Deleted] [bit] NULL,
 CONSTRAINT [PK_T_Dataset_Files] PRIMARY KEY NONCLUSTERED 
(
	[Dataset_File_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Dataset_Files_DatasetID_FilePath] ******/
CREATE UNIQUE CLUSTERED INDEX [IX_T_Dataset_Files_DatasetID_FilePath] ON [dbo].[T_Dataset_Files]
(
	[Dataset_ID] ASC,
	[File_Path] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Dataset_Files] ADD  CONSTRAINT [DF_T_Dataset_Files_Allow_Duplicates]  DEFAULT ((0)) FOR [Allow_Duplicates]
GO
ALTER TABLE [dbo].[T_Dataset_Files] ADD  CONSTRAINT [DF_T_Dataset_Files_Deleted]  DEFAULT ((0)) FOR [Deleted]
GO
