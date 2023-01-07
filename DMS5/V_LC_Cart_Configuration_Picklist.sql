/****** Object:  View [dbo].[V_LC_Cart_Configuration_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Configuration_Picklist]
AS
SELECT Config.Cart_Config_Name AS name,
       Config.description,
       ISNULL(Config.dataset_usage_last_year, 0) AS dataset_count,
	   ISNULL(Config.dataset_usage_count, 0) AS datasets_all_time,
       Cart.Cart_Name AS cart,
	   Config.Cart_Config_ID AS id,
	   CASE WHEN ISNULL(Config.dataset_usage_count, 0) > 0 THEN Config.Dataset_Usage_Count + 1000000 ELSE ISNULL(Config.dataset_usage_last_year, 0) END AS sort_key
FROM dbo.T_LC_Cart_Configuration Config
      INNER JOIN T_LC_Cart Cart
       ON Config.Cart_ID = Cart.ID
WHERE (Config.Cart_Config_State = 'Active')


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Configuration_Picklist] TO [DDL_Viewer] AS [dbo]
GO
