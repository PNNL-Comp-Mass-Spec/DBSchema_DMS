/****** Object:  Table [dbo].[T_Peptide_Synopsis_Reports] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Peptide_Synopsis_Reports](
	[Report_ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Dataset_Match_List] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Instrument_Match_List] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Instrument_Match_List]  DEFAULT ('%'),
	[Param_File_Match_List] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Param_File_Match_List]  DEFAULT ('%'),
	[Fasta_File_Match_List] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Fasta_File_Match_List]  DEFAULT ('%'),
	[Experiment_Match_List] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Experiment_Match_List]  DEFAULT ('%'),
	[Comparison_Job_Number] [int] NOT NULL,
	[Scrolling_Dataset_Dates] [tinyint] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Scrolling_Dataset_Dates]  DEFAULT (0),
	[Scrolling_Dataset_Time_Frame] [int] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Scrolling_Dataset_Time_Frame]  DEFAULT (365),
	[Dataset_Start_Date] [datetime] NULL,
	[Dataset_End_Date] [datetime] NULL,
	[Scrolling_Job_Dates] [tinyint] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Scrolling_Job_Dates]  DEFAULT (0),
	[Scrolling_Job_Time_Frame] [int] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Scrolling_Job_Time_Frame]  DEFAULT (7),
	[Job_Start_Date] [datetime] NULL,
	[Job_End_Date] [datetime] NULL,
	[Use_Synopsis_Files] [tinyint] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_File_To_Use]  DEFAULT (0),
	[Report_Sorting] [int] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Report_Sorting]  DEFAULT (0),
	[Primary_Filter_ID] [int] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Filter_ID]  DEFAULT (104),
	[Secondary_Filter_ID] [int] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Secondary_Filter_ID]  DEFAULT (104),
	[Required_Primary_Peptides_per_Protein] [int] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Required_Primary_Peptides_per_Protein]  DEFAULT (2),
	[Required_PrimaryPlusSecondary_Peptides_per_Protein] [int] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Required_PrimaryPlusSecondary_Peptides_per_Protein]  DEFAULT (1),
	[Required_Overlap_Peptides_per_Overlap_Protein] [int] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Required_Overlap_Peptides_per_Overlap_Protein]  DEFAULT (0),
	[Run_Interval] [int] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Run_Interval]  DEFAULT (10080),
	[Repeat_Count] [int] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Repeat_Count]  DEFAULT (1),
	[State] [int] NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_State]  DEFAULT (0),
	[Processor_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Output_Form] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Output_Form]  DEFAULT (''),
	[Task_Type] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Task_Type]  DEFAULT ('Synopsis'),
	[Database_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Peptide_Synopsis_Reports_Database_Name]  DEFAULT ('na'),
	[Server_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Peptide_Synopsis_Reports] PRIMARY KEY CLUSTERED 
(
	[Report_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_Peptide_Synopsis_Reports] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Peptide_Synopsis_Reports] TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Peptide_Synopsis_Reports]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Peptide_Synopsis_Reports_T_Peptide_Synopsis_Reports_Sorting] FOREIGN KEY([Report_Sorting])
REFERENCES [T_Peptide_Synopsis_Reports_Sorting] ([Report_Sort_ID])
GO
ALTER TABLE [dbo].[T_Peptide_Synopsis_Reports] CHECK CONSTRAINT [FK_T_Peptide_Synopsis_Reports_T_Peptide_Synopsis_Reports_Sorting]
GO
ALTER TABLE [dbo].[T_Peptide_Synopsis_Reports]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Peptide_Synopsis_Reports_T_Peptide_Synopsis_Reports_State] FOREIGN KEY([State])
REFERENCES [T_Peptide_Synopsis_Reports_State] ([State_ID])
GO
ALTER TABLE [dbo].[T_Peptide_Synopsis_Reports] CHECK CONSTRAINT [FK_T_Peptide_Synopsis_Reports_T_Peptide_Synopsis_Reports_State]
GO
