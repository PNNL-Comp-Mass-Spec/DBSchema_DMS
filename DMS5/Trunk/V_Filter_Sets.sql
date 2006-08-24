/****** Object:  View [dbo].[V_Filter_Sets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Filter_Sets
AS
SELECT     TOP 100 PERCENT dbo.T_Filter_Set_Types.Filter_Type_ID, dbo.T_Filter_Set_Types.Filter_Type_Name, dbo.T_Filter_Sets.Filter_Set_ID, 
                      dbo.T_Filter_Sets.Filter_Set_Name, dbo.T_Filter_Sets.Filter_Set_Description, dbo.T_Filter_Set_Criteria.Filter_Criteria_Group_ID, 
                      dbo.T_Filter_Set_Criteria_Names.Criterion_ID, dbo.T_Filter_Set_Criteria_Names.Criterion_Name, dbo.T_Filter_Set_Criteria.Filter_Set_Criteria_ID, 
                      dbo.T_Filter_Set_Criteria.Criterion_Comparison, dbo.T_Filter_Set_Criteria.Criterion_Value
FROM         dbo.T_Filter_Set_Types INNER JOIN
                      dbo.T_Filter_Sets ON dbo.T_Filter_Set_Types.Filter_Type_ID = dbo.T_Filter_Sets.Filter_Type_ID INNER JOIN
                      dbo.T_Filter_Set_Criteria_Groups ON dbo.T_Filter_Sets.Filter_Set_ID = dbo.T_Filter_Set_Criteria_Groups.Filter_Set_ID INNER JOIN
                      dbo.T_Filter_Set_Criteria INNER JOIN
                      dbo.T_Filter_Set_Criteria_Names ON dbo.T_Filter_Set_Criteria.Criterion_ID = dbo.T_Filter_Set_Criteria_Names.Criterion_ID ON 
                      dbo.T_Filter_Set_Criteria_Groups.Filter_Criteria_Group_ID = dbo.T_Filter_Set_Criteria.Filter_Criteria_Group_ID
ORDER BY dbo.T_Filter_Set_Types.Filter_Type_Name, dbo.T_Filter_Sets.Filter_Set_ID, dbo.T_Filter_Set_Criteria.Filter_Criteria_Group_ID, 
                      dbo.T_Filter_Set_Criteria_Names.Criterion_ID

GO
