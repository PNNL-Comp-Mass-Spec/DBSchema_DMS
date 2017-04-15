/****** Object:  View [dbo].[V_LC_Cart_Config_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Config_Export]
AS
SELECT Config.Cart_Config_ID,
       Config.Cart_Config_Name,
       Cart.Cart_Name,
       Config.Description,
       Config.Autosampler,
       Config.Pumps,
	   Dataset_Usage_Count,
	   Dataset_Usage_Last_Year,
       Config.Cart_Config_State
FROM T_LC_Cart_Configuration Config
     INNER JOIN T_LC_Cart Cart
       ON Config.Cart_ID = Cart.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Config_Export] TO [DDL_Viewer] AS [dbo]
GO
