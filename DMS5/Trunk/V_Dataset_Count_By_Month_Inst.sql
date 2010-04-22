/****** Object:  View [dbo].[V_Dataset_Count_By_Month_Inst] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Count_By_Month_Inst
AS
SELECT TOP 100 PERCENT year, month, COUNT(*) AS [Number of Datasets Created], CONVERT(varchar(24), month) + '/' + CONVERT(varchar(24), year) 
               AS Date, Instrument
FROM  dbo.V_Dataset_Date_Instr
GROUP BY year, month, Instrument
ORDER BY Instrument, year, month

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Count_By_Month_Inst] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Count_By_Month_Inst] TO [PNL\D3M580] AS [dbo]
GO
