/****** Object:  View [dbo].[V_LC_Cart_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_LC_Cart_Entry
AS
SELECT C.id,
       C.cart_name,
       SN.Name AS cart_state,
       C.cart_description
FROM T_LC_Cart C
     INNER JOIN T_LC_Cart_State_Name SN
       ON C.Cart_State_ID = SN.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Entry] TO [DDL_Viewer] AS [dbo]
GO
