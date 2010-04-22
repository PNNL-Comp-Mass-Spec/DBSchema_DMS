/****** Object:  View [dbo].[V_Peptide_Synopsis_Report_Runs_Grouped] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Peptide_Synopsis_Report_Runs_Grouped
AS
SELECT     dbo.T_Peptide_Synopsis_Reports.Report_ID, Grouped_Runs_All.Last_Run_Date, Grouped_Runs_All.Total_Runs, 
                      dbo.T_Peptide_Synopsis_Report_Runs.Failure AS Last_Run_Failure, Grouped_Runs_Successful.Last_Successful_Run_Date, 
                      Grouped_Runs_Successful.Total_Successful_Runs, T_Peptide_Synopsis_Report_Runs_1.Storage_Path AS Last_Successful_Storage_Path
FROM         dbo.T_Peptide_Synopsis_Reports LEFT OUTER JOIN
                      dbo.T_Peptide_Synopsis_Report_Runs T_Peptide_Synopsis_Report_Runs_1 INNER JOIN
                          (SELECT     Synopsis_Report, MAX(Run_Date) AS Last_Successful_Run_Date, COUNT(*) AS Total_Successful_Runs
                            FROM          T_Peptide_Synopsis_Report_Runs
                            WHERE      Failure = 0
                            GROUP BY Synopsis_Report) Grouped_Runs_Successful ON 
                      T_Peptide_Synopsis_Report_Runs_1.Run_Date = Grouped_Runs_Successful.Last_Successful_Run_Date AND 
                      T_Peptide_Synopsis_Report_Runs_1.Synopsis_Report = Grouped_Runs_Successful.Synopsis_Report ON 
                      Grouped_Runs_Successful.Synopsis_Report = dbo.T_Peptide_Synopsis_Reports.Report_ID LEFT OUTER JOIN
                      dbo.T_Peptide_Synopsis_Report_Runs INNER JOIN
                          (SELECT     Synopsis_Report, MAX(Run_Date) AS Last_Run_Date, COUNT(*) AS Total_Runs
                            FROM          T_Peptide_Synopsis_Report_Runs
                            GROUP BY Synopsis_Report) Grouped_Runs_All ON 
                      dbo.T_Peptide_Synopsis_Report_Runs.Synopsis_Report = Grouped_Runs_All.Synopsis_Report AND 
                      dbo.T_Peptide_Synopsis_Report_Runs.Run_Date = Grouped_Runs_All.Last_Run_Date ON 
                      dbo.T_Peptide_Synopsis_Reports.Report_ID = Grouped_Runs_All.Synopsis_Report

GO
GRANT VIEW DEFINITION ON [dbo].[V_Peptide_Synopsis_Report_Runs_Grouped] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Peptide_Synopsis_Report_Runs_Grouped] TO [PNL\D3M580] AS [dbo]
GO
