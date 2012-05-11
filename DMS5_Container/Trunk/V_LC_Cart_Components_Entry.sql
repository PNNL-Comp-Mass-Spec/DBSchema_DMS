/****** Object:  View [dbo].[V_LC_Cart_Components_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Components_Entry
AS
SELECT     dbo.T_LC_Cart_Components.ID, dbo.T_LC_Cart_Component_Type.Type, dbo.T_LC_Cart_Components.Status, dbo.T_LC_Cart_Components.Description, 
                      dbo.T_LC_Cart_Components.Manufacturer, dbo.T_LC_Cart_Components.Part_Number AS PartNumber, 
                      dbo.T_LC_Cart_Components.Serial_Number AS SerialNumber, dbo.T_LC_Cart_Components.Property_Number AS PropertyNumber, 
                      dbo.T_LC_Cart_Components.Comment, dbo.T_LC_Cart.Cart_Name AS CartName, dbo.T_LC_Cart_Positions.Name AS PositionName
FROM         dbo.T_LC_Cart INNER JOIN
                      dbo.T_LC_Cart_Component_Postition ON dbo.T_LC_Cart.ID = dbo.T_LC_Cart_Component_Postition.Cart_ID INNER JOIN
                      dbo.T_LC_Cart_Positions ON dbo.T_LC_Cart_Component_Postition.Position_ID = dbo.T_LC_Cart_Positions.ID RIGHT OUTER JOIN
                      dbo.T_LC_Cart_Component_Type INNER JOIN
                      dbo.T_LC_Cart_Components ON dbo.T_LC_Cart_Component_Type.ID = dbo.T_LC_Cart_Components.Type ON 
                      dbo.T_LC_Cart_Component_Postition.ID = dbo.T_LC_Cart_Components.Component_Position

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Components_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Components_Entry] TO [PNL\D3M580] AS [dbo]
GO
