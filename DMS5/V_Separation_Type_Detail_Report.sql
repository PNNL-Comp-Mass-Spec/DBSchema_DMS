/****** Object:  View [dbo].[V_Separation_Type_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Separation_Type_Detail_Report]
AS
SELECT SS.SS_name AS separation_type,
       SS.Sep_Group AS separation_group,
       SS.SS_comment AS separation_type_comment,
       SampType.Name AS sample_type,
       U.Usage_Last12Months AS usage_last_12_months,
       U.Usage_AllYears AS dataset_usage_all_years,
       U.Most_Recent_Use AS most_recent_use,
       CASE WHEN SS.SS_active = 1 THEN 'Active' ELSE 'Inactive' END AS state,
       SS.SS_ID As id,
	   SS.Created As created
FROM T_Secondary_Sep SS
     INNER JOIN T_Secondary_Sep_SampleType SampType
       ON SS.SampleType_ID = SampType.SampleType_ID
     LEFT OUTER JOIN T_Secondary_Sep_Usage U
       ON U.SS_ID = SS.SS_ID


GO
