/****** Object:  View [dbo].[V_Filter_Sets_By_Analysis_Tool] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Filter_Sets_By_Analysis_Tool
AS
SELECT     TOP 100 PERCENT dbo.T_Filter_Sets.Filter_Set_ID, MIN(dbo.T_Filter_Sets.Filter_Set_Name) AS Filter_Set_Name, 
                      MIN(dbo.T_Filter_Sets.Filter_Set_Description) AS Filter_Set_Description, dbo.T_Filter_Set_Criteria_Name_Tool_Map.Analysis_Tool_ID, 
                      dbo.T_Analysis_Tool.AJT_toolName AS Analysis_Tool_Name
FROM         dbo.V_Filter_Sets INNER JOIN
                      dbo.T_Filter_Set_Criteria_Name_Tool_Map ON dbo.V_Filter_Sets.Criterion_ID = dbo.T_Filter_Set_Criteria_Name_Tool_Map.Criterion_ID INNER JOIN
                      dbo.T_Filter_Sets ON dbo.V_Filter_Sets.Filter_Set_ID = dbo.T_Filter_Sets.Filter_Set_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Filter_Set_Criteria_Name_Tool_Map.Analysis_Tool_ID = dbo.T_Analysis_Tool.AJT_toolID
GROUP BY dbo.T_Filter_Set_Criteria_Name_Tool_Map.Analysis_Tool_ID, dbo.T_Filter_Sets.Filter_Set_ID, dbo.T_Analysis_Tool.AJT_toolName
ORDER BY dbo.T_Filter_Sets.Filter_Set_ID

GO
