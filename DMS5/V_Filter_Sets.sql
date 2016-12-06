/****** Object:  View [dbo].[V_Filter_Sets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Filter_Sets]
AS
SELECT FST.Filter_Type_ID,
       FST.Filter_Type_Name,
       FS.Filter_Set_ID,
       FS.Filter_Set_Name,
       FS.Filter_Set_Description,
       FSC.Filter_Criteria_Group_ID,
       FSCN.Criterion_ID,
       FSCN.Criterion_Name,
       FSC.Filter_Set_Criteria_ID,
       FSC.Criterion_Comparison,
       FSC.Criterion_Value
FROM dbo.T_Filter_Set_Types FST
     INNER JOIN dbo.T_Filter_Sets FS
       ON FST.Filter_Type_ID = FS.Filter_Type_ID
     INNER JOIN dbo.T_Filter_Set_Criteria_Groups FSCG
       ON FS.Filter_Set_ID = FSCG.Filter_Set_ID
     INNER JOIN dbo.T_Filter_Set_Criteria FSC
                INNER JOIN dbo.T_Filter_Set_Criteria_Names FSCN
                  ON FSC.Criterion_ID = FSCN.Criterion_ID
       ON FSCG.Filter_Criteria_Group_ID = FSC.Filter_Criteria_Group_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Filter_Sets] TO [DDL_Viewer] AS [dbo]
GO
