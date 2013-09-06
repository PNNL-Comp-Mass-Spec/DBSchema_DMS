/****** Object:  View [dbo].[V_Sample_Prep_Request_Items_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Sample_Prep_Request_Items_List_Report]
AS
    SELECT  ID AS [ID] ,
            Item_ID AS [Item ID] ,
            Item_Name AS [Item Name] ,
            Item_Type AS [Item Type] ,
            Status AS [Status] ,
            Created AS [Created] ,
            Item_Added AS [Item Added] ,
            CASE WHEN Item_Type = 'dataset' THEN Item_Name
                 WHEN Item_Type = 'experiment' THEN Item_Name
                 WHEN Item_Type = 'experiment_group' THEN Item_ID
                 WHEN Item_Type = 'material_container' THEN Item_Name
                 WHEN Item_Type = 'prep_lc_run' THEN Item_ID
                 WHEN Item_Type = 'requested_run' THEN Item_ID
                 ELSE ''
            END AS #Link
    FROM    T_Sample_Prep_Request_Items

  
GO
