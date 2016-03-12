/****** Object:  View [dbo].[V_Helper_Prep_Lc_Run_Tab_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Helper_Prep_Lc_Run_Tab_List_Report] as
SELECT TOP 250 Tab as val
FROM ( SELECT Tab,
              UsageCount,
              Row_Number() OVER ( ORDER BY UsageCount DESC, Tab ) AS UsageRank
       FROM ( SELECT Tab,
                     COUNT(*) AS UsageCount
              FROM T_Prep_LC_Run
              WHERE (NOT (Tab IS NULL))
              GROUP BY Tab 
            ) SourceQ 
      ) RankQ
ORDER BY UsageRank



GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_Lc_Run_Tab_List_Report] TO [PNL\D3M578] AS [dbo]
GO
