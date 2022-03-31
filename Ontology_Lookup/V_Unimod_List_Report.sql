/****** Object:  View [dbo].[V_Unimod_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Unimod_List_Report]
AS
SELECT M.Unimod_ID AS ID,
       M.Name,
       MCF.Mass_Correction_Tag AS DMS_Name,
       CONVERT(decimal(15, 6), M.MonoMass) AS MonoMass,
       M.Full_Name,
       M.Alternate_Names,
       M.Composition,
       SiteList.Sites,
       CONVERT(date, M.Date_Posted) AS Posted,
       CONVERT(date, M.Date_Modified) AS Modified,
       M.Approved
FROM T_Unimod_Mods M
     CROSS APPLY dbo.GetModificationSiteList ( M.Unimod_ID, 0 ) SiteList
     LEFT OUTER JOIN DMS5.dbo.V_Mass_Correction_Factors MCF
         ON M.Name = MCF.Original_Source_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Unimod_List_Report] TO [DDL_Viewer] AS [dbo]
GO
