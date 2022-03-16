/****** Object:  View [dbo].[V_Operations_Tasks_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Tasks_Detail_Report]
AS
SELECT  ID,
        Tab,
        Description,
        Requester,
        Requested_Personnel AS [Requested Personnel],
        Assigned_Personnel AS [Assigned Personnel],
        Comments,
        Hours_Spent,
        Status,
        Priority,
        Work_Package,
        CASE WHEN Status IN ('Completed', 'Not Implemented') THEN DATEDIFF(DAY, Created, Closed) ELSE DATEDIFF(DAY, Created, GETDATE()) END AS Days_In_Queue,
        Created,
        Closed
FROM    T_Operations_Tasks

GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Tasks_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
