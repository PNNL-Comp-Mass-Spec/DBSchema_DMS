/****** Object:  View [dbo].[V_Mass_Correction_Factors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mass_Correction_Factors]
AS
SELECT mass_correction_id,
       mass_correction_tag,
       description,
       monoisotopic_mass,
       average_mass,
       ISNULL(Empirical_Formula, '') AS empirical_formula,
       affected_atom,
       original_source,
       original_source_name,
       alternative_name
FROM dbo.T_Mass_Correction_Factors


GO
GRANT VIEW DEFINITION ON [dbo].[V_Mass_Correction_Factors] TO [DDL_Viewer] AS [dbo]
GO
