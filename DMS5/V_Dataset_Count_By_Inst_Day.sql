/****** Object:  View [dbo].[V_Dataset_Count_By_Inst_Day] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Count_By_Inst_Day
AS
SELECT TOP 100 PERCENT DATEPART(dd, created) AS day, 
   DATEPART(mm, created) AS month, DATEPART(yy, created) 
   AS year, instrument, COUNT(*) AS Total
FROM v_dataset_detail_report
GROUP BY DATEPART(dd, created), DATEPART(mm, created), 
   DATEPART(yy, created), instrument
ORDER BY instrument, year, month, day

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Count_By_Inst_Day] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Count_By_Inst_Day] TO [PNL\D3M580] AS [dbo]
GO
