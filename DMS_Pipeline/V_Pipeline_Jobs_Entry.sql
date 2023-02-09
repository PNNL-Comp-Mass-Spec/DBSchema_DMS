/****** Object:  View [dbo].[V_Pipeline_Jobs_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Jobs_Entry]
AS
SELECT J.Job AS job,
       J.Priority AS priority,
       J.Script AS script_name,
       J.Dataset AS dataset,
       J.Results_Folder_Name AS results_folder_name,
       J.Comment AS comment,
       J.Owner AS owner_username,
       J.DataPkgID as data_package_id,
       Cast(JP.Parameters As varchar(max)) AS job_param
FROM T_Jobs J
     INNER JOIN T_Job_Parameters JP
       ON J.Job = JP.Job

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Jobs_Entry] TO [DDL_Viewer] AS [dbo]
GO
