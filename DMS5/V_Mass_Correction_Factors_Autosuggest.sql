/****** Object:  View [dbo].[V_Mass_Correction_Factors_Autosuggest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[V_Mass_Correction_Factors_Autosuggest] 
AS 
SELECT Mass_Correction_ID AS id,
       Monoisotopic_Mass AS value,
       RTRIM(Mass_Correction_Tag) + ' - ' + Description AS info,
       Mass_Correction_Tag AS extra,
       CASE
           WHEN IsNull(affected_atom, '') = '-' THEN 'std'
           ELSE 'iso'
       END AS type
FROM dbo.T_Mass_Correction_Factors
WHERE ABS(Monoisotopic_Mass) > 0

GO
GRANT VIEW DEFINITION ON [dbo].[V_Mass_Correction_Factors_Autosuggest] TO [DDL_Viewer] AS [dbo]
GO
