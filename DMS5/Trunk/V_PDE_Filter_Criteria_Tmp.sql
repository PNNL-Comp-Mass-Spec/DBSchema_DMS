/****** Object:  View [dbo].[V_PDE_Filter_Criteria_Tmp] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_PDE_Filter_Criteria_Tmp
AS
SELECT     dbo.T_Filter_Set_Criteria_Names.Criterion_Name, dbo.T_Filter_Set_Criteria.Criterion_Comparison, dbo.T_Filter_Set_Criteria.Criterion_Value, 
                      dbo.T_Filter_Set_Criteria.Filter_Criteria_Group_ID, dbo.T_Filter_Set_Criteria.Filter_Set_Criteria_ID, 
                      dbo.T_Analysis_Tool.AJT_toolName AS Analysis_Tool_Name
FROM         dbo.T_Filter_Set_Criteria INNER JOIN
                      dbo.T_Filter_Set_Criteria_Names ON dbo.T_Filter_Set_Criteria.Criterion_ID = dbo.T_Filter_Set_Criteria_Names.Criterion_ID INNER JOIN
                      dbo.V_Filter_Set_Criteria_Name_Owners ON 
                      dbo.T_Filter_Set_Criteria_Names.Criterion_ID = dbo.V_Filter_Set_Criteria_Name_Owners.Criterion_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.V_Filter_Set_Criteria_Name_Owners.Analysis_Tool_ID = dbo.T_Analysis_Tool.AJT_toolID

GO
