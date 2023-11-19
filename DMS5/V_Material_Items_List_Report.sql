/****** Object:  View [dbo].[V_Material_Items_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Material_Items_List_Report]
AS
SELECT ContentsQ.item,
       ContentsQ.item_type,
       ContentsQ.Material_ID AS id,
       MC.Tag AS container,
       MC.type,
       SUBSTRING(ContentsQ.item_type, 1, 1) + ':' + CONVERT(varchar, ContentsQ.Material_ID) AS item_id,
       ML.Tag AS location,
       ContentsQ.Material_Status AS item_status,
       MC.Status AS container_status,
       ContentsQ.Request_ID AS prep_request,
       ContentsQ.Campaign AS campaign
FROM T_Material_Containers AS MC
     INNER JOIN (SELECT E.Experiment_Num AS Item,
                        'Experiment' AS Item_Type,
                        E.EX_Container_ID AS Container_ID,
                        E.Exp_ID AS Material_ID,
                        E.EX_sample_prep_request_ID AS Request_ID,
                        E.Ex_Material_Active AS Material_Status,
                        C.Campaign_Num AS Campaign
                 FROM T_Experiments AS E
                      INNER JOIN T_Campaign AS C
                        ON E.EX_campaign_ID = C.Campaign_ID
                 UNION
                 SELECT CC.CC_Name AS Item,
                        'Biomaterial' AS Item_Type,
                        CC.CC_Container_ID AS Container_ID,
                        CC.CC_ID AS Material_ID,
                        null AS Request_ID,
                        CC.CC_Material_Active AS Material_Status,
                        C.Campaign_Num AS Campaign
                 FROM T_Cell_Culture CC
                      INNER JOIN T_Campaign AS C ON
                        CC.CC_Campaign_ID = C.Campaign_ID
                 UNION
                 SELECT RC.Compound_Name AS Item,
                        'RefCompound' AS Item_Type,
                        RC.Container_ID AS Container_ID,
                        RC.Compound_ID AS Material_ID,
                        null AS Request_ID,
                        CASE WHEN RC.Active > 0 THEN 'Active' ELSE 'Inactive' END AS Material_Status,
                        C.Campaign_Num AS Campaign
                 FROM T_Reference_Compound RC
                      INNER JOIN T_Campaign AS C ON
                        RC.Campaign_ID = C.Campaign_ID
                ) AS ContentsQ
       ON ContentsQ.Container_ID = MC.ID
     INNER JOIN dbo.T_Material_Locations AS ML
       ON MC.Location_ID = ML.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Items_List_Report] TO [DDL_Viewer] AS [dbo]
GO
