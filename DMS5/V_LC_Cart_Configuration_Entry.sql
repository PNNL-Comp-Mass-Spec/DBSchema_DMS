/****** Object:  View [dbo].[V_LC_Cart_Configuration_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Configuration_Entry]
AS
SELECT Config.ID,
       Cart.Cart_Name AS Cart,
       Config.Pumps,
       Config.[Columns],
       Config.Traps,
       Config.Mobile_Phase,
       Config.Injection,
       Config.Gradient,
       Config.[Comment]
FROM T_LC_Cart_Configuration Config
     INNER JOIN T_LC_Cart Cart
       ON Config.Cart_ID = Cart.ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Configuration_Entry] TO [DDL_Viewer] AS [dbo]
GO
