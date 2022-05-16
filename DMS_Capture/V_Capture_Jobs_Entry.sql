/****** Object:  View [dbo].[V_Capture_Jobs_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Capture_Jobs_Entry
AS
SELECT  dbo.T_Jobs.job,
        dbo.T_Jobs.priority,
        dbo.T_Jobs.Script AS script_name,
        dbo.T_Jobs.Results_Folder_Name AS results_folder_name,
        dbo.T_Jobs.comment,
        CONVERT(VARCHAR(MAX), dbo.T_Job_Parameters.Parameters) AS job_param
FROM    dbo.T_Jobs
        INNER JOIN dbo.T_Job_Parameters ON dbo.T_Jobs.Job = dbo.T_Job_Parameters.Job

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Jobs_Entry] TO [DDL_Viewer] AS [dbo]
GO
