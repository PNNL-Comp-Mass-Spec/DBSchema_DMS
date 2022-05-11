/****** Object:  Table [dbo].[T_Dataset_Storage_Move_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Storage_Move_Log](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[DatasetID] [int] NOT NULL,
	[StoragePathOld] [int] NULL,
	[StoragePathNew] [int] NULL,
	[ArchivePathOld] [int] NULL,
	[ArchivePathNew] [int] NULL,
	[MoveCmd] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NULL,
 CONSTRAINT [PK_T_Dataset_Storage_Move_Log] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Dataset_Storage_Move_Log] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Dataset_Storage_Move_Log_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Storage_Move_Log_DatasetID] ON [dbo].[T_Dataset_Storage_Move_Log]
(
	[DatasetID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Dataset_Storage_Move_Log] ADD  CONSTRAINT [DF_T_Dataset_Storage_Move_Log_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Dataset_Storage_Move_Log]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Storage_Move_Log_T_Dataset] FOREIGN KEY([DatasetID])
REFERENCES [dbo].[T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Dataset_Storage_Move_Log] CHECK CONSTRAINT [FK_T_Dataset_Storage_Move_Log_T_Dataset]
GO
