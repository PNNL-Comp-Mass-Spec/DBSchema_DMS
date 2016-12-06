/****** Object:  View [dbo].[V_Pipeline_Jobs_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Pipeline_Jobs_Entry as
SELECT J.Job AS job,
       J.Priority AS priority,
       J.Script AS scriptName,
       J.Dataset AS datasetNum,
       J.Results_Folder_Name AS resultsFolderName,
       J.[Comment] AS [comment],
       J.Owner AS [ownerPRN],
       J.DataPkgID as DataPackageID,
       CONVERT(varchar(MAX),  JP.Parameters) AS jobParam
FROM T_Jobs J
     INNER JOIN T_Job_Parameters JP
       ON J.Job = JP.Job

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Jobs_Entry] TO [DDL_Viewer] AS [dbo]
GO
