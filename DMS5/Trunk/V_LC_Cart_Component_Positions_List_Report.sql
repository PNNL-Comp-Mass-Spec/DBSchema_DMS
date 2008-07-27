/****** Object:  View [dbo].[V_LC_Cart_Component_Positions_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Component_Positions_List_Report
AS
SELECT     dbo.T_LC_Cart_Component_Postition.ID, dbo.T_LC_Cart.Cart_Name AS Cart, dbo.T_LC_Cart_Positions.Name AS Position, 
                      dbo.T_LC_Cart_Component_Type.Type, dbo.T_LC_Cart_Components.ID AS [Comp. ID], 
                      CASE WHEN NOT Traceable_By_Serial_Number = 'N' THEN 'Replace' ELSE '' END AS Replace, CASE WHEN NOT T_LC_Cart_Components.ID IS NULL 
                      THEN 'Add Note' ELSE '' END AS Service, dbo.T_LC_Cart_Components.Description, dbo.T_LC_Cart_Components.Manufacturer, 
                      dbo.T_LC_Cart_Components.Part_Number, dbo.T_LC_Cart_Components.Serial_Number, dbo.T_LC_Cart_Components.Property_Number, 
                      dbo.T_LC_Cart_Components.Comment, dbo.T_LC_Cart_Components.Starting_Date, dbo.T_LC_Cart_Components.Status
FROM         dbo.T_LC_Cart_Component_Type INNER JOIN
                      dbo.T_LC_Cart_Component_Postition INNER JOIN
                      dbo.T_LC_Cart ON dbo.T_LC_Cart_Component_Postition.Cart_ID = dbo.T_LC_Cart.ID INNER JOIN
                      dbo.T_LC_Cart_Positions ON dbo.T_LC_Cart_Component_Postition.Position_ID = dbo.T_LC_Cart_Positions.ID ON 
                      dbo.T_LC_Cart_Component_Type.ID = dbo.T_LC_Cart_Positions.Component_Type LEFT OUTER JOIN
                      dbo.T_LC_Cart_Components ON dbo.T_LC_Cart_Component_Postition.ID = dbo.T_LC_Cart_Components.Component_Position

GO
