/****** Object:  View [dbo].[v_Dataset_Count_LCQ_By_Week] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.v_Dataset_Count_LCQ_By_Week
AS
SELECT TOP 100 PERCENT DATEPART(wk, Created) AS week, DATEPART(yy, Created) AS year, COUNT(*) AS Total
FROM  dbo.V_Dataset_Detail_Report
WHERE ([Inst class] LIKE '%TOF%') OR
               ([Inst class] LIKE '%Ion_Trap%')
GROUP BY DATEPART(wk, Created), DATEPART(yy, Created)
ORDER BY year, week

GO
GRANT VIEW DEFINITION ON [dbo].[v_Dataset_Count_LCQ_By_Week] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[v_Dataset_Count_LCQ_By_Week] TO [PNL\D3M580] AS [dbo]
GO
