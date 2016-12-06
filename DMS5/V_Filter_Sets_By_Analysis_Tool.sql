/****** Object:  View [dbo].[V_Filter_Sets_By_Analysis_Tool] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Filter_Sets_By_Analysis_Tool]
AS
SELECT FS.Filter_Set_ID,
       MIN(FS.Filter_Set_Name) AS Filter_Set_Name,
       MIN(FS.Filter_Set_Description) AS Filter_Set_Description,
       FSCM.Analysis_Tool_ID,
       Tool.AJT_toolName AS Analysis_Tool_Name
FROM T_Filter_Set_Criteria_Groups FSCG
     INNER JOIN T_Filter_Sets FS
       ON FSCG.Filter_Set_ID = FS.Filter_Set_ID
     INNER JOIN T_Filter_Set_Criteria FSC
       ON FSCG.Filter_Criteria_Group_ID = FSC.Filter_Criteria_Group_ID
     INNER JOIN T_Filter_Set_Criteria_Name_Tool_Map FSCM
                INNER JOIN T_Analysis_Tool Tool
                  ON FSCM.Analysis_Tool_ID = Tool.AJT_toolID
       ON FSC.Criterion_ID = FSCM.Criterion_ID
GROUP BY FSCM.Analysis_Tool_ID, FS.Filter_Set_ID, Tool.AJT_toolName


GO
GRANT VIEW DEFINITION ON [dbo].[V_Filter_Sets_By_Analysis_Tool] TO [DDL_Viewer] AS [dbo]
GO
