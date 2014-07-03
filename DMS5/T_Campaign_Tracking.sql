/****** Object:  Table [dbo].[T_Campaign_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Campaign_Tracking](
	[C_ID] [int] NOT NULL,
	[Cell_Culture_Count] [int] NOT NULL,
	[Experiment_Count] [int] NOT NULL,
	[Dataset_Count] [int] NOT NULL,
	[Job_Count] [int] NOT NULL,
	[Run_Request_Count] [int] NOT NULL,
	[Sample_Prep_Request_Count] [int] NOT NULL,
	[Cell_Culture_Most_Recent] [datetime] NULL,
	[Experiment_Most_Recent] [datetime] NULL,
	[Dataset_Most_Recent] [datetime] NULL,
	[Job_Most_Recent] [datetime] NULL,
	[Run_Request_Most_Recent] [datetime] NULL,
	[Sample_Prep_Request_Most_Recent] [datetime] NULL,
	[Most_Recent_Activity] [datetime] NULL,
 CONSTRAINT [PK_T_Campaign_Tracking] PRIMARY KEY CLUSTERED 
(
	[C_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Campaign_Tracking] ADD  CONSTRAINT [DF_T_Campaign_Tracking_Cell_Culture_Count]  DEFAULT (0) FOR [Cell_Culture_Count]
GO
ALTER TABLE [dbo].[T_Campaign_Tracking] ADD  CONSTRAINT [DF_T_Campaign_Tracking_Experiment_Count]  DEFAULT (0) FOR [Experiment_Count]
GO
ALTER TABLE [dbo].[T_Campaign_Tracking] ADD  CONSTRAINT [DF_T_Campaign_Tracking_Dataset_Count]  DEFAULT (0) FOR [Dataset_Count]
GO
ALTER TABLE [dbo].[T_Campaign_Tracking] ADD  CONSTRAINT [DF_T_Campaign_Tracking_Job_Count]  DEFAULT (0) FOR [Job_Count]
GO
ALTER TABLE [dbo].[T_Campaign_Tracking] ADD  CONSTRAINT [DF_T_Campaign_Tracking_Run_Request_Count]  DEFAULT ((0)) FOR [Run_Request_Count]
GO
ALTER TABLE [dbo].[T_Campaign_Tracking] ADD  CONSTRAINT [DF_T_Campaign_Tracking_Sample_Prep_Request_Count]  DEFAULT ((0)) FOR [Sample_Prep_Request_Count]
GO
