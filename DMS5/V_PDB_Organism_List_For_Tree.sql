/****** Object:  View [dbo].[V_PDB_Organism_List_For_Tree] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_PDB_Organism_List_For_Tree
AS
SELECT     TOP (100) PERCENT Organism_ID AS id, OG_name AS organism_name, RTRIM(CASE WHEN (OG_genus IS NOT NULL AND OG_Genus <> 'na') 
                      THEN COALESCE (OG_Genus, '') + ' ' + COALESCE (OG_Species, '') + ' ' + COALESCE (OG_Strain, '') ELSE [OG_name] END) AS display_name, 
                      'organisms/' + LOWER(CASE WHEN (OG_Domain IS NULL OR
                      OG_Domain = 'na') THEN 'Uncategorized' ELSE [OG_Domain] END + CASE WHEN (OG_Kingdom IS NOT NULL AND OG_Kingdom <> 'na') 
                      THEN '/' + [OG_Kingdom] ELSE '' END + CASE WHEN (OG_phylum IS NOT NULL AND OG_Phylum <> 'na') THEN '/' + [OG_Phylum] ELSE '' END) 
                      AS search_terms
FROM         dbo.T_Organisms
WHERE     (OG_name <> '(default)')

GO
GRANT SELECT ON [dbo].[V_PDB_Organism_List_For_Tree] TO [DMSWebUser] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_PDB_Organism_List_For_Tree] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_PDB_Organism_List_For_Tree] TO [PNL\D3M580] AS [dbo]
GO
