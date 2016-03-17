/****** Object:  View [dbo].[V_Analysis_Job_Scheduled_Count_by_Day] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Analysis_Job_scheduled_count_by_day
AS
SELECT CONVERT(datetime, CONVERT(varchar(24), m) 
   + '/' + CONVERT(varchar(24), d) + '/' + CONVERT(varchar(24), y)) 
   AS date, COUNT(*) 
   AS [Number of Analysis Jobs Scheduled]
FROM V_Analysis_date_scheduled
WHERE (state = 4)
GROUP BY y, m, d
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Scheduled_Count_by_Day] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Scheduled_Count_by_Day] TO [PNL\D3M580] AS [dbo]
GO
