/****** Object:  View [dbo].[V_Operations_Tasks_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Tasks_Detail_Report]
AS
SELECT OpsTask.id,
       TaskType.Task_Type_Name As task_type,
       OpsTask.task,
       OpsTask.description,
       OpsTask.requester,
       OpsTask.Requested_Personnel AS requested_personnel,
       OpsTask.Assigned_Personnel AS assigned_personnel,
       OpsTask.comments,
       L.Lab_Name AS lab,
       OpsTask.status,
       OpsTask.priority,
       OpsTask.work_package,
       CASE
           WHEN OpsTask.Status IN ('Completed', 'Not Implemented') THEN DATEDIFF(DAY, OpsTask.created, OpsTask.Closed)
           ELSE DATEDIFF(DAY, OpsTask.created, GETDATE())
       END AS days_in_queue,
       OpsTask.created,
       OpsTask.closed
FROM T_Operations_Tasks OpsTask
     INNER JOIN T_Operations_Task_Type TaskType
       ON OpsTask.Task_Type_ID = TaskType.Task_Type_ID
     INNER JOIN T_Lab_Locations L
       ON OpsTask.Lab_ID = L.Lab_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Tasks_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
