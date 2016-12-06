/****** Object:  View [dbo].[V_Filter_Set_Criteria] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Filter_Set_Criteria]
AS
SELECT FS.Filter_Set_ID,
                   FS.Filter_Set_Name,
                   FS.Filter_Set_Description,
                   FSC.Filter_Criteria_Group_ID,
                   FSC.Filter_Set_Criteria_ID,
                   FSC.Criterion_ID,
                   FSCN.Criterion_Name,
                   FSC.Criterion_Comparison,
                   FSC.Criterion_Value
FROM dbo.T_Filter_Sets AS FS
     INNER JOIN dbo.T_Filter_Set_Criteria_Groups AS FSCG
       ON FS.Filter_Set_ID = FSCG.Filter_Set_ID
     INNER JOIN dbo.T_Filter_Set_Criteria AS FSC
       ON FSCG.Filter_Criteria_Group_ID = FSC.Filter_Criteria_Group_ID
     INNER JOIN dbo.T_Filter_Set_Criteria_Names AS FSCN
       ON FSC.Criterion_ID = FSCN.Criterion_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Filter_Set_Criteria] TO [DDL_Viewer] AS [dbo]
GO
