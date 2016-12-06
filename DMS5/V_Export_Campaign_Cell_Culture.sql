/****** Object:  View [dbo].[V_Export_Campaign_Cell_Culture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Export_Campaign_Cell_Culture
AS
SELECT     dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Cell_Culture.CC_Name AS CellCulture, dbo.T_Cell_Culture.CC_ID
FROM         dbo.T_Campaign INNER JOIN
                      dbo.T_Cell_Culture ON dbo.T_Campaign.Campaign_ID = dbo.T_Cell_Culture.CC_Campaign_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Export_Campaign_Cell_Culture] TO [DDL_Viewer] AS [dbo]
GO
