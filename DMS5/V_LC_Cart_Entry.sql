/****** Object:  View [dbo].[V_LC_Cart_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create VIEW V_LC_Cart_Entry
AS
SELECT     T_LC_Cart.ID AS ID, T_LC_Cart.Cart_Name AS CartName, T_LC_Cart_State_Name.Name AS CartState, 
                      T_LC_Cart.Cart_Description AS CartDescription
FROM         T_LC_Cart INNER JOIN
                      T_LC_Cart_State_Name ON T_LC_Cart.Cart_State_ID = T_LC_Cart_State_Name.ID

GO
