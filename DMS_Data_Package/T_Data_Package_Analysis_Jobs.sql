/****** Object:  Table [dbo].[T_Data_Package_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Package_Analysis_Jobs](
	[Data_Package_ID] [int] NOT NULL,
	[Job] [int] NOT NULL,
	[Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_ID] [int] NOT NULL,
	[Dataset] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NULL,
	[Item_Added] [datetime] NOT NULL,
	[Package_Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Data_Package_Analysis_Jobs] PRIMARY KEY CLUSTERED 
(
	[Data_Package_ID] ASC,
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Data_Package_Analysis_Jobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Data_Package_Analysis_Jobs] TO [DMS_SP_User] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Data_Package_Analysis_Jobs] TO [DMS_SP_User] AS [dbo]
GO
/****** Object:  Index [IX_T_Data_Package_Analysis_Jobs_Dataset_ID_Data_Package_ID_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_Data_Package_Analysis_Jobs_Dataset_ID_Data_Package_ID_Job] ON [dbo].[T_Data_Package_Analysis_Jobs]
(
	[Dataset_ID] ASC,
	[Data_Package_ID] ASC,
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Data_Package_Analysis_Jobs_Job_Include_Data_Package_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Data_Package_Analysis_Jobs_Job_Include_Data_Package_ID] ON [dbo].[T_Data_Package_Analysis_Jobs]
(
	[Job] ASC
)
INCLUDE([Data_Package_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Data_Package_Analysis_Jobs] ADD  CONSTRAINT [DF_T_Data_Package_Analysis_Jobs_Item Added]  DEFAULT (getdate()) FOR [Item_Added]
GO
ALTER TABLE [dbo].[T_Data_Package_Analysis_Jobs] ADD  CONSTRAINT [DF_T_Data_Package_Analysis_Jobs_Package Comment]  DEFAULT ('') FOR [Package_Comment]
GO
ALTER TABLE [dbo].[T_Data_Package_Analysis_Jobs]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Package_Analysis_Jobs_T_Data_Package] FOREIGN KEY([Data_Package_ID])
REFERENCES [dbo].[T_Data_Package] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Data_Package_Analysis_Jobs] CHECK CONSTRAINT [FK_T_Data_Package_Analysis_Jobs_T_Data_Package]
GO
