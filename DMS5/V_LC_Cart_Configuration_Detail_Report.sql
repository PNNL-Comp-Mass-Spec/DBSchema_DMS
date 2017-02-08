/****** Object:  View [dbo].[V_LC_Cart_Configuration_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Configuration_Detail_Report]
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
       U1.Name_with_PRN AS Entered_By,
       Config.Updated,
       U2.Name_with_PRN AS Updated_By
FROM T_LC_Cart_Configuration Config
     INNER JOIN T_LC_Cart Cart
       ON Config.Cart_ID = Cart.ID
     INNER JOIN T_Users AS U1
       ON Config.Entered_By = U1.U_PRN
     LEFT OUTER JOIN T_Users AS U2
       ON Config.Updated_By = U2.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Configuration_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
