/****** Object:  View [dbo].[V_Analysis_Job_Backlog_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Analysis_Job_Backlog_History
AS
SELECT TOP 100 PERCENT dbo.T_Analysis_Tool.AJT_toolName, 
    dbo.T_Analysis_Job_Status_History.Posting_Time, 
    SUM(dbo.T_Analysis_Job_Status_History.Job_Count) 
    AS Backlog_Count
FROM dbo.T_Analysis_Job_Status_History INNER JOIN
    dbo.T_Analysis_Tool ON 
    dbo.T_Analysis_Job_Status_History.Tool_ID = dbo.T_Analysis_Tool.AJT_toolID
WHERE (dbo.T_Analysis_Job_Status_History.State_ID IN (1, 2, 3, 
    8))
GROUP BY dbo.T_Analysis_Job_Status_History.Posting_Time, 
    dbo.T_Analysis_Tool.AJT_toolName
ORDER BY dbo.T_Analysis_Tool.AJT_toolName, 
    dbo.T_Analysis_Job_Status_History.Posting_Time

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Backlog_History] TO [DDL_Viewer] AS [dbo]
GO
