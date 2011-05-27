/****** Object:  View [dbo].[V_Mage_Filter_Set_Criteria] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW V_Mage_Filter_Set_Criteria
AS
SELECT TF.Filter_Set_ID,
       TG.Filter_Criteria_Group_ID,
       TN.Criterion_Name,
       TC.Criterion_Comparison,
       TC.Criterion_Value
FROM T_Filter_Sets AS TF
     INNER JOIN T_Filter_Set_Criteria_Groups AS TG
       ON TF.Filter_Set_ID = TG.Filter_Set_ID
     INNER JOIN T_Filter_Set_Criteria AS TC
       ON TG.Filter_Criteria_Group_ID = TC.Filter_Criteria_Group_ID
     INNER JOIN T_Filter_Set_Criteria_Names AS TN
       ON TC.Criterion_ID = TN.Criterion_ID

GO
