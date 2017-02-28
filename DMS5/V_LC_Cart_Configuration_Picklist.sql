/****** Object:  View [dbo].[V_LC_Cart_Configuration_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Configuration_Picklist]
AS
SELECT Config.Cart_Config_Name AS [Name],
       Config.Description AS [Desc],
       ISNULL(Config.Dataset_Usage_Last_Year, 0) AS [Dataset Count],
	   ISNULL(Config.Dataset_Usage_Count, 0) AS [Datasets (all time)],
       Cart.Cart_Name AS Cart,
	   Config.Cart_Config_ID AS ID,
	   CASE WHEN ISNULL(Config.Dataset_Usage_Count, 0) > 0 THEN Config.Dataset_Usage_Count + 1000000 ELSE ISNULL(Config.Dataset_Usage_Last_Year, 0) END as SortKey
FROM dbo.T_LC_Cart_Configuration Config
      INNER JOIN T_LC_Cart Cart
       ON Config.Cart_ID = Cart.ID
WHERE (Config.Cart_Config_State = 'Active')


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Configuration_Picklist] TO [DDL_Viewer] AS [dbo]
GO
