/****** Object:  View [dbo].[V_Filter_Set_Members_By_Analysis_Tool] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Filter_Set_Members_By_Analysis_Tool
AS
SELECT     dbo.V_Filter_Sets.Filter_Type_ID, dbo.V_Filter_Sets.Filter_Type_Name, dbo.V_Filter_Sets.Filter_Set_ID, dbo.V_Filter_Sets.Filter_Set_Name, 
                      dbo.V_Filter_Sets.Filter_Set_Description, dbo.V_Filter_Sets.Filter_Criteria_Group_ID, dbo.V_Filter_Sets.Criterion_ID, dbo.V_Filter_Sets.Criterion_Name, 
                      dbo.V_Filter_Sets.Filter_Set_Criteria_ID, dbo.V_Filter_Sets.Criterion_Comparison, dbo.V_Filter_Sets.Criterion_Value, 
                      dbo.T_Filter_Set_Criteria_Name_Tool_Map.Analysis_Tool_ID, dbo.T_Analysis_Tool.AJT_toolName AS Analysis_Tool_Name
FROM         dbo.V_Filter_Sets INNER JOIN
                      dbo.T_Filter_Set_Criteria_Name_Tool_Map ON dbo.V_Filter_Sets.Criterion_ID = dbo.T_Filter_Set_Criteria_Name_Tool_Map.Criterion_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Filter_Set_Criteria_Name_Tool_Map.Analysis_Tool_ID = dbo.T_Analysis_Tool.AJT_toolID

GO
