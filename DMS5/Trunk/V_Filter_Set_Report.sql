/****** Object:  View [dbo].[V_Filter_Set_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Filter_Set_Report
AS
SELECT TOP 100 PERCENT FST.Filter_Type_Name, 
    FS.Filter_Set_ID, FS.Filter_Set_Name, 
    FS.Filter_Set_Description, FSCG.Filter_Criteria_Group_ID, 
    MAX(CASE WHEN criterion_id = 1 THEN Criterion_Comparison + CONVERT(varchar(18),
     Criterion_Value) ELSE NULL END) AS Spectrum_Count, 
    MAX(CASE WHEN criterion_id = 2 THEN Criterion_Comparison + CONVERT(varchar(18),
     Criterion_Value) ELSE NULL END) AS Charge, 
    MAX(CASE WHEN criterion_id = 3 THEN Criterion_Comparison + CONVERT(varchar(18),
     Criterion_Value) ELSE NULL END) 
    AS High_Normalized_Score, 
    MAX(CASE WHEN criterion_id = 4 THEN Criterion_Comparison + CONVERT(varchar(18),
     Criterion_Value) ELSE NULL END) AS Cleavage_State, 
    MAX(CASE WHEN criterion_id = 13 THEN Criterion_Comparison +
     CONVERT(varchar(18), Criterion_Value) ELSE NULL END) 
    AS Terminus_State, 
    MAX(CASE WHEN criterion_id = 5 THEN Criterion_Comparison + CONVERT(varchar(18),
     Criterion_Value) ELSE NULL END) AS Peptide_Length, 
    MAX(CASE WHEN criterion_id = 6 THEN Criterion_Comparison + CONVERT(varchar(18),
     Criterion_Value) ELSE NULL END) AS Mass, 
    MAX(CASE WHEN criterion_id = 7 THEN Criterion_Comparison + CONVERT(varchar(18),
     Criterion_Value) ELSE NULL END) AS DelCn, 
    MAX(CASE WHEN criterion_id = 8 THEN Criterion_Comparison + CONVERT(varchar(18),
     Criterion_Value) ELSE NULL END) AS DelCn2, 
    MAX(CASE WHEN criterion_id = 9 THEN Criterion_Comparison + CONVERT(varchar(18),
     Criterion_Value) ELSE NULL END) AS Discriminant_Score, 
    MAX(CASE WHEN criterion_id = 10 THEN Criterion_Comparison +
     CONVERT(varchar(18), Criterion_Value) ELSE NULL END) 
    AS NET_Difference_Absolute, 
    MAX(CASE WHEN criterion_id = 11 THEN Criterion_Comparison +
     CONVERT(varchar(18), Criterion_Value) ELSE NULL END) 
    AS Discriminant_Initial_Filter, 
    MAX(CASE WHEN criterion_id = 12 THEN Criterion_Comparison +
     CONVERT(varchar(18), Criterion_Value) ELSE NULL END) 
    AS Protein_Count, 
    MAX(CASE WHEN criterion_id = 14 THEN Criterion_Comparison +
     CONVERT(varchar(18), Criterion_Value) ELSE NULL END) 
    AS XTandem_Hyperscore, 
    MAX(CASE WHEN criterion_id = 15 THEN Criterion_Comparison +
     CONVERT(varchar(18), Criterion_Value) ELSE NULL END) 
    AS XTandem_LogEValue, 
    MAX(CASE WHEN criterion_id = 16 THEN Criterion_Comparison +
     CONVERT(varchar(18), Criterion_Value) ELSE NULL END) 
    AS Peptide_Prophet_Probability, 
    MAX(CASE WHEN criterion_id = 17 THEN Criterion_Comparison +
     CONVERT(varchar(18), Criterion_Value) ELSE NULL END) 
    AS RankScore
FROM dbo.T_Filter_Set_Criteria FSC INNER JOIN
    dbo.T_Filter_Set_Criteria_Groups FSCG ON 
    FSC.Filter_Criteria_Group_ID = FSCG.Filter_Criteria_Group_ID INNER
     JOIN
    dbo.T_Filter_Sets FS ON 
    FSCG.Filter_Set_ID = FS.Filter_Set_ID INNER JOIN
    dbo.T_Filter_Set_Types FST ON 
    FS.Filter_Type_ID = FST.Filter_Type_ID
GROUP BY FS.Filter_Set_ID, FS.Filter_Set_Name, 
    FS.Filter_Set_Description, FSCG.Filter_Criteria_Group_ID, 
    FST.Filter_Type_Name
ORDER BY FST.Filter_Type_Name, FS.Filter_Set_ID, 
    FSCG.Filter_Criteria_Group_ID


GO
