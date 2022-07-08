/****** Object:  View [dbo].[V_Biomaterial_Date] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Biomaterial_Date]
AS
SELECT     CC_Name As biomaterial_name, { fn YEAR(CC_Created) } AS year, { fn MONTH(CC_Created) } AS month, DAY(CC_Created) AS day
FROM         dbo.T_Cell_Culture


GO
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_Date] TO [DDL_Viewer] AS [dbo]
GO
