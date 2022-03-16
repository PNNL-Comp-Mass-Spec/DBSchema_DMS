/****** Object:  View [dbo].[V_Operations_Tasks_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Tasks_List_Report]
AS
SELECT  OpsTask.ID,
        OpsTask.Tab,
        OpsTask.Description,
        OpsTask.Assigned_Personnel AS [Assigned Personnel],
        OpsTask.Comments,
        OpsTask.Status,
        OpsTask.Priority,
        OpsTask.Hours_Spent,
        CASE WHEN OpsTask.Status IN ('Completed', 'Not Implemented') 
             THEN DATEDIFF(DAY, OpsTask.Created, OpsTask.Closed) 
             ELSE DATEDIFF(DAY, OpsTask.Created, GETDATE()) END AS Days_In_Queue,
        OpsTask.Work_Package,
        OpsTask.Created,
        OpsTask.Closed,
        Case 
            When OpsTask.Status In ('Completed', 'Not Implemented') Then 0     -- Request is complete or closed
            When DATEDIFF(DAY, OpsTask.Created, GETDATE()) <= 30 Then    30    -- Request is 0 to 30 days old
            When DATEDIFF(DAY, OpsTask.Created, GETDATE()) <= 60 Then    60    -- Request is 30 to 60 days old
            When DATEDIFF(DAY, OpsTask.Created, GETDATE()) <= 90 Then    90    -- Request is 60 to 90 days old
            Else 120                                -- Request is over 90 days old
        End
        AS #Age_Bracket    
FROM T_Operations_Tasks OpsTask

GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Tasks_List_Report] TO [DDL_Viewer] AS [dbo]
GO
