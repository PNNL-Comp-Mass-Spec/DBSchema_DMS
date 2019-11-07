/****** Object:  View [dbo].[V_Separation_Type_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Separation_Type_List_Report]
AS

SELECT SS.SS_name AS [Separation Type],
       SS.Sep_Group AS [Separation Group],
       SS.SS_comment AS [Separation Type Comment],
       SampType.Name AS [Sample Type],
       U.Usage_Last12Months AS [Usage Last 12 Months],
       U.Usage_AllYears AS [Dataset Usage All Years],
       U.Most_Recent_Use AS [Most Recent Use],
       SS.SS_active As Active,
       SS.SS_ID As ID
FROM T_Secondary_Sep SS
     INNER JOIN T_Secondary_Sep_SampleType SampType
       ON SS.SampleType_ID = SampType.SampleType_ID
     LEFT OUTER JOIN T_Secondary_Sep_Usage U
       ON U.SS_ID = SS.SS_ID


GO
