/****** Object:  View [dbo].[V_Operations_Tasks_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Tasks_Detail_Report]
AS
SELECT OpsTask.ID,
       TaskType.Task_Type_Name As [Task Type],
       OpsTask.Tab,
       OpsTask.Description,
       OpsTask.Requester,
       OpsTask.Requested_Personnel AS [Requested Personnel],
       OpsTask.Assigned_Personnel AS [Assigned Personnel],
       OpsTask.Comments,
       L.Lab_Name AS Lab,
       OpsTask.Status,
       OpsTask.Priority,
       OpsTask.Work_Package,
       CASE
           WHEN OpsTask.Status IN ('Completed', 'Not Implemented') THEN DATEDIFF(DAY, OpsTask.Created, OpsTask.Closed)
           ELSE DATEDIFF(DAY, OpsTask.Created, GETDATE())
       END AS Days_In_Queue,
       OpsTask.Created,
       OpsTask.Closed
FROM T_Operations_Tasks OpsTask
     INNER JOIN T_Operations_Task_Type TaskType
       ON OpsTask.Task_Type_ID = TaskType.Task_Type_ID
     INNER JOIN T_Lab_Locations L
       ON OpsTask.Lab_ID = L.Lab_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Tasks_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
