/****** Object:  View [dbo].[V_Biomaterial_Count_by_Month] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Biomaterial_Count_by_Month]
AS
SELECT year, month, COUNT(*) 
   AS [Number of Cell Cultures Created], CONVERT(varchar(24), 
   month) + '/' + CONVERT(varchar(24), year) AS Date
FROM dbo.V_Biomaterial_Date
GROUP BY year, month


GO
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_Count_by_Month] TO [DDL_Viewer] AS [dbo]
GO
