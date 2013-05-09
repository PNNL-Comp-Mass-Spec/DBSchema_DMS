/****** Object:  Table [dbo].[T_Data_Package_Experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Package_Experiments](
	[Data_Package_ID] [int] NOT NULL,
	[Experiment_ID] [int] NOT NULL,
	[Experiment] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NULL,
	[Item Added] [datetime] NOT NULL,
	[Package Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Data_Package_Experiments] PRIMARY KEY CLUSTERED 
(
	[Data_Package_ID] ASC,
	[Experiment_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_Data_Package_Experiments] TO [DMS_SP_User] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Data_Package_Experiments] TO [DMS_SP_User] AS [dbo]
GO
ALTER TABLE [dbo].[T_Data_Package_Experiments]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Package_Experiments_T_Data_Package] FOREIGN KEY([Data_Package_ID])
REFERENCES [T_Data_Package] ([ID])
GO
ALTER TABLE [dbo].[T_Data_Package_Experiments] CHECK CONSTRAINT [FK_T_Data_Package_Experiments_T_Data_Package]
GO
ALTER TABLE [dbo].[T_Data_Package_Experiments] ADD  CONSTRAINT [DF_T_Data_Package_Experiments_Item Added]  DEFAULT (getdate()) FOR [Item Added]
GO
ALTER TABLE [dbo].[T_Data_Package_Experiments] ADD  CONSTRAINT [DF_T_Data_Package_Experiments_Package Comment]  DEFAULT ('') FOR [Package Comment]
GO
