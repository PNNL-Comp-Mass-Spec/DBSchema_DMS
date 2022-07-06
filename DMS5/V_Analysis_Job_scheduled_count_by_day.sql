/****** Object:  View [dbo].[V_Analysis_Job_Scheduled_Count_by_Day] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Scheduled_Count_by_Day]
AS
SELECT Cast(AJ_created As Date) As Date, COUNT(*) AS [Number of Analysis Jobs Scheduled]
FROM T_Analysis_Job
WHERE AJ_StateID = 4
GROUP By Cast(AJ_created As Date)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Scheduled_Count_by_Day] TO [DDL_Viewer] AS [dbo]
GO
