/****** Object:  Table [dbo].[T_Predefined_Analysis] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Predefined_Analysis](
	[AD_ID] [int] IDENTITY(1000,1) NOT NULL,
	[AD_level] [int] NOT NULL,
	[AD_sequence] [int] NULL,
	[AD_instrumentClassCriteria] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_campaignNameCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_campaignExclCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_experimentNameCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_experimentExclCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_instrumentNameCriteria] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_organismNameCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_datasetNameCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_datasetExclCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_datasetTypeCriteria] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_expCommentCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_labellingInclCriteria] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_labellingExclCriteria] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_separationTypeCriteria] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_scanCountMinCriteria] [int] NOT NULL,
	[AD_scanCountMaxCriteria] [int] NOT NULL,
	[AD_analysisToolName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_parmFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_settingsFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AD_organism_ID] [int] NOT NULL,
	[AD_organismDBName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_proteinCollectionList] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_proteinOptionsList] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_priority] [int] NOT NULL,
	[AD_specialProcessing] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AD_enabled] [tinyint] NOT NULL,
	[AD_description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AD_created] [datetime] NOT NULL,
	[AD_creator] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AD_nextLevel] [int] NULL,
	[Trigger_Before_Disposition] [tinyint] NOT NULL,
	[Propagation_Mode] [tinyint] NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Predefined_Analysis] PRIMARY KEY CLUSTERED 
(
	[AD_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_campaign_Name]  DEFAULT ('') FOR [AD_campaignNameCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_campaignExclCriteria]  DEFAULT ('') FOR [AD_campaignExclCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_experiment_Name]  DEFAULT ('') FOR [AD_experimentNameCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_experimentExclCriteria]  DEFAULT ('') FOR [AD_experimentExclCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_instrument_Name]  DEFAULT ('') FOR [AD_instrumentNameCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_organism_Name]  DEFAULT ('') FOR [AD_organismNameCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_datasetNameCriteria]  DEFAULT ('') FOR [AD_datasetNameCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_datasetExclCriteria]  DEFAULT ('') FOR [AD_datasetExclCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_datasetTypeCriteria]  DEFAULT ('') FOR [AD_datasetTypeCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_expCommentCriteria]  DEFAULT ('') FOR [AD_expCommentCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_criteriaLabellingInclusion]  DEFAULT ('') FOR [AD_labellingInclCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_criteriaLabellingExclusion]  DEFAULT ('') FOR [AD_labellingExclCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_separationTypeCriteria]  DEFAULT ('') FOR [AD_separationTypeCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_scanCountMin]  DEFAULT ((0)) FOR [AD_scanCountMinCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_scanCountMax]  DEFAULT ((0)) FOR [AD_scanCountMaxCriteria]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_organismDBName]  DEFAULT ('default') FOR [AD_organismDBName]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Analysis_Job_AD_proteinCollectionList]  DEFAULT ('na') FOR [AD_proteinCollectionList]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Analysis_Job_AD_proteinOptionsList]  DEFAULT ('na') FOR [AD_proteinOptionsList]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_priority]  DEFAULT ((2)) FOR [AD_priority]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_enabled]  DEFAULT ((0)) FOR [AD_enabled]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_AD_created]  DEFAULT (getdate()) FOR [AD_created]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Trigger_Before_Disposition]  DEFAULT ((0)) FOR [Trigger_Before_Disposition]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Propagation_Mode]  DEFAULT ((0)) FOR [Propagation_Mode]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] ADD  CONSTRAINT [DF_T_Predefined_Analysis]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis]  WITH CHECK ADD  CONSTRAINT [FK_T_Predefined_Analysis_T_Analysis_Tool] FOREIGN KEY([AD_analysisToolName])
REFERENCES [dbo].[T_Analysis_Tool] ([AJT_toolName])
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] CHECK CONSTRAINT [FK_T_Predefined_Analysis_T_Analysis_Tool]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis]  WITH CHECK ADD  CONSTRAINT [FK_T_Predefined_Analysis_T_Instrument_Class] FOREIGN KEY([AD_instrumentClassCriteria])
REFERENCES [dbo].[T_Instrument_Class] ([IN_class])
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] CHECK CONSTRAINT [FK_T_Predefined_Analysis_T_Instrument_Class]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis]  WITH CHECK ADD  CONSTRAINT [FK_T_Predefined_Analysis_T_Organisms] FOREIGN KEY([AD_organism_ID])
REFERENCES [dbo].[T_Organisms] ([Organism_ID])
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] CHECK CONSTRAINT [FK_T_Predefined_Analysis_T_Organisms]
GO
