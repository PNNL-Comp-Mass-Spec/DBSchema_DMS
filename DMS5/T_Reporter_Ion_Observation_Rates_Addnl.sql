/****** Object:  Table [dbo].[T_Reporter_Ion_Observation_Rates_Addnl] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Reporter_Ion_Observation_Rates_Addnl](
	[Job] [int] NOT NULL,
	[Dataset_ID] [int] NOT NULL,
	[Reporter_Ion] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TopNPct] [int] NOT NULL,
	[Channel19] [real] NULL,
	[Channel20] [real] NULL,
	[Channel21] [real] NULL,
	[Channel22] [real] NULL,
	[Channel23] [real] NULL,
	[Channel24] [real] NULL,
	[Channel25] [real] NULL,
	[Channel26] [real] NULL,
	[Channel27] [real] NULL,
	[Channel28] [real] NULL,
	[Channel29] [real] NULL,
	[Channel30] [real] NULL,
	[Channel31] [real] NULL,
	[Channel32] [real] NULL,
	[Channel33] [real] NULL,
	[Channel34] [real] NULL,
	[Channel35] [real] NULL,
	[Channel19_Median_Intensity] [int] NULL,
	[Channel20_Median_Intensity] [int] NULL,
	[Channel21_Median_Intensity] [int] NULL,
	[Channel22_Median_Intensity] [int] NULL,
	[Channel23_Median_Intensity] [int] NULL,
	[Channel24_Median_Intensity] [int] NULL,
	[Channel25_Median_Intensity] [int] NULL,
	[Channel26_Median_Intensity] [int] NULL,
	[Channel27_Median_Intensity] [int] NULL,
	[Channel28_Median_Intensity] [int] NULL,
	[Channel29_Median_Intensity] [int] NULL,
	[Channel30_Median_Intensity] [int] NULL,
	[Channel31_Median_Intensity] [int] NULL,
	[Channel32_Median_Intensity] [int] NULL,
	[Channel33_Median_Intensity] [int] NULL,
	[Channel34_Median_Intensity] [int] NULL,
	[Channel35_Median_Intensity] [int] NULL,
	[Entered] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Reporter_Ion_Observation_Rates_Addnl] PRIMARY KEY CLUSTERED 
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Reporter_Ion_Observation_Rates_Addnl] ADD  CONSTRAINT [DF_T_Reporter_Ion_Observation_Rates_Addnl_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Reporter_Ion_Observation_Rates_Addnl]  WITH CHECK ADD  CONSTRAINT [FK_T_Reporter_Ion_Observation_Rates_Addnl_T_Analysis_Job] FOREIGN KEY([Job])
REFERENCES [dbo].[T_Analysis_Job] ([AJ_jobID])
GO
ALTER TABLE [dbo].[T_Reporter_Ion_Observation_Rates_Addnl] CHECK CONSTRAINT [FK_T_Reporter_Ion_Observation_Rates_Addnl_T_Analysis_Job]
GO
ALTER TABLE [dbo].[T_Reporter_Ion_Observation_Rates_Addnl]  WITH CHECK ADD  CONSTRAINT [FK_T_Reporter_Ion_Observation_Rates_Addnl_T_Sample_Labelling] FOREIGN KEY([Reporter_Ion])
REFERENCES [dbo].[T_Sample_Labelling] ([Label])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Reporter_Ion_Observation_Rates_Addnl] CHECK CONSTRAINT [FK_T_Reporter_Ion_Observation_Rates_Addnl_T_Sample_Labelling]
GO
