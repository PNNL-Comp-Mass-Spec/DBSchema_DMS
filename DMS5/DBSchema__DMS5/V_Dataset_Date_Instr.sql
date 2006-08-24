/****** Object:  View [dbo].[V_Dataset_Date_Instr] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Date_Instr
AS
SELECT Dataset, { fn YEAR(Created) } AS year, { fn MONTH(Created) } AS month, DAY(Created) AS day, Instrument, [Inst class]
FROM  dbo.V_Dataset_Detail_Report

GO
