/****** Object:  View [dbo].[V_Separation_Type_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Separation_Type_Entry]
AS
SELECT SS.SS_ID As ID,
	   SS.SS_name AS Separation_Name,
       SS.Sep_Group AS Separation_Group,
       SS.SS_comment AS Comment,
       ST.Name AS Sample_Type,
	   CASE WHEN SS.SS_active = 1 THEN 'Active' ELSE 'Inactive' END AS State
FROM T_Secondary_Sep SS
LEFT OUTER JOIN T_Secondary_Sep_SampleType ST ON SS.SampleType_ID = ST.SampleType_ID


GO
