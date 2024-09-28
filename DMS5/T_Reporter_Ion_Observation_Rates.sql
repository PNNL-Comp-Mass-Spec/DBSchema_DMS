/****** Object:  Table [dbo].[T_Reporter_Ion_Observation_Rates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Reporter_Ion_Observation_Rates](
	[Job] [int] NOT NULL,
	[Dataset_ID] [int] NOT NULL,
	[Reporter_Ion] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TopNPct] [int] NOT NULL,
	[Channel1] [real] NULL,
	[Channel2] [real] NULL,
	[Channel3] [real] NULL,
	[Channel4] [real] NULL,
	[Channel5] [real] NULL,
	[Channel6] [real] NULL,
	[Channel7] [real] NULL,
	[Channel8] [real] NULL,
	[Channel9] [real] NULL,
	[Channel10] [real] NULL,
	[Channel11] [real] NULL,
	[Channel12] [real] NULL,
	[Channel13] [real] NULL,
	[Channel14] [real] NULL,
	[Channel15] [real] NULL,
	[Channel16] [real] NULL,
	[Channel17] [real] NULL,
	[Channel18] [real] NULL,
	[Channel1_Median_Intensity] [int] NULL,
	[Channel2_Median_Intensity] [int] NULL,
	[Channel3_Median_Intensity] [int] NULL,
	[Channel4_Median_Intensity] [int] NULL,
	[Channel5_Median_Intensity] [int] NULL,
	[Channel6_Median_Intensity] [int] NULL,
	[Channel7_Median_Intensity] [int] NULL,
	[Channel8_Median_Intensity] [int] NULL,
	[Channel9_Median_Intensity] [int] NULL,
	[Channel10_Median_Intensity] [int] NULL,
	[Channel11_Median_Intensity] [int] NULL,
	[Channel12_Median_Intensity] [int] NULL,
	[Channel13_Median_Intensity] [int] NULL,
	[Channel14_Median_Intensity] [int] NULL,
	[Channel15_Median_Intensity] [int] NULL,
	[Channel16_Median_Intensity] [int] NULL,
	[Channel17_Median_Intensity] [int] NULL,
	[Channel18_Median_Intensity] [int] NULL,
	[Entered] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Reporter_Ion_Observation_Rates] PRIMARY KEY CLUSTERED 
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Reporter_Ion_Observation_Rates] ADD  CONSTRAINT [DF_T_Reporter_Ion_Observation_Rates_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Reporter_Ion_Observation_Rates]  WITH CHECK ADD  CONSTRAINT [FK_T_Reporter_Ion_Observation_Rates_T_Analysis_Job] FOREIGN KEY([Job])
REFERENCES [dbo].[T_Analysis_Job] ([AJ_jobID])
GO
ALTER TABLE [dbo].[T_Reporter_Ion_Observation_Rates] CHECK CONSTRAINT [FK_T_Reporter_Ion_Observation_Rates_T_Analysis_Job]
GO
ALTER TABLE [dbo].[T_Reporter_Ion_Observation_Rates]  WITH CHECK ADD  CONSTRAINT [FK_T_Reporter_Ion_Observation_Rates_T_Sample_Labelling] FOREIGN KEY([Reporter_Ion])
REFERENCES [dbo].[T_Sample_Labelling] ([Label])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Reporter_Ion_Observation_Rates] CHECK CONSTRAINT [FK_T_Reporter_Ion_Observation_Rates_T_Sample_Labelling]
GO
