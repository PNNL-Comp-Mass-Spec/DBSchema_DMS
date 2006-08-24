/****** Object:  Table [dbo].[T_Peptide_Synopsis_Report_Runs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Peptide_Synopsis_Report_Runs](
	[Synopsis_Report_Run_ID] [int] IDENTITY(1,1) NOT NULL,
	[Synopsis_Report] [int] NOT NULL,
	[Run_Date] [datetime] NOT NULL,
	[Failure] [tinyint] NOT NULL,
	[Storage_Path] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Processor_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Peptide_Synopsis_Report_Runs] PRIMARY KEY CLUSTERED 
(
	[Synopsis_Report_Run_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Peptide_Synopsis_Report_Runs]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Peptide_Synopsis_Report_Runs_T_Peptide_Synopsis_Reports] FOREIGN KEY([Synopsis_Report])
REFERENCES [T_Peptide_Synopsis_Reports] ([Report_ID])
GO
ALTER TABLE [dbo].[T_Peptide_Synopsis_Report_Runs] CHECK CONSTRAINT [FK_T_Peptide_Synopsis_Report_Runs_T_Peptide_Synopsis_Reports]
GO
