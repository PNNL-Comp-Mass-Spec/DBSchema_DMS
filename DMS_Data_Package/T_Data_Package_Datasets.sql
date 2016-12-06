/****** Object:  Table [dbo].[T_Data_Package_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Package_Datasets](
	[Data_Package_ID] [int] NOT NULL,
	[Dataset_ID] [int] NOT NULL,
	[Dataset] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Experiment] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NULL,
	[Item Added] [datetime] NOT NULL,
	[Package Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Data_Package_Datasets] PRIMARY KEY CLUSTERED 
(
	[Data_Package_ID] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Data_Package_Datasets] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Data_Package_Datasets] TO [DMS_SP_User] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Data_Package_Datasets] TO [DMS_SP_User] AS [dbo]
GO
ALTER TABLE [dbo].[T_Data_Package_Datasets] ADD  CONSTRAINT [DF_T_Data_Package_Datasets_Item Added]  DEFAULT (getdate()) FOR [Item Added]
GO
ALTER TABLE [dbo].[T_Data_Package_Datasets] ADD  CONSTRAINT [DF_T_Data_Package_Datasets_Package Comment]  DEFAULT ('') FOR [Package Comment]
GO
ALTER TABLE [dbo].[T_Data_Package_Datasets]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Package_Datasets_T_Data_Package] FOREIGN KEY([Data_Package_ID])
REFERENCES [dbo].[T_Data_Package] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Data_Package_Datasets] CHECK CONSTRAINT [FK_T_Data_Package_Datasets_T_Data_Package]
GO
