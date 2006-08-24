/****** Object:  View [dbo].[V_Qrollup_Report_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create       VIEW V_Qrollup_Report_List_Report
AS
SELECT  Report_ID AS ID, Name, Description, Dataset_Match_List AS [Dataset],
  Experiment_Match_List AS [Experiment], Comparison_Job_Number AS [Comparison QID Number], 
  Repeat_Count AS [Repeat Count], State_Description, Output_Form AS [Email Recipients], Comment, MAX(Storage_Path) AS [Storage_Path]
FROM T_Peptide_Synopsis_Reports 
  LEFT JOIN T_Peptide_Synopsis_Reports_State ON State = State_ID 
  LEFT JOIN T_Peptide_Synopsis_Report_Runs ON Report_ID = Synopsis_Report
WHERE Task_Type = 'QRollup'
GROUP BY Report_ID, Name, Description, Dataset_Match_List, Experiment_Match_List, Comparison_Job_Number, 
  Repeat_Count, State_Description, Output_Form, Comment

GO
