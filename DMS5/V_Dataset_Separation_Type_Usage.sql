/****** Object:  View [dbo].[V_Dataset_Separation_Type_Usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Dataset_Separation_Type_Usage]
AS
SELECT SUM(CASE
               WHEN datediff(MONTH, ds_created, getdate()) <= 12 THEN 1
               ELSE 0
           END) AS [Usage Last 12 Months],
       SS.SS_name AS [Separation Type],
       SS.Sep_Group as [Separation Group],
       SS.SS_comment AS [Separation Type Comment],
       SUM(CASE
               WHEN DS.Dataset_ID IS NULL THEN 0
               ELSE 1
           END) AS [Dataset Usage All Years],
       MAX(DS.DS_created) AS [Most Recent Use]
FROM T_Secondary_Sep SS
     LEFT OUTER JOIN T_Dataset DS
       ON DS.DS_sec_sep = SS.SS_name
WHERE (SS.SS_active <> 0)
GROUP BY SS.SS_name, SS.SS_comment, SS.Sep_Group




GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Separation_Type_Usage] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Separation_Type_Usage] TO [PNL\D3M580] AS [dbo]
GO
