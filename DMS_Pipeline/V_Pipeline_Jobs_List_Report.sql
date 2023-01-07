/****** Object:  View [dbo].[V_Pipeline_Jobs_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Jobs_List_Report]
AS
SELECT J.job,
       J.priority,
       J.script,
       JSN.Name AS job_state_b,
       'Steps' AS steps,
       J.dataset,
       J.results_folder_name,
       J.imported,
       J.start,
       J.finish,
       J.runtime_minutes,
       J.DataPkgID AS data_pkg_id,
       J.owner,
       J.transfer_folder_path,
       J.archive_busy,
       J.comment
FROM dbo.T_Jobs J
     INNER JOIN dbo.T_Job_State_Name JSN
       ON J.State = JSN.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Jobs_List_Report] TO [DDL_Viewer] AS [dbo]
GO
