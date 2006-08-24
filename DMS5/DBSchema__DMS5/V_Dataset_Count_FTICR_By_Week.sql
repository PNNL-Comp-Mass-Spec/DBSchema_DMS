/****** Object:  View [dbo].[V_Dataset_Count_FTICR_By_Week] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Count_FTICR_By_Week
AS
SELECT TOP 100 PERCENT DATEPART(wk, Created) AS week, DATEPART(yy, Created) AS year, COUNT(*) AS Total
FROM  dbo.V_Dataset_Detail_Report
WHERE (Instrument LIKE '%fticr%')
GROUP BY DATEPART(wk, Created), DATEPART(yy, Created)
ORDER BY year, week

GO
