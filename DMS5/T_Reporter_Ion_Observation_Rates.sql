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
	[Channel1_All] [real] NULL,
	[Channel2_All] [real] NULL,
	[Channel3_All] [real] NULL,
	[Channel4_All] [real] NULL,
	[Channel5_All] [real] NULL,
	[Channel6_All] [real] NULL,
	[Channel7_All] [real] NULL,
	[Channel8_All] [real] NULL,
	[Channel9_All] [real] NULL,
	[Channel10_All] [real] NULL,
	[Channel11_All] [real] NULL,
	[Channel12_All] [real] NULL,
	[Channel13_All] [real] NULL,
	[Channel14_All] [real] NULL,
	[Channel15_All] [real] NULL,
	[Channel16_All] [real] NULL,
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
