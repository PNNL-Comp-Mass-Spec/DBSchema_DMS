/****** Object:  View [dbo].[V_LC_Cart_Component_Service_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Component_Service_Entry
AS
SELECT     dbo.T_LC_Cart_Components.ID AS ComponentID, dbo.T_LC_Cart_Component_Type.Type, dbo.T_LC_Cart_Components.Status, 
                      dbo.T_LC_Cart_Components.Description, dbo.T_LC_Cart_Components.Manufacturer, dbo.T_LC_Cart_Components.Part_Number AS PartNumber, 
                      dbo.T_LC_Cart_Components.Serial_Number AS SerialNumber, dbo.T_LC_Cart_Components.Property_Number AS PropertyNumber, '' AS Comment, 
                      '' AS Action
FROM         dbo.T_LC_Cart_Components INNER JOIN
                      dbo.T_LC_Cart_Component_Type ON dbo.T_LC_Cart_Components.Type = dbo.T_LC_Cart_Component_Type.ID

GO
