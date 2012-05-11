/****** Object:  View [dbo].[V_Material_Containers_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Material_Containers_Detail_Report as 
SELECT        dbo.T_Material_Containers.Tag AS Container, dbo.T_Material_Containers.Type, dbo.T_Material_Locations.Tag AS Location, COUNT(T.M_ID) AS Items, 
                         dbo.T_Material_Containers.Comment, dbo.T_Material_Containers.Barcode, dbo.T_Material_Containers.Created, dbo.T_Material_Containers.Status, 
                         dbo.T_Material_Containers.Researcher
FROM            dbo.T_Material_Containers LEFT OUTER JOIN
                             (SELECT        CC_Container_ID AS C_ID, CC_ID AS M_ID
                               FROM            dbo.T_Cell_Culture
                               UNION
                               SELECT        EX_Container_ID AS C_ID, Exp_ID AS M_ID
                               FROM            dbo.T_Experiments) AS T ON T.C_ID = dbo.T_Material_Containers.ID INNER JOIN
                         dbo.T_Material_Locations ON dbo.T_Material_Containers.Location_ID = dbo.T_Material_Locations.ID
GROUP BY dbo.T_Material_Containers.Tag, dbo.T_Material_Containers.Type, dbo.T_Material_Locations.Tag, dbo.T_Material_Containers.Comment, 
                         dbo.T_Material_Containers.Barcode, dbo.T_Material_Containers.Created, dbo.T_Material_Containers.Status, dbo.T_Material_Containers.Researcher

GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Containers_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Containers_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
