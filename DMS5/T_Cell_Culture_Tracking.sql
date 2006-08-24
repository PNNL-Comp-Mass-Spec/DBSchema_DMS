/****** Object:  Table [dbo].[T_Cell_Culture_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cell_Culture_Tracking](
	[CC_ID] [int] NOT NULL,
	[Experiment_Count] [int] NOT NULL CONSTRAINT [DF_T_Cell_Culture_Tracking_Experiment_Count]  DEFAULT (0),
	[Dataset_Count] [int] NOT NULL CONSTRAINT [DF_T_Cell_Culture_Tracking_Dataset_Count]  DEFAULT (0),
	[Job_Count] [int] NOT NULL CONSTRAINT [DF_T_Cell_Culture_Tracking_Job_Count]  DEFAULT (0),
 CONSTRAINT [PK_T_Cell_Culture_Tracking] PRIMARY KEY CLUSTERED 
(
	[CC_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
