/****** Object:  View [dbo].[V_Operations_Tasks_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Tasks_Detail_Report]
AS
SELECT  ID ,
        Tab ,
        Description ,
        Assigned_Personal AS [Assigned Personal] ,
        Comments ,
        Status ,
        Priority ,
        CASE WHEN Status IN ('Completed', 'Not Implemented') THEN DATEDIFF(DAY, Created, Closed) ELSE DATEDIFF(DAY, Created, GETDATE()) END  AS Days_In_Queue ,
        Requestor ,
        Requested_Personal AS [Requested Personal] ,
        Work_Package ,
        Created,
        Closed
FROM    T_Operations_Tasks

GO
