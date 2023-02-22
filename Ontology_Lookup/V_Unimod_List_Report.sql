/****** Object:  View [dbo].[V_Unimod_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Unimod_List_Report]
AS
SELECT M.Unimod_ID AS id,
       M.name,
       MCF.Mass_Correction_Tag AS dms_name,
       CONVERT(decimal(15, 6), M.MonoMass) AS mono_mass,
       M.full_name,
       M.alternate_names,
       M.composition,
       SiteList.sites,
       CONVERT(date, M.Date_Posted) AS posted,
       CONVERT(date, M.Date_Modified) AS modified,
       M.approved
FROM T_Unimod_Mods M
     CROSS APPLY dbo.get_modification_site_list ( M.Unimod_ID, 0 ) SiteList
     LEFT OUTER JOIN DMS5.dbo.V_Mass_Correction_Factors MCF
         ON M.Name = MCF.Original_Source_Name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Unimod_List_Report] TO [DDL_Viewer] AS [dbo]
GO
