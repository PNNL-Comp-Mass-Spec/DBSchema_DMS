/****** Object:  View [dbo].[V_Peptide_Synopsis_Reports] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW V_Peptide_Synopsis_Reports
AS
SELECT     dbo.T_Peptide_Synopsis_Reports.Report_ID, dbo.T_Peptide_Synopsis_Reports.Name, dbo.T_Peptide_Synopsis_Reports.Description, 
                      dbo.T_Peptide_Synopsis_Reports_Sorting.Report_Sort_Value, dbo.T_Peptide_Synopsis_Reports_Sorting.Report_Sort_Comment, 
                      dbo.T_Peptide_Synopsis_Reports.Dataset_Match_List, dbo.T_Peptide_Synopsis_Reports.Instrument_Match_List, 
                      dbo.T_Peptide_Synopsis_Reports.Param_File_Match_List, dbo.T_Peptide_Synopsis_Reports.Fasta_File_Match_List, 
                      dbo.T_Peptide_Synopsis_Reports.Comparison_Job_Number, dbo.T_Peptide_Synopsis_Reports.Scrolling_Dataset_Dates, 
                      dbo.T_Peptide_Synopsis_Reports.Scrolling_Dataset_Time_Frame, dbo.T_Peptide_Synopsis_Reports.Dataset_Start_Date, 
                      dbo.T_Peptide_Synopsis_Reports.Dataset_End_Date, dbo.T_Peptide_Synopsis_Reports.Scrolling_Job_Dates, 
                      dbo.T_Peptide_Synopsis_Reports.Scrolling_Job_Time_Frame, dbo.T_Peptide_Synopsis_Reports.Job_Start_Date, 
                      dbo.T_Peptide_Synopsis_Reports.Job_End_Date, dbo.T_Peptide_Synopsis_Reports.Use_Synopsis_Files, 
                      dbo.T_Peptide_Synopsis_Reports.Primary_Filter_ID, dbo.T_Peptide_Synopsis_Reports.Secondary_Filter_ID, 
                      dbo.T_Peptide_Synopsis_Reports.Required_Primary_Peptides_per_Protein, 
                      dbo.T_Peptide_Synopsis_Reports.Required_PrimaryPlusSecondary_Peptides_per_Protein, 
                      dbo.T_Peptide_Synopsis_Reports.Required_Overlap_Peptides_per_Overlap_Protein, dbo.T_Peptide_Synopsis_Reports.Run_Interval, 
                      dbo.T_Peptide_Synopsis_Reports.Repeat_Count, dbo.T_Peptide_Synopsis_Reports.State, dbo.T_Peptide_Synopsis_Reports.Output_Form, 
                      dbo.T_Peptide_Synopsis_Reports.Comment, dbo.T_Peptide_Synopsis_Reports_State.State_Description, 
                      dbo.V_Peptide_Synopsis_Report_Runs_Grouped.Last_Run_Date, dbo.V_Peptide_Synopsis_Report_Runs_Grouped.Total_Runs, 
                      dbo.V_Peptide_Synopsis_Report_Runs_Grouped.Last_Successful_Run_Date, 
                      dbo.V_Peptide_Synopsis_Report_Runs_Grouped.Total_Successful_Runs, 
                      dbo.V_Peptide_Synopsis_Report_Runs_Grouped.Last_Successful_Storage_Path, dbo.T_Peptide_Synopsis_Reports.Experiment_Match_List, 
                      dbo.T_Peptide_Synopsis_Reports.Task_Type, dbo.T_Peptide_Synopsis_Reports.Database_Name, dbo.T_Peptide_Synopsis_Reports.Server_Name
FROM         dbo.T_Peptide_Synopsis_Reports INNER JOIN
                      dbo.T_Peptide_Synopsis_Reports_Sorting ON 
                      dbo.T_Peptide_Synopsis_Reports.Report_Sorting = dbo.T_Peptide_Synopsis_Reports_Sorting.Report_Sort_ID INNER JOIN
                      dbo.T_Peptide_Synopsis_Reports_State ON dbo.T_Peptide_Synopsis_Reports.State = dbo.T_Peptide_Synopsis_Reports_State.State_ID INNER JOIN
                      dbo.V_Peptide_Synopsis_Report_Runs_Grouped ON 
                      dbo.T_Peptide_Synopsis_Reports.Report_ID = dbo.V_Peptide_Synopsis_Report_Runs_Grouped.Report_ID

GO
