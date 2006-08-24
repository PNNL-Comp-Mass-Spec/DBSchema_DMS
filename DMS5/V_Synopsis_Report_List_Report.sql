/****** Object:  View [dbo].[V_Synopsis_Report_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW V_Synopsis_Report_List_Report
AS
SELECT  Report_ID AS ID, Name, Description, 
  Dataset_Match_List AS [Dataset], Instrument_Match_List AS [Instrument], 
  Param_File_Match_List AS [Param File], Fasta_File_Match_List AS [Fasta File], 
  Comparison_Job_Number AS [Comparison Job], Repeat_Count AS [Repeat Count], State_Description, 
  Output_Form AS [Email Recipients], Comment
FROM T_Peptide_Synopsis_Reports INNER JOIN
 T_Peptide_Synopsis_Reports_State ON State = State_ID 
WHERE Task_Type = 'Synopsis'

GO
