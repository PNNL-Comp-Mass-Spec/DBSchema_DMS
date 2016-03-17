/****** Object:  View [dbo].[V_Analysis_Job_Completed_Count_by_month] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Completed_Count_by_month
AS
SELECT CONVERT(datetime, CONVERT(varchar(24), m) 
   + '/1/' + CONVERT(varchar(24), y)) AS date, COUNT(*) 
   AS [Number of Analysis Jobs Completed]
FROM dbo.V_Analysis_date_completed
WHERE (state = 4)
GROUP BY y, m

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Completed_Count_by_month] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Completed_Count_by_month] TO [PNL\D3M580] AS [dbo]
GO
