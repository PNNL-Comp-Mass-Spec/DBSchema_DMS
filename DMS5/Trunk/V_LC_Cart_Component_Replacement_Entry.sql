/****** Object:  View [dbo].[V_LC_Cart_Component_Replacement_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Component_Replacement_Entry
AS
SELECT     dbo.T_LC_Cart_Component_Postition.ID AS PositionID, dbo.T_LC_Cart.Cart_Name AS CartName, dbo.T_LC_Cart_Positions.Name AS PositionName, 
                      dbo.T_LC_Cart_Component_Type.Type AS ComponentType, dbo.T_LC_Cart_Components.ID AS ComponentID, '' AS Comment
FROM         dbo.T_LC_Cart_Component_Postition INNER JOIN
                      dbo.T_LC_Cart_Positions ON dbo.T_LC_Cart_Component_Postition.Position_ID = dbo.T_LC_Cart_Positions.ID INNER JOIN
                      dbo.T_LC_Cart ON dbo.T_LC_Cart_Component_Postition.Cart_ID = dbo.T_LC_Cart.ID INNER JOIN
                      dbo.T_LC_Cart_Component_Type ON dbo.T_LC_Cart_Positions.Component_Type = dbo.T_LC_Cart_Component_Type.ID LEFT OUTER JOIN
                      dbo.T_LC_Cart_Components ON dbo.T_LC_Cart_Component_Postition.ID = dbo.T_LC_Cart_Components.Component_Position

GO
