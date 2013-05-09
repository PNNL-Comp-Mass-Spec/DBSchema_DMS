/****** Object:  Table [dbo].[T_Analysis_Job_PSM_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_PSM_Stats](
	[Job] [int] NOT NULL,
	[MSGF_Threshold] [float] NOT NULL,
	[FDR_Threshold] [float] NOT NULL,
	[Spectra_Searched] [int] NULL,
	[Total_PSMs] [int] NULL,
	[Unique_Peptides] [int] NULL,
	[Unique_Proteins] [int] NULL,
	[Total_PSMs_FDR_Filter] [int] NULL,
	[Unique_Peptides_FDR_Filter] [int] NULL,
	[Unique_Proteins_FDR_Filter] [int] NULL,
	[Last_Affected] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Analysis_Job_PSM_Stats] PRIMARY KEY CLUSTERED 
(
	[Job] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Analysis_Job_PSM_Stats] ADD  CONSTRAINT [DF_T_Analysis_Job_PSM_Stats_FDR_Threshold]  DEFAULT ((1)) FOR [FDR_Threshold]
GO
ALTER TABLE [dbo].[T_Analysis_Job_PSM_Stats] ADD  CONSTRAINT [DF_T_Analysis_Job_PSM_Stats_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
