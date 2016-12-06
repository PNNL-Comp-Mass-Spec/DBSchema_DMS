/****** Object:  View [dbo].[V_Material_Move_Containers_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Material_Move_Containers_List_Report
AS
SELECT MC.Tag AS Container,
       '' AS [Sel.],
       MC.Type,
       ML.Tag AS Location,
       COUNT(T.C_ID) AS Items,
       MC.Comment,
       MC.Barcode,
       MC.Created,
       MC.ID AS [#ID]
FROM dbo.T_Material_Containers MC
     INNER JOIN dbo.T_Material_Locations ML
       ON MC.Location_ID = ML.ID
     LEFT OUTER JOIN (SELECT CC_Container_ID AS C_ID,
                             CC_ID AS M_ID
                      FROM dbo.T_Cell_Culture
                      UNION
                      SELECT EX_Container_ID AS C_ID,
                             Exp_ID AS M_ID
                      FROM dbo.T_Experiments ) AS T
       ON T.C_ID = MC.ID
WHERE (MC.Status = 'Active')
GROUP BY MC.Tag, MC.Type, ML.Tag, MC.Comment, MC.Barcode, MC.Created, MC.Status, MC.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Move_Containers_List_Report] TO [DDL_Viewer] AS [dbo]
GO
