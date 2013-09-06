/****** Object:  Table [dbo].[T_Dataset_QC_Metric_Names] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_QC_Metric_Names](
	[Metric] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Source] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Category] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Short_Description] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Metric_Group] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Metric_Value] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Units] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Optimal] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Purpose] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Ignored] [tinyint] NULL,
	[SortKey] [int] NOT NULL,
 CONSTRAINT [PK_T_Dataset_QC_Metrics] PRIMARY KEY NONCLUSTERED 
(
	[Metric] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Dataset_QC_Metric_Names_SortKey] ******/
CREATE CLUSTERED INDEX [IX_T_Dataset_QC_Metric_Names_SortKey] ON [dbo].[T_Dataset_QC_Metric_Names] 
(
	[SortKey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Dataset_QC_Metric_Names_Source_Metric] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Dataset_QC_Metric_Names_Source_Metric] ON [dbo].[T_Dataset_QC_Metric_Names] 
(
	[Source] ASC,
	[Metric] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Dataset_QC_Metric_Names] ADD  CONSTRAINT [DF_T_Dataset_QC_Metric_Names_Ignored]  DEFAULT ((0)) FOR [Ignored]
GO
