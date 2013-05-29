/****** Object:  View [dbo].[V_Unimod_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Unimod_Detail_Report]
AS
	SELECT M.Unimod_ID,
	       M.Name,
	       M.Full_Name,
	       M.Alternate_Names,
	       M.Notes,
	       CONVERT(Decimal(15,6), M.MonoMass) as Monoisotopic_Mass,
	       CONVERT(Decimal(15,6), M.AvgMass) as Average_Mass,
	       M.Composition,
	       CommonSites.Sites,
	       HiddenSites.Sites AS HiddenSites,
	       M.URL,
	       M.Date_Posted,
	       M.Date_Modified,
	       M.Approved,
	       M.Poster_Username,
	       M.Poster_Group
	FROM T_Unimod_Mods M
	     CROSS APPLY dbo.GetModificationSiteList ( M.Unimod_ID, 0 ) CommonSites
	     CROSS APPLY dbo.GetModificationSiteList ( M.Unimod_ID, 1 ) HiddenSites


GO
