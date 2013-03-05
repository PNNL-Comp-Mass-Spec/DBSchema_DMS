/****** Object:  View [dbo].[V_OSM_Package_AllItems_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* */
CREATE VIEW dbo.V_OSM_Package_AllItems_List_Report
AS
SELECT        OSM_Package_ID AS ID, '<item pkg="' + CONVERT(VARCHAR(12), OSM_Package_ID) + '" type="' + Item_Type + '" id="' + CONVERT(VARCHAR(128), Item_ID) 
                         + '"/>' AS [Sel.], Item_Type, CASE WHEN Item_Type IN ('Sample_Prep_Requests', 'Experiment_Groups', 'HPLC_Runs', 'Sample_Submissions', 'Requested_Runs') 
                         THEN CONVERT(VARCHAR(12), Item_ID) ELSE Item END AS Link, Item_ID, Item, [Item Added], [Package Comment]
FROM            dbo.T_OSM_Package_Items

GO
