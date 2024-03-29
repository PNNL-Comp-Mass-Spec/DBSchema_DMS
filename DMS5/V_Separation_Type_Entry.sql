/****** Object:  View [dbo].[V_Separation_Type_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Separation_Type_Entry]
AS
SELECT SS.SS_ID As id,
	   SS.SS_name AS separation_name,
       SS.Sep_Group AS separation_group,
       SS.SS_comment AS comment,
       ST.Name AS sample_type,
	   CASE WHEN SS.SS_active = 1 THEN 'Active' ELSE 'Inactive' END AS state
FROM T_Secondary_Sep SS
LEFT OUTER JOIN T_Secondary_Sep_SampleType ST ON SS.SampleType_ID = ST.SampleType_ID


GO
