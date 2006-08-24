/****** Object:  View [dbo].[V_Cell_Culture_Date] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Cell_Culture_Date
AS
SELECT     CC_Name, { fn YEAR(CC_Created) } AS year, { fn MONTH(CC_Created) } AS month, DAY(CC_Created) AS day
FROM         dbo.T_Cell_Culture


GO
