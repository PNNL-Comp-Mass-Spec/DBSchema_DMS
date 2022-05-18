/****** Object:  View [dbo].[V_LC_Cart_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_LC_Cart_Picklist
As
SELECT ID, Cart_Name As Name
FROM T_LC_Cart
WHERE Cart_State_ID = 2


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Picklist] TO [DDL_Viewer] AS [dbo]
GO
