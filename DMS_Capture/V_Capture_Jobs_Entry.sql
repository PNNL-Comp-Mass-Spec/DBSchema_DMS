/****** Object:  View [dbo].[V_Capture_Jobs_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Capture_Jobs_Entry
AS
SELECT  dbo.T_Tasks.job,
        dbo.T_Tasks.priority,
        dbo.T_Tasks.Script AS script_name,
        dbo.T_Tasks.Results_Folder_Name AS results_folder_name,
        dbo.T_Tasks.comment,
        CONVERT(VARCHAR(MAX), dbo.T_Task_Parameters.Parameters) AS job_param
FROM    dbo.T_Tasks
        INNER JOIN dbo.T_Task_Parameters ON dbo.T_Tasks.Job = dbo.T_Task_Parameters.Job

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Jobs_Entry] TO [DDL_Viewer] AS [dbo]
GO
