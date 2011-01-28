/****** Object:  View [dbo].[V_Material_Containers_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Material_Containers_List_Report as
SELECT  Container ,
        Type ,
        Location ,
        Items ,
        Comment ,
        'New Biomaterial' AS Action ,
        Barcode ,
        Created ,
        dbo.GetMaterialContainerCampaignList([#ID], Items) AS Campaigns ,
        [#ID]
FROM    ( SELECT    MC.Tag AS Container ,
                    MC.Type ,
                    ML.Tag AS Location ,
                    COUNT(T.C_ID) AS Items ,
                    MC.Comment ,
                    MC.Barcode ,
                    MC.Created ,
                    MC.ID AS [#ID]
          FROM      T_Material_Containers AS MC
                    INNER JOIN T_Material_Locations AS ML ON MC.Location_ID = ML.ID
                    LEFT OUTER JOIN ( SELECT    CC_Container_ID AS C_ID ,
                                                CC_ID AS M_ID
                                      FROM      T_Cell_Culture
                                      UNION
                                      SELECT    EX_Container_ID AS C_ID ,
                                                Exp_ID AS M_ID
                                      FROM      T_Experiments
                                    ) AS T ON T.C_ID = MC.ID
          WHERE     ( MC.Status = 'Active' )
          GROUP BY  MC.Tag ,
                    MC.Type ,
                    ML.Tag ,
                    MC.Comment ,
                    MC.Barcode ,
                    MC.Created ,
                    MC.Status ,
                    MC.ID
        ) AS TZ
GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Containers_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Containers_List_Report] TO [PNL\D3M580] AS [dbo]
GO
