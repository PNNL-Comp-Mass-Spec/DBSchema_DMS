/****** Object:  View [dbo].[V_Analysis_Job_Completed_Count_Tool_by_day] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Completed_Count_Tool_by_day
AS
SELECT TOP 100 PERCENT CONVERT(datetime, CONVERT(varchar(24), m) + '/' + CONVERT(varchar(24), d) + '/' + CONVERT(varchar(24), y)) AS date, COUNT(*) 
               AS [Number of Analysis Jobs Completed], Tool
FROM  dbo.V_Analysis_date_completed
WHERE (state = 4)
GROUP BY y, m, d, Tool
ORDER BY Tool, y, m, d

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Completed_Count_Tool_by_day] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Completed_Count_Tool_by_day] TO [PNL\D3M580] AS [dbo]
GO
