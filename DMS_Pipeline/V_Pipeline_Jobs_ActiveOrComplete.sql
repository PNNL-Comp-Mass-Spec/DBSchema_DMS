/****** Object:  View [dbo].[V_Pipeline_Jobs_ActiveOrComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Jobs_ActiveOrComplete]
AS
SELECT J.Job,
       J.Priority,
       J.Script,
       J.[State],
       JSN.Name AS State_Name,
       J.Dataset,
       J.Dataset_ID,
       J.Storage_Server,
       J.Imported,
       J.Start,
       J.Finish,
       SUM(CASE WHEN JS.State IN (2, 4, 5) 
                THEN 1
                ELSE 0
           END) AS Step_Count_ActiveOrComplete
FROM T_Jobs J
     INNER JOIN T_Job_State_Name JSN
       ON J.State = JSN.ID
     LEFT OUTER JOIN T_Job_Steps JS
       ON J.Job = JS.Job
WHERE (J.State IN (0, 1, 2, 3, 7, 8, 9, 14, 20) OR JS.State IN (2, 4, 5))
GROUP BY J.Job, J.Priority, J.Script, J.[State], JSN.Name, 
         J.Dataset, J.Dataset_ID, J.Storage_Server, J.Results_Folder_Name, J.Imported, 
         J.Start, J.Finish


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Jobs_ActiveOrComplete] TO [DDL_Viewer] AS [dbo]
GO
