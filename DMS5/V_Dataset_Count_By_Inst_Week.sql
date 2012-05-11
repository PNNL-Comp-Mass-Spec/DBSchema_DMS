/****** Object:  View [dbo].[V_Dataset_Count_By_Inst_Week] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Count_By_Inst_Week
AS
SELECT TOP 100 PERCENT DATEPART(wk, created) AS week, 
   DATEPART(yy, created) AS year, instrument, COUNT(*) 
   AS Total
FROM v_dataset_detail_report
GROUP BY DATEPART(wk, created), DATEPART(yy, created), 
   instrument
ORDER BY instrument, year, week

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Count_By_Inst_Week] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Count_By_Inst_Week] TO [PNL\D3M580] AS [dbo]
GO
