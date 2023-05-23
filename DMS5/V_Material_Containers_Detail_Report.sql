/****** Object:  View [dbo].[V_Material_Containers_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Material_Containers_Detail_Report]
AS
SELECT container,
       type,
       location,
       items,
       comment,
       freezer,
       dbo.get_material_container_campaign_list(Container_ID, Items) AS campaigns,
       barcode,
       created,
       status,
       researcher,
       files
FROM ( SELECT MC.Tag AS Container,
              MC.Type,
              ML.Tag AS Location,
              COUNT(ContentsQ.Material_ID) AS Items,
              MC.Comment,
              ML.Freezer_Tag AS Freezer,
              MC.Barcode,
              MC.Created,
              MC.Status,
              MC.Researcher,
              TFA.Files,
              MC.ID AS Container_ID
       FROM T_Material_Containers MC
            LEFT OUTER JOIN (SELECT CC_Container_ID AS Container_ID,
                                    CC_ID AS Material_ID
                             FROM T_Cell_Culture
                             WHERE CC_Material_Active = 'Active'
                             UNION
                             SELECT EX_Container_ID AS Container_ID,
                                    Exp_ID AS Material_ID
                             FROM T_Experiments
                             WHERE Ex_Material_Active = 'Active'
                             UNION
                             SELECT Container_ID AS Container_ID,
                                    Compound_ID AS Material_ID
                             FROM T_Reference_Compound
                             WHERE Active > 0
                            ) AS ContentsQ
              ON ContentsQ.Container_ID = MC.ID
            LEFT OUTER JOIN ( SELECT Entity_ID,
                                     COUNT(*) AS Files
                              FROM T_File_Attachment
                              WHERE Entity_Type = 'material_container' AND
                                    Active > 0 AND
                                    -- Exclude the staging containers because they have thousands of items,
                                    -- leading to slow query times on the Material Container Detail Report
                                    -- when this query looks for a file attachment associated with every container in the staging location
                                    Entity_ID <> 'na' AND
                                    Entity_ID NOT LIKE '%Staging%'
                              GROUP BY Entity_ID
                            ) AS TFA
              ON TFA.Entity_ID = MC.Tag
            INNER JOIN T_Material_Locations ML
              ON MC.Location_ID = ML.ID
       GROUP BY MC.Tag, MC.Type, ML.Tag, MC.Comment, MC.Barcode, MC.Created, MC.Status,
                MC.Researcher, ML.Freezer_Tag, TFA.Files, MC.ID
     ) ContainerQ

GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Containers_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
