/****** Object:  Table [dbo].[T_Analysis_Job_PSM_Stats_Phospho] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_PSM_Stats_Phospho](
	[Job] [int] NOT NULL,
	[Phosphopeptides] [int] NOT NULL,
	[CTermK_Phosphopeptides] [int] NOT NULL,
	[CTermR_Phosphopeptides] [int] NOT NULL,
	[MissedCleavageRatio] [real] NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Analysis_Job_PSM_Stats_Phospho] PRIMARY KEY CLUSTERED 
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Analysis_Job_PSM_Stats_Phospho] ADD  CONSTRAINT [DF_T_Analysis_Job_PSM_Stats_Phospho_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
