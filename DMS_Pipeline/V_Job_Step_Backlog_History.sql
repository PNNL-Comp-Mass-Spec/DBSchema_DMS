/****** Object:  View [dbo].[V_Job_Step_Backlog_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_Backlog_History]
AS
SELECT Step_Tool,
       Posting_time,
       SUM(Step_Count) AS Backlog_Count
FROM dbo.T_Job_Step_Status_History
WHERE State IN (2, 4)
GROUP BY Step_Tool, Posting_Time


GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_Backlog_History] TO [PNL\D3M578] AS [dbo]
GO
