/****** Object:  View [dbo].[V_Mass_Correction_Factors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mass_Correction_Factors]
AS
SELECT Mass_Correction_ID,
       Mass_Correction_Tag,
       Description,
       Monoisotopic_Mass_Correction AS Monoisotopic_Mass,
       Average_Mass_Correction AS Average_Mass,
       ISNULL(Empirical_Formula, '') AS Empirical_Formula,
       Affected_Atom,
       Original_Source,
       Original_Source_Name,
       Alternative_Name
FROM dbo.T_Mass_Correction_Factors


GO
GRANT VIEW DEFINITION ON [dbo].[V_Mass_Correction_Factors] TO [DDL_Viewer] AS [dbo]
GO
