/****** Object:  View [dbo].[V_Tasks_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Tasks_History_Detail_Report]
AS
SELECT J.job,
       J.priority,
       J.script,
       JSN.Name AS job_state,
       J.State AS job_state_id,
       ISNULL(JS.Steps, 0) AS steps,
       J.dataset,
       J.results_folder_name,
       J.imported,
       J.start,
       J.finish,
       CONVERT(varchar(MAX), JP.Parameters) AS parameters
FROM dbo.T_Jobs_History AS J
     INNER JOIN dbo.T_Job_State_Name AS JSN
       ON J.State = JSN.ID
     LEFT OUTER JOIN dbo.T_Job_Parameters_History AS JP
       ON J.Job = JP.Job AND JP.Most_Recent_Entry = 1
     LEFT OUTER JOIN ( SELECT Job,
                              COUNT(*) Steps
                       FROM T_Job_Steps_History
                       WHERE Most_Recent_Entry = 1
                       GROUP BY Job ) JS
       ON J.Job = JS.Job
WHERE J.Most_Recent_Entry = 1


GO
GRANT VIEW DEFINITION ON [dbo].[V_Tasks_History_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
