/****** Object:  Table [dbo].[T_Predefined_Analysis] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Predefined_Analysis](
	[AD_level] [int] NOT NULL,
	[AD_sequence] [int] NULL,
	[AD_instrumentClassCriteria] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_campaignNameCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_campaign_Name]  DEFAULT (''),
	[AD_experimentNameCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_experiment_Name]  DEFAULT (''),
	[AD_instrumentNameCriteria] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_instrument_Name]  DEFAULT (''),
	[AD_organismNameCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_organism_Name]  DEFAULT (''),
	[AD_datasetNameCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_datasetNameCriteria]  DEFAULT (''),
	[AD_expCommentCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_expCommentCriteria]  DEFAULT (''),
	[AD_labellingInclCriteria] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_criteriaLabellingInclusion]  DEFAULT (''),
	[AD_labellingExclCriteria] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_criteriaLabellingExclusion]  DEFAULT (''),
	[AD_separationTypeCriteria] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_separationTypeCriteria]  DEFAULT (''),
	[AD_campaignExclCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_campaignExclCriteria]  DEFAULT (''),
	[AD_experimentExclCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_experimentExclCriteria]  DEFAULT (''),
	[AD_datasetExclCriteria] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_datasetExclCriteria]  DEFAULT (''),
	[AD_analysisToolName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_parmFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AD_settingsFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AD_organism_ID] [int] NOT NULL,
	[AD_organismDBName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_organismDBName]  DEFAULT ('default'),
	[AD_priority] [int] NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_priority]  DEFAULT ((2)),
	[AD_enabled] [tinyint] NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_enabled]  DEFAULT ((0)),
	[AD_description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AD_created] [datetime] NOT NULL CONSTRAINT [DF_T_Predefined_Analysis_AD_created]  DEFAULT (getdate()),
	[AD_creator] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AD_nextLevel] [int] NULL,
	[AD_ID] [int] IDENTITY(1000,1) NOT NULL,
	[AD_proteinCollectionList] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_AD_proteinCollectionList]  DEFAULT ('na'),
	[AD_proteinOptionsList] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_AD_proteinOptionsList]  DEFAULT ('na'),
 CONSTRAINT [PK_T_Predefined_Analysis] PRIMARY KEY CLUSTERED 
(
	[AD_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Predefined_Analysis]  WITH CHECK ADD  CONSTRAINT [FK_T_Predefined_Analysis_T_Instrument_Class] FOREIGN KEY([AD_instrumentClassCriteria])
REFERENCES [T_Instrument_Class] ([IN_class])
GO
ALTER TABLE [dbo].[T_Predefined_Analysis]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Predefined_Analysis_T_Organisms] FOREIGN KEY([AD_organism_ID])
REFERENCES [T_Organisms] ([Organism_ID])
GO
ALTER TABLE [dbo].[T_Predefined_Analysis] CHECK CONSTRAINT [FK_T_Predefined_Analysis_T_Organisms]
GO
