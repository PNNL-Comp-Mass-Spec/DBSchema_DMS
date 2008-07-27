/****** Object:  View [dbo].[V_LC_Cart_Component_Positions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Component_Positions
AS
SELECT     dbo.T_LC_Cart_Component_Postition.ID, dbo.T_LC_Cart.Cart_Name AS Cart, dbo.T_LC_Cart_Positions.Name AS Position, 
                      dbo.T_LC_Cart_Positions.ID AS Position_Code, dbo.T_LC_Cart_Component_Type.Type, dbo.T_LC_Cart_Components.ID AS [Comp. ID], 
                      dbo.T_LC_Cart_Components.Serial_Number, dbo.T_LC_Cart_Components.Starting_Date, 
                      dbo.T_LC_Cart_Component_Type.Traceable_By_Serial_Number
FROM         dbo.T_LC_Cart_Component_Postition INNER JOIN
                      dbo.T_LC_Cart ON dbo.T_LC_Cart_Component_Postition.Cart_ID = dbo.T_LC_Cart.ID INNER JOIN
                      dbo.T_LC_Cart_Positions ON dbo.T_LC_Cart_Component_Postition.Position_ID = dbo.T_LC_Cart_Positions.ID INNER JOIN
                      dbo.T_LC_Cart_Component_Type ON dbo.T_LC_Cart_Positions.Component_Type = dbo.T_LC_Cart_Component_Type.ID LEFT OUTER JOIN
                      dbo.T_LC_Cart_Components ON dbo.T_LC_Cart_Component_Postition.ID = dbo.T_LC_Cart_Components.Component_Position

GO
