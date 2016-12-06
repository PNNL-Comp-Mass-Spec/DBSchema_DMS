/****** Object:  View [dbo].[V_Filter_Set_Criteria_Name_Owners] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Filter_Set_Criteria_Name_Owners
AS
SELECT     dbo.T_Filter_Set_Criteria_Names.Criterion_ID, dbo.T_Filter_Set_Criteria_Names.Criterion_Name, 
                      dbo.T_Filter_Set_Criteria_Names.Criterion_Description, dbo.T_Filter_Set_Criteria_Name_Tool_Map.Analysis_Tool_ID, 
                      dbo.T_Analysis_Tool.AJT_toolName AS Analysis_Tool_Name
FROM         dbo.T_Filter_Set_Criteria_Names INNER JOIN
                      dbo.T_Filter_Set_Criteria_Name_Tool_Map ON 
                      dbo.T_Filter_Set_Criteria_Names.Criterion_ID = dbo.T_Filter_Set_Criteria_Name_Tool_Map.Criterion_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Filter_Set_Criteria_Name_Tool_Map.Analysis_Tool_ID = dbo.T_Analysis_Tool.AJT_toolID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Filter_Set_Criteria_Name_Owners] TO [DDL_Viewer] AS [dbo]
GO
