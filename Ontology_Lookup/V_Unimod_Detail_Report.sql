/****** Object:  View [dbo].[V_Unimod_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Unimod_Detail_Report]
AS
SELECT M.unimod_id,
       M.name,
       M.full_name,
       M.alternate_names,
       M.notes,
       MCF.Mass_Correction_Tag AS dms_name,
       MCF.Mass_Correction_ID AS mass_correction_id,
       CONVERT(Decimal(15,6), M.MonoMass) AS monoisotopic_mass,
       CONVERT(Decimal(15,6), M.AvgMass) AS average_mass,
       M.composition,
       CommonSites.sites,
       HiddenSites.Sites AS hidden_sites,
       M.url,
       M.date_posted,
       M.date_modified,
       M.approved,
       M.poster_username,
       M.poster_group
FROM T_Unimod_Mods M
     CROSS APPLY dbo.get_modification_site_list ( M.Unimod_ID, 0 ) CommonSites
     CROSS APPLY dbo.get_modification_site_list ( M.Unimod_ID, 1 ) HiddenSites
     LEFT OUTER JOIN DMS5.dbo.V_Mass_Correction_Factors MCF
         ON M.Name = MCF.Original_Source_Name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Unimod_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
