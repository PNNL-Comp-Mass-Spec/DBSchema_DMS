/****** Object:  View [dbo].[V_Separation_Group_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Separation_Group_List_Report] AS
SELECT SG.Sep_Group AS Separation_Group,
       SG.[Comment],
       SG.Active,
       SG.Sample_Prep_Visible,
       SG.Fraction_Count,
       Count(SS.SS_ID) AS Separation_Types
FROM T_Separation_Group SG
     LEFT OUTER JOIN T_Secondary_Sep SS
       ON SG.Sep_Group = SS.Sep_Group
GROUP BY SG.Sep_Group, SG.[Comment], SG.Active, SG.Sample_Prep_Visible, SG.Fraction_Count


GO
GRANT VIEW DEFINITION ON [dbo].[V_Separation_Group_List_Report] TO [DDL_Viewer] AS [dbo]
GO
