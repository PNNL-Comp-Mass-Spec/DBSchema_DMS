/****** Object:  View [dbo].[V_Dataset_Separation_Type_Usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Separation_Type_Usage]
AS

SELECT U.Usage_Last12Months AS [Usage Last 12 Months],
       SS.SS_name AS [Separation Type],
       SS.Sep_Group AS [Separation Group],
       SS.SS_comment AS [Separation Type Comment],
       SampType.Name AS [Sample Type],
       U.Usage_AllYears AS [Dataset Usage All Years],
       U.Most_Recent_Use AS [Most Recent Use]
FROM T_Secondary_Sep SS
     INNER JOIN T_Secondary_Sep_SampleType SampType
       ON SS.SampleType_ID = SampType.SampleType_ID
     LEFT OUTER JOIN T_Secondary_Sep_Usage U
       ON U.SS_ID = SS.SS_ID
WHERE (SS.SS_active <> 0)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Separation_Type_Usage] TO [DDL_Viewer] AS [dbo]
GO
