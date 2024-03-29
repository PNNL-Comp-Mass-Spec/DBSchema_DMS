/****** Object:  Table [dbo].[T_MyEMSL_Uploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MyEMSL_Uploads](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Data_Pkg_ID] [int] NOT NULL,
	[Subfolder] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FileCountNew] [int] NULL,
	[FileCountUpdated] [int] NULL,
	[Bytes] [bigint] NULL,
	[UploadTimeSeconds] [real] NULL,
	[StatusURI_PathID] [int] NULL,
	[StatusNum] [int] NULL,
	[Available] [tinyint] NOT NULL,
	[Verified] [tinyint] NOT NULL,
	[ErrorCode] [int] NULL,
	[Entered] [datetime] NOT NULL,
	[Data_Package_ID]  AS ([Data_Pkg_ID]),
 CONSTRAINT [PK_T_MyEMSL_Uploads] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_MyEMSL_Uploads] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_MyEMSL_Uploads_Data_Package_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_Uploads_Data_Package_ID] ON [dbo].[T_MyEMSL_Uploads]
(
	[Data_Pkg_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_MyEMSL_Uploads_Entered] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_Uploads_Entered] ON [dbo].[T_MyEMSL_Uploads]
(
	[Entered] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_MyEMSL_Uploads_ErrorCode_StatusNum] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_Uploads_ErrorCode_StatusNum] ON [dbo].[T_MyEMSL_Uploads]
(
	[ErrorCode] ASC,
	[StatusNum] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_MyEMSL_Uploads] ADD  CONSTRAINT [DF_T_MyEMSL_Uploads_Available]  DEFAULT ((0)) FOR [Available]
GO
ALTER TABLE [dbo].[T_MyEMSL_Uploads] ADD  CONSTRAINT [DF_T_MyEMSL_Uploads_Verified]  DEFAULT ((0)) FOR [Verified]
GO
ALTER TABLE [dbo].[T_MyEMSL_Uploads] ADD  CONSTRAINT [DF_T_MyEMSL_Uploads_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_MyEMSL_Uploads]  WITH CHECK ADD  CONSTRAINT [FK_T_MyEMSL_Uploads_T_URI_Paths_StatusURI] FOREIGN KEY([StatusURI_PathID])
REFERENCES [dbo].[T_URI_Paths] ([URI_PathID])
GO
ALTER TABLE [dbo].[T_MyEMSL_Uploads] CHECK CONSTRAINT [FK_T_MyEMSL_Uploads_T_URI_Paths_StatusURI]
GO
