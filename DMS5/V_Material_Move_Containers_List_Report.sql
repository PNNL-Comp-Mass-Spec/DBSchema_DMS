/****** Object:  View [dbo].[V_Material_Move_Containers_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Move_Containers_List_Report]
AS
SELECT MC.Tag AS Container,
       '' AS [Sel],
       MC.Type,
       ML.Tag AS Location,
       COUNT(ContentsQ.Material_ID) AS Items,
       MC.Comment,
       -- Unused: MC.Barcode,
       MC.Created,
       MC.ID AS id
FROM dbo.T_Material_Containers MC
     INNER JOIN dbo.T_Material_Locations ML
       ON MC.Location_ID = ML.ID
     LEFT OUTER JOIN ( SELECT   CC_Container_ID AS Container_ID ,
                                CC_ID AS Material_ID
                       FROM     T_Cell_Culture
                       UNION
                       SELECT   EX_Container_ID AS Container_ID ,
                                Exp_ID AS Material_ID
                       FROM     T_Experiments
                       UNION
                       SELECT   Container_ID AS Container_ID ,
                                Compound_ID AS Material_ID
                       FROM     T_Reference_Compound
                    ) AS ContentsQ
       ON ContentsQ.Container_ID = MC.ID
WHERE (MC.Status = 'Active')
GROUP BY MC.Tag, MC.Type, ML.Tag, MC.Comment, MC.Created, MC.Status, MC.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Move_Containers_List_Report] TO [DDL_Viewer] AS [dbo]
GO
