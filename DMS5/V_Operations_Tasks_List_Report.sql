/****** Object:  View [dbo].[V_Operations_Tasks_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Tasks_List_Report]
AS
SELECT OpsTask.id,
       TaskType.Task_Type_Name As task_type,
       OpsTask.task,
       OpsTask.description,
       IsNull(U.name_with_prn, OpsTask.Requester) AS requester,
       OpsTask.Assigned_Personnel AS assigned_personnel,
       OpsTask.comments,
       L.Lab_Name As lab,
       OpsTask.status,
       OpsTask.priority,
       CASE
           WHEN OpsTask.Status IN ('Completed', 'Not Implemented') THEN
                DATEDIFF(DAY, OpsTask.created, OpsTask.Closed)
           ELSE DATEDIFF(DAY, OpsTask.created, GETDATE())
       END AS days_in_queue,
       OpsTask.work_package,
       OpsTask.created,
       OpsTask.closed,
       CASE
           WHEN OpsTask.Status IN ('Completed', 'Not Implemented') THEN 0  -- Request is complete or closed
           WHEN DATEDIFF(DAY, OpsTask.created, GETDATE()) <= 30 THEN 30    -- Request is 0 to 30 days old
           WHEN DATEDIFF(DAY, OpsTask.created, GETDATE()) <= 60 THEN 60    -- Request is 30 to 60 days old
           WHEN DATEDIFF(DAY, OpsTask.created, GETDATE()) <= 90 THEN 90    -- Request is 60 to 90 days old
           ELSE 120                                                        -- Request is over 90 days old
       END AS age_bracket
FROM T_Operations_Tasks OpsTask
     INNER JOIN T_Operations_Task_Type TaskType
       ON OpsTask.Task_Type_ID = TaskType.task_type_id
     INNER JOIN T_Lab_Locations L
       ON OpsTask.Lab_ID = L.lab_id
     LEFT OUTER JOIN T_Users U
       ON OpsTask.Requester = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Tasks_List_Report] TO [DDL_Viewer] AS [dbo]
GO
