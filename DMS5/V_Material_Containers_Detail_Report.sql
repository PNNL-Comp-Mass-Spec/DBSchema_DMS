/****** Object:  View [dbo].[V_Material_Containers_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 
CREATE VIEW [dbo].[V_Material_Containers_Detail_Report] AS 
SELECT  MC.Tag AS Container ,
        MC.Type ,
        ML.Tag AS Location ,
        COUNT(T.M_ID) AS Items ,
        MC.Comment ,
        MC.Barcode ,
        MC.Created ,
        MC.Status ,
        MC.Researcher,
        TFA.Files
FROM    T_Material_Containers MC
        LEFT OUTER JOIN ( SELECT    CC_Container_ID AS C_ID ,
                                    CC_ID AS M_ID
                          FROM      T_Cell_Culture
                          UNION
                          SELECT    EX_Container_ID AS C_ID ,
                                    Exp_ID AS M_ID
                          FROM      T_Experiments
                        ) AS T ON T.C_ID = MC.ID
        LEFT OUTER JOIN ( SELECT    Entity_ID ,
                                    COUNT(*) AS Files
                          FROM      T_File_Attachment
                          WHERE     ( Entity_Type = 'material_container' )
                                    AND ( Active > 0 )
                          GROUP BY  Entity_ID
                        ) AS TFA ON TFA.Entity_ID = MC.Tag                        
        INNER JOIN T_Material_Locations ML ON MC.Location_ID = ML.ID
GROUP BY MC.Tag ,
        MC.Type ,
        ML.Tag ,
        MC.Comment ,
        MC.Barcode ,
        MC.Created ,
        MC.Status ,
        MC.Researcher,
        TFA.Files
GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Containers_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
