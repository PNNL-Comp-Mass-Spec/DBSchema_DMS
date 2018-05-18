/****** Object:  View [dbo].[V_Material_Items_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Items_List_Report]
AS
SELECT ContentsQ.Item,       
       ContentsQ.Item_Type,      -- Note that this field needs to be Item_Type, and not [Item Type]
       ContentsQ.Material_ID AS ID,
       -- Unused: Containers.Barcode,
       MC.Tag AS Container,
       MC.[Type],
       SUBSTRING(ContentsQ.Item_Type, 1, 1) + ':' + CONVERT(varchar, ContentsQ.Material_ID) AS [#I_ID],  -- ItemID
       ML.Tag AS [Location],
       MC.[Status] As [Container Status],
       ContentsQ.Request_ID AS [Prep Request]
FROM dbo.T_Material_Containers AS MC
     INNER JOIN (SELECT Experiment_Num AS Item,
                        'Experiment' AS Item_Type,
                        EX_Container_ID AS Container_ID,
                        Exp_ID AS Material_ID,
                        -- Unused: EX_Barcode AS Barcode
                        EX_sample_prep_request_ID AS Request_ID
                 FROM dbo.T_Experiments
                 UNION
                 SELECT CC_Name AS Item,
                        'Biomaterial' AS Item_Type,
                        CC_Container_ID AS Container_ID,
                        CC_ID AS Material_ID,
                        null AS Request_ID
                 FROM dbo.T_Cell_Culture 
                 UNION
                 SELECT Compound_Name AS Item,
                        'RefCompound' AS Item_Type,
                        Container_ID AS Container_ID,
                        Compound_ID AS Material_ID,
                        null AS Request_ID
                 FROM dbo.T_Reference_Compound
                ) AS ContentsQ
       ON ContentsQ.Container_ID = MC.ID
     INNER JOIN dbo.T_Material_Locations AS ML
       ON MC.Location_ID = ML.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Items_List_Report] TO [DDL_Viewer] AS [dbo]
GO
