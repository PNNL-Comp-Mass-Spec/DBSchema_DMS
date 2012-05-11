/****** Object:  Table [dbo].[T_Dataset_QC_Metric_Names] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_QC_Metric_Names](
	[Metric] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Category] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Metric_Group] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Metric_Value] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Units] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Optimal] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Purpose] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Dataset_QC_Metrics] PRIMARY KEY CLUSTERED 
(
	[Metric] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
