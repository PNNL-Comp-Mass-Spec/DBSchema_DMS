/****** Object:  View [dbo].[V_Analysis_Job_Est_Duration_Histogram] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW dbo.V_Analysis_Job_Est_Duration_Histogram
AS
SELECT     TOP 100 PERCENT Priority, [Duration], COUNT(*) AS [Number]
FROM
(
	SELECT 
		Priority,
		[Duration] = 
			CASE 
				WHEN [Avg Duration (min.)] IS NULL THEN 'No Estimate' 
				WHEN [Avg Duration (min.)] BETWEEN 0.0 AND 60 THEN '0 - 60 Min'
				WHEN [Avg Duration (min.)] BETWEEN 60 AND 120 THEN '60 - 120 Min' 
				WHEN [Avg Duration (min.)] BETWEEN 120 AND 240 THEN '120 - 240 Min' 
				WHEN [Avg Duration (min.)] BETWEEN 240 AND 480 THEN '240 - 480 Min' 
				WHEN [Avg Duration (min.)] BETWEEN 480 AND 960 THEN '480 - 960 Min' 
				WHEN [Avg Duration (min.)] BETWEEN 960 AND 1940 THEN '960 - 1940 Min' 
				WHEN [Avg Duration (min.)] BETWEEN 1940 AND 3880 THEN '1940 - 3380 Min' 
				WHEN [Avg Duration (min.)] > 1940  THEN 'Maximum'
				ELSE 'Bin 0' 
			END
	FROM          V_Analysis_Job_Duration_Est_New
	WHERE     (Tool = 'Sequest') AND (State = 'New')
) AS x
GROUP BY [Duration], Priority
ORDER BY [Duration], Priority



GO
