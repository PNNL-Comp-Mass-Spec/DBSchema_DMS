/****** Object:  View [dbo].[V_Pipeline_Jobs_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Jobs_History_Detail_Report]
AS
SELECT J.Job,
       J.Priority,
       J.Script,
       JSN.Name AS Job_State,
       J.State AS Job_State_ID,
       ISNULL(JS.Steps, 0) AS Steps,
       J.Dataset,
       J.Results_Folder_Name,
       J.Imported,
       J.Start,
       J.Finish,
       CONVERT(varchar(MAX), JP.Parameters) AS Parameters
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
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Jobs_History_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
