/****** Object:  View [dbo].[V_Data_Package_AllItems_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Data_Package_AllItems_List_Report
AS
SELECT     Data_Package_ID AS ID, '<item pkg="' + CONVERT(varchar(12), Data_Package_ID) + '" type="Job" id="' + CONVERT(varchar(128), Job) + '"/>' AS [Sel.], 
                      'Job' AS Item_Type, CONVERT(varchar(128), Job) AS Item, Dataset AS Parent_Entity, Tool AS Info, [Item Added], [Package Comment], 1 AS SortKey
FROM         dbo.T_Data_Package_Analysis_Jobs
UNION
SELECT     Data_Package_ID AS ID, '<item pkg="' + CONVERT(varchar(12), Data_Package_ID) + '" type="Dataset" id="' + Dataset + '"/>' AS [Sel.], 
                      'Dataset' AS Item_Type, Dataset AS Item, Experiment AS Parent_Entity, Instrument AS Info, [Item Added], [Package Comment], 2 AS SortKey
FROM         dbo.T_Data_Package_Datasets
UNION
SELECT     Data_Package_ID AS ID, '<item pkg="' + CONVERT(varchar(12), Data_Package_ID) + '" type="Experiment" id="' + Experiment + '"/>' AS [Sel.], 
                      'Experiment' AS Item_Type, Experiment AS Item, '' AS Parent_Entity, '' AS Info, [Item Added], [Package Comment], 3 AS SortKey
FROM         dbo.T_Data_Package_Experiments
UNION
SELECT     Data_Package_ID AS ID, '<item pkg="' + CONVERT(varchar(12), Data_Package_ID) + '" type="Biomaterial" id="' + Name + '"/>' AS [Sel.], 
                      'Biomaterial' AS Item_Type, Name AS Item, Campaign AS Parent_Entity, Type AS Info, [Item Added], [Package Comment], 4 AS SortKey
FROM         dbo.T_Data_Package_Biomaterial

GO
GRANT SELECT ON [dbo].[V_Data_Package_AllItems_List_Report] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_AllItems_List_Report] TO [PNL\D3M578] AS [dbo]
GO
