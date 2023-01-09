/****** Object:  View [dbo].[V_Analysis_Date_Completed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Analysis_date_completed
AS
SELECT dbo.T_Analysis_Job.AJ_jobID AS job,
       dbo.T_Analysis_Job.AJ_StateID AS state,
       { fn YEAR(dbo.T_Analysis_Job.AJ_finish) } AS y,
       { fn MONTH(dbo.T_Analysis_Job.AJ_finish) } AS m,
       day(dbo.T_Analysis_Job.AJ_finish) AS d,
       dbo.T_Analysis_Tool.AJT_toolName AS tool
FROM dbo.T_Analysis_Job INNER JOIN
     dbo.T_Analysis_Tool ON
     dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Date_Completed] TO [DDL_Viewer] AS [dbo]
GO
