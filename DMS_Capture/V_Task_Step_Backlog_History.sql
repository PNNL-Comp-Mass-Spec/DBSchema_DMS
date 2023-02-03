/****** Object:  View [dbo].[V_Task_Step_Backlog_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Task_Step_Backlog_History]
AS
SELECT step_tool,
       posting_time,
       SUM(Step_Count) AS backlog_count
FROM dbo.T_Job_Step_Status_History
WHERE State IN (2, 4)
GROUP BY Step_Tool, Posting_Time


GO
GRANT VIEW DEFINITION ON [dbo].[V_Task_Step_Backlog_History] TO [DDL_Viewer] AS [dbo]
GO
