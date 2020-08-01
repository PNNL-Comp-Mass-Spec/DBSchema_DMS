/****** Object:  Table [dbo].[T_Cached_Dataset_Links] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Dataset_Links](
	[Dataset_ID] [int] NOT NULL,
	[DS_RowVersion] [binary](8) NOT NULL,
	[SPath_RowVersion] [binary](8) NOT NULL,
	[Dataset_Folder_Path] [varchar](550) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Archive_Folder_Path] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MyEMSL_URL] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QC_Link] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QC_2D] [varchar](385) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QC_Metric_Stats] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MASIC_Directory_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[UpdateRequired] [tinyint] NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
 CONSTRAINT [PK_Cached_Dataset_Links] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Cached_Dataset_Links] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Cached_Dataset_Links_UpdateRequired] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cached_Dataset_Links_UpdateRequired] ON [dbo].[T_Cached_Dataset_Links]
(
	[UpdateRequired] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Links] ADD  CONSTRAINT [DF_T_Cached_Dataset_Links_UpdateRequired]  DEFAULT ((0)) FOR [UpdateRequired]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Links] ADD  CONSTRAINT [DF_T_Cached_Dataset_Links_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Links]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Dataset_Links_T_Dataset] FOREIGN KEY([Dataset_ID])
REFERENCES [dbo].[T_Dataset] ([Dataset_ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Links] CHECK CONSTRAINT [FK_T_Cached_Dataset_Links_T_Dataset]
GO
