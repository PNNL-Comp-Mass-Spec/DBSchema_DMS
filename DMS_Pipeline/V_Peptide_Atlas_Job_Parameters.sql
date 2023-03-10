/****** Object:  View [dbo].[V_Peptide_Atlas_Job_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Peptide_Atlas_Job_Parameters]
AS
	SELECT Job,
	       Parameters,
		   Output_Folder_Name
	FROM (
		SELECT Job,
		       Parameters,
			   Output_Folder_Name,
		       Row_Number() Over (Partition By Job ORDER By HistoryJob) AS RowRank
		FROM (
				SELECT J.Job,
					   P.Parameters,
					   JS.Output_Folder_Name,
					   0 AS HistoryJob
				FROM T_Jobs J
					 INNER JOIN T_Job_Parameters P
					   ON J.Job = P.Job
					 INNER JOIN T_Job_Steps JS
					   ON J.Job = JS.Job
				WHERE J.Script = 'PeptideAtlas' AND
					  JS.Step = 1
				UNION ALL
				SELECT J.Job,
					   P.Parameters,
					   JS.Output_Folder_Name,
					   1 AS HistoryJob
				FROM T_Jobs_History J
					 INNER JOIN T_Job_Parameters_History P
					   ON J.Job = P.Job AND
						  J.Saved = P.Saved
					 INNER JOIN T_Job_Steps_History JS
					   ON J.Job = JS.Job AND
					      J.Saved = JS.Saved
				WHERE J.Script = 'PeptideAtlas' AND
					  JS.Step = 1 AND
					  (J.Most_Recent_Entry = 1)
			) LookupQ
		) SelectionQ
	WHERE SelectionQ.RowRank = 1

GO
GRANT VIEW DEFINITION ON [dbo].[V_Peptide_Atlas_Job_Parameters] TO [DDL_Viewer] AS [dbo]
GO
