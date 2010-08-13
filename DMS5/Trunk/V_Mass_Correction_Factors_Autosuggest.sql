/****** Object:  View [dbo].[V_Mass_Correction_Factors_Autosuggest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Mass_Correction_Factors_Autosuggest
AS
SELECT     Mass_Correction_ID AS id, Monoisotopic_Mass_Correction AS value, RTRIM(Mass_Correction_Tag) + ' - ' + Description AS info, Mass_Correction_Tag AS extra
FROM         dbo.T_Mass_Correction_Factors

GO
