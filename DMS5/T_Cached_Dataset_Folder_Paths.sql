/****** Object:  Table [dbo].[T_Cached_Dataset_Folder_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Dataset_Folder_Paths](
	[Dataset_ID] [int] NOT NULL,
	[DS_RowVersion] [binary](8) NOT NULL,
	[SPath_RowVersion] [binary](8) NULL,
	[Dataset_Folder_Path] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Archive_Folder_Path] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MyEMSL_Path_Flag] [varchar](416) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_URL] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[UpdateRequired] [tinyint] NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Cached_Dataset_Folder_Paths] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Cached_Dataset_Folder_Paths_UpdateRequired] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cached_Dataset_Folder_Paths_UpdateRequired] ON [dbo].[T_Cached_Dataset_Folder_Paths] 
(
	[UpdateRequired] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Folder_Paths]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Dataset_Folder_Paths_T_Dataset] FOREIGN KEY([Dataset_ID])
REFERENCES [T_Dataset] ([Dataset_ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Folder_Paths] CHECK CONSTRAINT [FK_T_Cached_Dataset_Folder_Paths_T_Dataset]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Folder_Paths] ADD  CONSTRAINT [DF_T_Cached_Dataset_Folder_Paths_UpdateRequired]  DEFAULT ((0)) FOR [UpdateRequired]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Folder_Paths] ADD  CONSTRAINT [DF_T_Cached_Dataset_Folder_Paths_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
