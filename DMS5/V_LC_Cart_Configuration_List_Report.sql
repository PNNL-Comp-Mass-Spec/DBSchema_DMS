/****** Object:  View [dbo].[V_LC_Cart_Configuration_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Configuration_List_Report]
AS
SELECT Config.ID,
       Cart.Cart_Name,
       Config.Pumps,
       Config.[Columns],
       Config.Traps,
       Config.Mobile_Phase,
       Config.Injection,
       Config.Gradient,
       Config.[Comment],
       Config.Entered,
       Config.Entered_By,
       Config.Updated,
	   Config.Updated_By
FROM T_LC_Cart_Configuration Config
     INNER JOIN T_LC_Cart Cart
       ON Config.Cart_ID = Cart.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Configuration_List_Report] TO [DDL_Viewer] AS [dbo]
GO
