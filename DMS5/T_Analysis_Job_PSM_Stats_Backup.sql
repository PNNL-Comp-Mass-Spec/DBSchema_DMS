/****** Object:  Table [dbo].[T_Analysis_Job_PSM_Stats_Backup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_PSM_Stats_Backup](
	[Job] [int] NOT NULL,
	[MSGF_Threshold] [float] NOT NULL,
	[FDR_Threshold] [float] NOT NULL,
	[MSGF_Threshold_Is_EValue] [tinyint] NOT NULL,
	[Spectra_Searched] [int] NULL,
	[Total_PSMs] [int] NULL,
	[Unique_Peptides] [int] NULL,
	[Unique_Proteins] [int] NULL,
	[Total_PSMs_FDR_Filter] [int] NULL,
	[Unique_Peptides_FDR_Filter] [int] NULL,
	[Unique_Proteins_FDR_Filter] [int] NULL,
	[Missed_Cleavage_Ratio_FDR] [real] NULL,
	[Tryptic_Peptides_FDR] [int] NULL,
	[Keratin_Peptides_FDR] [int] NULL,
	[Trypsin_Peptides_FDR] [int] NULL,
	[Acetyl_Peptides_FDR] [int] NULL,
	[Percent_MSn_Scans_NoPSM] [real] NULL,
	[Maximum_ScanGap_Adjacent_MSn] [int] NULL,
	[Dynamic_Reporter_Ion] [tinyint] NOT NULL,
	[Percent_PSMs_Missing_NTermReporterIon] [real] NULL,
	[Percent_PSMs_Missing_ReporterIon] [real] NULL,
	[Last_Affected] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Analysis_Job_PSM_Stats_Backup] PRIMARY KEY CLUSTERED 
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
