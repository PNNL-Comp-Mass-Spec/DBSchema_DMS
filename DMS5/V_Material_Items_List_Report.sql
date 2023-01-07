/****** Object:  View [dbo].[V_Material_Items_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Items_List_Report]
AS
SELECT ContentsQ.item,
       ContentsQ.item_type,      -- Note that this field needs to be Item_Type, and not Item_Type
       ContentsQ.Material_ID AS id,
       MC.Tag AS container,
       MC.type,
       SUBSTRING(ContentsQ.item_type, 1, 1) + ':' + CONVERT(varchar, ContentsQ.Material_ID) AS item_id,
       ML.Tag AS location,
       ContentsQ.Material_Status As item_status,
       MC.Status As container_status,
       ContentsQ.Request_ID AS prep_request
FROM dbo.T_Material_Containers AS MC
     INNER JOIN (SELECT Experiment_Num AS Item,
                        'Experiment' AS Item_Type,
                        EX_Container_ID AS Container_ID,
                        Exp_ID AS Material_ID,
                        EX_sample_prep_request_ID AS Request_ID,
                        Ex_Material_Active As Material_Status
                 FROM dbo.T_Experiments
                 UNION
                 SELECT CC_Name AS Item,
                        'Biomaterial' AS Item_Type,
                        CC_Container_ID AS Container_ID,
                        CC_ID AS Material_ID,
                        null AS Request_ID,
                        CC_Material_Active As Material_Status
                 FROM dbo.T_Cell_Culture
                 UNION
                 SELECT Compound_Name AS Item,
                        'RefCompound' AS Item_Type,
                        Container_ID AS Container_ID,
                        Compound_ID AS Material_ID,
                        null AS Request_ID,
                        Case When Active > 0 Then 'Active' Else 'Inactive' End As Material_Status
                 FROM dbo.T_Reference_Compound
                ) AS ContentsQ
       ON ContentsQ.Container_ID = MC.ID
     INNER JOIN dbo.T_Material_Locations AS ML
       ON MC.Location_ID = ML.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Items_List_Report] TO [DDL_Viewer] AS [dbo]
GO
