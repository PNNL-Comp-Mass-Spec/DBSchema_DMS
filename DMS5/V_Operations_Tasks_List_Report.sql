/****** Object:  View [dbo].[V_Operations_Tasks_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Tasks_List_Report]
AS
SELECT OpsTask.ID,
       TaskType.Task_Type_Name As [Task Type],
       OpsTask.Tab,
       OpsTask.Description,
       IsNull(U.Name_with_PRN, OpsTask.Requester) AS Requester,
       OpsTask.Assigned_Personnel AS [Assigned Personnel],
       OpsTask.Comments,
       L.Lab_Name As Lab,
       OpsTask.Status,
       OpsTask.Priority,
       CASE
           WHEN OpsTask.Status IN ('Completed', 'Not Implemented') THEN
             DATEDIFF(DAY, OpsTask.Created, OpsTask.Closed)
           ELSE DATEDIFF(DAY, OpsTask.Created, GETDATE())
       END AS Days_In_Queue,
       OpsTask.Work_Package,
       OpsTask.Created,
       OpsTask.Closed,
       CASE
           WHEN OpsTask.Status IN ('Completed', 'Not Implemented') THEN 0  -- Request is complete or closed
           WHEN DATEDIFF(DAY, OpsTask.Created, GETDATE()) <= 30 THEN 30    -- Request is 0 to 30 days old
           WHEN DATEDIFF(DAY, OpsTask.Created, GETDATE()) <= 60 THEN 60    -- Request is 30 to 60 days old
           WHEN DATEDIFF(DAY, OpsTask.Created, GETDATE()) <= 90 THEN 90    -- Request is 60 to 90 days old
           ELSE 120                                                        -- Request is over 90 days old
       END AS age_bracket
FROM T_Operations_Tasks OpsTask
     INNER JOIN T_Operations_Task_Type TaskType
       ON OpsTask.Task_Type_ID = TaskType.Task_Type_ID
     INNER JOIN T_Lab_Locations L
       ON OpsTask.Lab_ID = L.Lab_ID
     LEFT OUTER JOIN T_Users U
       ON OpsTask.Requester = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Tasks_List_Report] TO [DDL_Viewer] AS [dbo]
GO
