/****** Object:  Table [dbo].[T_Cached_Experiment_Components] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Experiment_Components](
	[Exp_ID] [int] NOT NULL,
	[Cell_Culture_List] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Reference_Compound_List] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [smalldatetime] NOT NULL,
	[Last_affected] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_T_Cached_Experiment_Components] PRIMARY KEY CLUSTERED 
(
	[Exp_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Cached_Experiment_Components] ADD  CONSTRAINT [DF_T_Cached_Experiment_Components_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Cached_Experiment_Components] ADD  CONSTRAINT [DF_T_Cached_Experiment_Components_Last_affected]  DEFAULT (getdate()) FOR [Last_affected]
GO
