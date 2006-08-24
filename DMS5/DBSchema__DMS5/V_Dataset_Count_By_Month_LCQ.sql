/****** Object:  View [dbo].[V_Dataset_Count_By_Month_LCQ] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Count_By_Month_LCQ
AS
SELECT TOP 100 PERCENT year, month, COUNT(*) AS [Number of Datasets Created], CONVERT(varchar(24), month) + '/' + CONVERT(varchar(24), year) 
               AS Date
FROM  dbo.V_Dataset_Date_Instr
WHERE ([Inst class] LIKE '%TOF%') OR
               ([Inst class] LIKE '%Ion_Trap%')
GROUP BY year, month
ORDER BY year, month

GO
