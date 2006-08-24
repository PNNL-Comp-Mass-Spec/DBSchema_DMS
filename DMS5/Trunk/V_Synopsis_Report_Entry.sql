/****** Object:  View [dbo].[V_Synopsis_Report_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Synopsis_Report_Entry
AS
SELECT Report_ID, Name, Description, Dataset_Match_List,
Instrument_Match_List, Param_File_Match_List,
Fasta_File_Match_List, Comparison_Job_Number,
Scrolling_Dataset_Dates, Scrolling_Dataset_Time_Frame,
Dataset_Start_Date, Dataset_End_Date,
Scrolling_Job_Dates, Scrolling_Job_Time_Frame,
Job_Start_Date, Job_End_Date,
Use_Synopsis_Files, Report_Sorting,
Primary_Filter_ID, Secondary_Filter_ID,
Required_Primary_Peptides_per_Protein,
Required_PrimaryPlusSecondary_Peptides_per_Protein,
Required_Overlap_Peptides_per_Overlap_Protein,
Run_Interval, Repeat_Count, State_Description,
Output_Form, Comment
FROM T_Peptide_Synopsis_Reports INNER JOIN
 T_Peptide_Synopsis_Reports_State ON State = State_ID

GO
