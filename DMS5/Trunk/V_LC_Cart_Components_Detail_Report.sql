/****** Object:  View [dbo].[V_LC_Cart_Components_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Components_Detail_Report
AS
SELECT     dbo.T_LC_Cart_Components.ID, dbo.T_LC_Cart_Component_Type.Type, dbo.T_LC_Cart_Components.Status, dbo.T_LC_Cart_Components.Description, 
                      dbo.T_LC_Cart_Components.Manufacturer, dbo.T_LC_Cart_Components.Part_Number AS [Part Number], 
                      dbo.T_LC_Cart_Components.Serial_Number AS [Serial Number], dbo.T_LC_Cart_Components.Property_Number AS [Property Number], 
                      dbo.T_LC_Cart_Component_Type.Traceable_By_Serial_Number AS [Traceable By Serial Number], dbo.T_LC_Cart_Components.Comment
FROM         dbo.T_LC_Cart_Components INNER JOIN
                      dbo.T_LC_Cart_Component_Type ON dbo.T_LC_Cart_Components.Type = dbo.T_LC_Cart_Component_Type.ID

GO
