/****** Object:  View [dbo].[V_LC_Cart_Components_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Components_List_Report
AS
SELECT     dbo.T_LC_Cart_Components.ID, 'Add Note' AS Service, 'Show History' AS History, dbo.T_LC_Cart_Component_Type.Type, 
                      dbo.T_LC_Cart_Components.Status, dbo.T_LC_Cart_Components.Description, dbo.T_LC_Cart_Components.Manufacturer, 
                      dbo.T_LC_Cart_Components.Part_Number AS [Part Number], dbo.T_LC_Cart_Components.Serial_Number AS [Serial Number], 
                      dbo.T_LC_Cart_Components.Property_Number AS [Property Number], dbo.T_LC_Cart_Components.Comment, dbo.T_LC_Cart.Cart_Name, 
                      dbo.T_LC_Cart_Positions.Name, dbo.T_LC_Cart_Components.Starting_Date
FROM         dbo.T_LC_Cart INNER JOIN
                      dbo.T_LC_Cart_Component_Postition ON dbo.T_LC_Cart.ID = dbo.T_LC_Cart_Component_Postition.Cart_ID INNER JOIN
                      dbo.T_LC_Cart_Positions ON dbo.T_LC_Cart_Component_Postition.Position_ID = dbo.T_LC_Cart_Positions.ID RIGHT OUTER JOIN
                      dbo.T_LC_Cart_Component_Type INNER JOIN
                      dbo.T_LC_Cart_Components ON dbo.T_LC_Cart_Component_Type.ID = dbo.T_LC_Cart_Components.Type ON 
                      dbo.T_LC_Cart_Component_Postition.ID = dbo.T_LC_Cart_Components.Component_Position

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Components_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Components_List_Report] TO [PNL\D3M580] AS [dbo]
GO
