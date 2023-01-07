/****** Object:  View [dbo].[V_Pipeline_Jobs_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Jobs_Detail_Report]
AS
SELECT J.job,
       J.priority,
       J.script,
       JSN.Name AS job_state,
       J.State AS job_state_id,
       ISNULL(JS.steps, 0) AS steps,
       J.dataset,
       AJ.AJ_settingsFileName AS settings_file,
       AJ.AJ_parmFileName AS parameter_file,
       J.comment,
       J.owner,
       J.special_processing,
       J.DataPkgID AS data_package_id,
       J.results_folder_name,
       J.imported,
       J.start,
       J.finish,
       J.runtime_minutes,
       J.transfer_folder_path,
       J.archive_busy,
       CONVERT(varchar(MAX), JP.Parameters) AS parameters
FROM dbo.T_Jobs AS J
     INNER JOIN dbo.T_Job_State_Name AS JSN
       ON J.State = JSN.ID
     INNER JOIN dbo.T_Job_Parameters AS JP
       ON J.Job = JP.Job
     LEFT OUTER JOIN ( SELECT Job,
                              COUNT(*) Steps
                       FROM T_Job_Steps
                       GROUP BY Job ) JS
       ON J.Job = JS.Job
     LEFT OUTER JOIN dbo.S_DMS_T_Analysis_Job AS AJ
       ON J.Job = AJ.AJ_jobID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Jobs_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
