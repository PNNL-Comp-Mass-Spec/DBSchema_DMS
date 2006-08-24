/****** Object:  View [dbo].[V_Synopsis_Report_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Synopsis_Report_Detail_Report
AS
SELECT Report_ID AS ID, Name, Description, Dataset_Match_List AS [Dataset Match List],
Instrument_Match_List AS [Instrument Match List], Param_File_Match_List AS [Param File Match List],
Fasta_File_Match_List AS [Fasta File Match List], Comparison_Job_Number AS [Comparison Job Number],
Scrolling_Dataset_Dates AS [Scrolling Dataset Dates], Scrolling_Dataset_Time_Frame AS [Scrolling Dataset Time Frame],
Dataset_Start_Date AS [Dataset Start Date], Dataset_End_Date AS [Dataset End Date],
Scrolling_Job_Dates AS [Scrolling Job Dates], Scrolling_Job_Time_Frame AS [Job Time Frame],
Job_Start_Date AS [Job Start Date], Job_End_Date AS [Job End Date],
Use_Synopsis_Files AS [Use Synopsis Files], Report_Sorting AS [Report Sorting],
Primary_Filter_ID AS [Primary Filter ID], Secondary_Filter_ID AS [Secondary Filter ID],
Required_Primary_Peptides_per_Protein AS [Req Primary Peptides per Protein],
Required_PrimaryPlusSecondary_Peptides_per_Protein AS [Req Primary plus Secondary Peptides per Protein],
Required_Overlap_Peptides_per_Overlap_Protein AS [Req Overlap Peptides per Overlap Protein],
Run_Interval AS [Run Interval], Repeat_Count AS [Repeat Count], State, State_Description AS [State Description],
Output_Form AS [Email Recipients], Comment
FROM T_Peptide_Synopsis_Reports INNER JOIN
 T_Peptide_Synopsis_Reports_State ON State = State_ID

GO
