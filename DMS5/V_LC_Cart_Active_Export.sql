/****** Object:  View [dbo].[V_LC_Cart_Active_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Active_Export]
AS
SELECT Cart.ID,
       Cart.Cart_Name,
       Cart.Cart_Description,
       CartState.Name AS [State],
	   Cart.Created
FROM dbo.T_LC_Cart AS Cart
     INNER JOIN dbo.T_LC_Cart_State_Name AS CartState
       ON Cart.Cart_State_ID = CartState.ID
WHERE Cart.ID > 1 AND
      Not CartState.Name In ('Retired')


GO
