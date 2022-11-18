/****** Object:  View [dbo].[V_Helper_Prep_LC_Run_Name_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Helper_Prep_LC_Run_Name_List_Report]
AS
SELECT TOP 1000 Prep_Run_Name as val
FROM ( SELECT Prep_Run_Name,
              UsageCount,
              Row_Number() OVER ( ORDER BY UsageCount DESC, Prep_Run_Name ) AS UsageRank
       FROM ( SELECT Prep_Run_Name,
                     COUNT(*) AS UsageCount
              FROM T_Prep_LC_Run
              WHERE Coalesce(Prep_Run_Name, '') <> ''
              GROUP BY Prep_Run_Name 
            ) SourceQ 
      ) RankQ
ORDER BY UsageRank


GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_LC_Run_Name_List_Report] TO [DDL_Viewer] AS [dbo]
GO
