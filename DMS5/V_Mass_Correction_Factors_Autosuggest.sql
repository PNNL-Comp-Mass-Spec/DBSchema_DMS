/****** Object:  View [dbo].[V_Mass_Correction_Factors_Autosuggest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW V_Mass_Correction_Factors_Autosuggest 
AS 
SELECT Mass_Correction_ID AS id,
	   Monoisotopic_Mass_Correction AS value,
	   RTRIM(Mass_Correction_Tag) + ' - ' + Description AS info,
	   Mass_Correction_Tag AS extra,
	   CASE
		   WHEN NULLIF('-', affected_atom) IS NOT NULL THEN 'iso'
		   ELSE 'std'
	   END AS type
FROM dbo.T_Mass_Correction_Factors
WHERE ABS(Monoisotopic_Mass_Correction) > 0

GO
GRANT VIEW DEFINITION ON [dbo].[V_Mass_Correction_Factors_Autosuggest] TO [PNL\D3M578] AS [dbo]
GO
