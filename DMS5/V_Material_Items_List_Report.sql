/****** Object:  View [dbo].[V_Material_Items_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Items_List_Report]
AS
SELECT ContentsQ.Item,
       ContentsQ.Item_Type,
       ContentsQ.Material_ID AS ID,
       -- Unused: Containers.Barcode,
       MC.Tag AS Container,
       MC.[Type],
       SUBSTRING(ContentsQ.Item_Type, 1, 1) + ':' + CONVERT(varchar, ContentsQ.Material_ID) AS [#I_ID],  -- ItemID
       ML.Tag AS Location
FROM dbo.T_Material_Containers AS MC
     INNER JOIN (SELECT Experiment_Num AS Item,
                        'Experiment' AS Item_Type,
                        EX_Container_ID AS Container_ID,
                        Exp_ID AS Material_ID
                        -- Unused: EX_Barcode AS Barcode
                 FROM dbo.T_Experiments
                 UNION
                 SELECT CC_Name AS Item,
                        'Biomaterial' AS Item_Type,
                        CC_Container_ID AS Container_ID,
                        CC_ID AS Material_ID
                 FROM dbo.T_Cell_Culture 
                 UNION
                 SELECT Compound_Name AS Item,
                        'RefCompound' AS Item_Type,
                        Container_ID AS Container_ID,
                        Compound_ID AS Material_ID
                 FROM dbo.T_Reference_Compound
                ) AS ContentsQ
       ON ContentsQ.Container_ID = MC.ID
     INNER JOIN dbo.T_Material_Locations AS ML
       ON MC.Location_ID = ML.ID
WHERE (MC.Status = 'Active')


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Items_List_Report] TO [DDL_Viewer] AS [dbo]
GO
