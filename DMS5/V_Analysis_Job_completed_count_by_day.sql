/****** Object:  View [dbo].[V_Analysis_Job_Completed_Count_by_Day] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Analysis_Job_completed_count_by_day
AS
SELECT CONVERT(datetime, CONVERT(varchar(24), m) 
   + '/' + CONVERT(varchar(24), d) + '/' + CONVERT(varchar(24), y)) 
   AS date, COUNT(*) 
   AS [Number of Analysis Jobs Completed]
FROM V_Analysis_date_completed
WHERE (state = 4)
GROUP BY y, m, d
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Completed_Count_by_Day] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Completed_Count_by_Day] TO [PNL\D3M580] AS [dbo]
GO
