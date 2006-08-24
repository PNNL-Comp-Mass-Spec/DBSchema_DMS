/****** Object:  View [dbo].[V_QRollup_Report_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create    VIEW V_QRollup_Report_Detail_Report
AS
SELECT Report_ID AS ID, Name, Description, Dataset_Match_List AS [Dataset Match List],
Experiment_Match_List AS [Experiment Match List], Comparison_Job_Number AS [Comparison QID Number], 
Server_Name AS [Server Name], Database_Name AS [Database Name], 
Report_Sorting AS [Report Sorting], Primary_Filter_ID AS [Primary Filter ID], 
Secondary_Filter_ID AS [Secondary Filter ID], 
Required_Primary_Peptides_per_Protein AS [Req Primary Peptides per Protein],
Required_PrimaryPlusSecondary_Peptides_per_Protein AS [Req Primary plus Secondary Peptides per Protein],
Required_Overlap_Peptides_per_Overlap_Protein AS [Req Overlap Peptides per Overlap Protein],
Run_Interval AS [Run Interval], Repeat_Count AS [Repeat Count], State, 
State_Description AS [State Description], Output_Form AS [Email Recipients], Comment
FROM T_Peptide_Synopsis_Reports INNER JOIN
 T_Peptide_Synopsis_Reports_State ON State = State_ID

GO
