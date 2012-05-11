/****** Object:  View [dbo].[V_Dataset_Count_By_Month_LTQ] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Count_By_Month_LTQ
AS
SELECT TOP 100 PERCENT year, month, COUNT(*) AS [Number of Datasets Created], CONVERT(varchar(24), month) + '/' + CONVERT(varchar(24), year) 
               AS Date
FROM  dbo.V_Dataset_Date_Instr
WHERE (Instrument LIKE '%LTQ%')
GROUP BY year, month
ORDER BY year, month

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Count_By_Month_LTQ] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Count_By_Month_LTQ] TO [PNL\D3M580] AS [dbo]
GO
