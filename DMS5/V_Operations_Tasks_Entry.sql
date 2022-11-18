/****** Object:  View [dbo].[V_Operations_Tasks_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Tasks_Entry]
AS
SELECT OpsTask.id,
       TaskType.task_type_name,
       OpsTask.task,
       OpsTask.requester,
       OpsTask.requested_personnel,
       OpsTask.assigned_personnel,
       OpsTask.description,
       OpsTask.comments,
       L.lab_name,
       OpsTask.status,
       OpsTask.priority,
       OpsTask.work_package
FROM T_Operations_Tasks OpsTask
     INNER JOIN T_Operations_Task_Type TaskType
       ON OpsTask.Task_Type_ID = TaskType.Task_Type_ID
     INNER JOIN T_Lab_Locations L
       ON OpsTask.Lab_ID = L.Lab_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Tasks_Entry] TO [DDL_Viewer] AS [dbo]
GO
