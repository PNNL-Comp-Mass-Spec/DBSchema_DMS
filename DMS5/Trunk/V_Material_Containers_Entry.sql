/****** Object:  View [dbo].[V_Material_Containers_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Material_Containers_Entry
AS
SELECT     dbo.T_Material_Containers.Tag AS Container, dbo.T_Material_Containers.Type, dbo.T_Material_Locations.Tag AS Location, 
                      dbo.T_Material_Containers.Status, dbo.T_Material_Containers.Comment, dbo.T_Material_Containers.Barcode
FROM         dbo.T_Material_Containers INNER JOIN
                      dbo.T_Material_Locations ON dbo.T_Material_Containers.Location_ID = dbo.T_Material_Locations.ID

GO
