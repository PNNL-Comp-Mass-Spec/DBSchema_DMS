/****** Object:  Table [dbo].[T_Campaign_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Campaign_Tracking](
	[C_ID] [int] NOT NULL,
	[Cell_Culture_Count] [int] NOT NULL CONSTRAINT [DF_T_Campaign_Tracking_Cell_Culture_Count]  DEFAULT (0),
	[Experiment_Count] [int] NOT NULL CONSTRAINT [DF_T_Campaign_Tracking_Experiment_Count]  DEFAULT (0),
	[Dataset_Count] [int] NOT NULL CONSTRAINT [DF_T_Campaign_Tracking_Dataset_Count]  DEFAULT (0),
	[Job_Count] [int] NOT NULL CONSTRAINT [DF_T_Campaign_Tracking_Job_Count]  DEFAULT (0),
 CONSTRAINT [PK_T_Campaign_Tracking] PRIMARY KEY CLUSTERED 
(
	[C_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
