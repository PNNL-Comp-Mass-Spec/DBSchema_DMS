/****** Object:  Table [dbo].[T_Cell_Culture_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cell_Culture_Tracking](
	[CC_ID] [int] NOT NULL,
	[Experiment_Count] [int] NOT NULL,
	[Dataset_Count] [int] NOT NULL,
	[Job_Count] [int] NOT NULL,
 CONSTRAINT [PK_T_Cell_Culture_Tracking] PRIMARY KEY CLUSTERED 
(
	[CC_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Cell_Culture_Tracking] ADD  CONSTRAINT [DF_T_Cell_Culture_Tracking_Experiment_Count]  DEFAULT (0) FOR [Experiment_Count]
GO
ALTER TABLE [dbo].[T_Cell_Culture_Tracking] ADD  CONSTRAINT [DF_T_Cell_Culture_Tracking_Dataset_Count]  DEFAULT (0) FOR [Dataset_Count]
GO
ALTER TABLE [dbo].[T_Cell_Culture_Tracking] ADD  CONSTRAINT [DF_T_Cell_Culture_Tracking_Job_Count]  DEFAULT (0) FOR [Job_Count]
GO
