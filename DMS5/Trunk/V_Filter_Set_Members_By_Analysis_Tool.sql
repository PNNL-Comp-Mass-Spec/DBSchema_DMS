/****** Object:  View [dbo].[V_Filter_Set_Members_By_Analysis_Tool] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Filter_Set_Members_By_Analysis_Tool]
AS
SELECT FS.Filter_Type_ID,
       FS.Filter_Type_Name,
       FS.Filter_Set_ID,
       FS.Filter_Set_Name,
       FS.Filter_Set_Description,
       FS.Filter_Criteria_Group_ID,
       FS.Criterion_ID,
       FS.Criterion_Name,
       FS.Filter_Set_Criteria_ID,
       FS.Criterion_Comparison,
       FS.Criterion_Value,
       FSCM.Analysis_Tool_ID,
       Tool.AJT_toolName AS Analysis_Tool_Name
FROM V_Filter_Sets FS
     INNER JOIN T_Filter_Set_Criteria_Name_Tool_Map FSCM
       ON FS.Criterion_ID = FSCM.Criterion_ID
     INNER JOIN T_Analysis_Tool Tool
       ON FSCM.Analysis_Tool_ID = Tool.AJT_toolID
    

GO
GRANT VIEW DEFINITION ON [dbo].[V_Filter_Set_Members_By_Analysis_Tool] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Filter_Set_Members_By_Analysis_Tool] TO [PNL\D3M580] AS [dbo]
GO
