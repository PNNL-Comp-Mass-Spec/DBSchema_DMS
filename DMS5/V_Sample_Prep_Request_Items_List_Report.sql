/****** Object:  View [dbo].[V_Sample_Prep_Request_Items_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Items_List_Report]
AS
SELECT ID AS id,
        Item_ID AS item_id,
        Item_Name AS item_name,
        Item_Type AS item_type,
        Status AS status,
        Created AS created,
        Item_Added AS item_added,
        CASE WHEN Item_Type = 'dataset' THEN Item_Name
                WHEN Item_Type = 'experiment' THEN Item_Name
                WHEN Item_Type = 'experiment_group' THEN Cast(Item_ID As Varchar(128))
                WHEN Item_Type = 'material_container' THEN Item_Name
                WHEN Item_Type = 'prep_lc_run' THEN Cast(Item_ID As Varchar(128))
                WHEN Item_Type = 'requested_run' THEN Cast(Item_ID As Varchar(128))
                ELSE ''
        END AS link
FROM T_Sample_Prep_Request_Items


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Items_List_Report] TO [DDL_Viewer] AS [dbo]
GO
