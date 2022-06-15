/****** Object:  View [dbo].[V_PDE_Filter_Criteria] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_PDE_Filter_Criteria]
AS
-- This view was used by PRISM Data Extractor, then StarSuite Extractor, both of which were retired in 2011 when Mage Extractor was released
--
SELECT     dbo.T_Filter_Set_Criteria_Names.Criterion_Name, dbo.T_Filter_Set_Criteria.Criterion_Comparison, dbo.T_Filter_Set_Criteria.Criterion_Value, 
                      dbo.T_Filter_Set_Criteria.Filter_Criteria_Group_ID, dbo.T_Filter_Set_Criteria.Filter_Set_Criteria_ID, 
                      dbo.T_Filter_Set_Criteria_Names.Criterion_Description
FROM         dbo.T_Filter_Set_Criteria INNER JOIN
                      dbo.T_Filter_Set_Criteria_Names ON dbo.T_Filter_Set_Criteria.Criterion_ID = dbo.T_Filter_Set_Criteria_Names.Criterion_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_PDE_Filter_Criteria] TO [DDL_Viewer] AS [dbo]
GO
