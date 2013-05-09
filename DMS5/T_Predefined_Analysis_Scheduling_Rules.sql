/****** Object:  Table [dbo].[T_Predefined_Analysis_Scheduling_Rules] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Predefined_Analysis_Scheduling_Rules](
	[SR_evaluationOrder] [smallint] NOT NULL,
	[SR_instrumentClass] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SR_instrument_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SR_dataset_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SR_analysisToolName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SR_priority] [int] NOT NULL,
	[SR_processorGroupID] [int] NULL,
	[SR_enabled] [tinyint] NOT NULL,
	[SR_Created] [datetime] NOT NULL,
	[ID] [int] IDENTITY(100,1) NOT NULL,
 CONSTRAINT [PK_T_Predefined_Analysis_Scheduling_Rules] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Rules]  WITH CHECK ADD  CONSTRAINT [FK_T_Predefined_Analysis_Scheduling_Rules_T_Analysis_Job_Processor_Group] FOREIGN KEY([SR_processorGroupID])
REFERENCES [T_Analysis_Job_Processor_Group] ([ID])
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Rules] CHECK CONSTRAINT [FK_T_Predefined_Analysis_Scheduling_Rules_T_Analysis_Job_Processor_Group]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Rules] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Rules_SR_instrumentClass]  DEFAULT ('') FOR [SR_instrumentClass]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Rules] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Rules_SR_instrument_Name]  DEFAULT ('') FOR [SR_instrument_Name]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Rules] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Rules_SR_dataset_Name]  DEFAULT ('') FOR [SR_dataset_Name]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Rules] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Rules_SR_analysisToolName]  DEFAULT ('') FOR [SR_analysisToolName]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Rules] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Rules_SR_priority]  DEFAULT (3) FOR [SR_priority]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Rules] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Rules_SR_enabled]  DEFAULT (1) FOR [SR_enabled]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Rules] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Rules_SR_Created]  DEFAULT (getdate()) FOR [SR_Created]
GO
