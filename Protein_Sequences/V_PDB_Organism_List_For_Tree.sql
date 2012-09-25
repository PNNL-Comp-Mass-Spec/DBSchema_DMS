/****** Object:  View [dbo].[V_PDB_Organism_List_For_Tree] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_PDB_Organism_List_For_Tree]
AS
SELECT ID AS id,
       short_name AS organism_name,
       Organism_Name AS display_name,
       search_terms AS search_terms
FROM V_Organism_Picker
WHERE short_name NOT LIKE '%def%'

/*
-- Original query
SELECT Organism_ID AS id,
       OG_name AS organism_name,
       RTRIM(CASE
                 WHEN (OG_genus IS NOT NULL AND
                       OG_Genus <> 'na') THEN COALESCE(OG_Genus, '') + ' ' + 
                                                COALESCE(OG_Species, '') + ' ' + 
                                                COALESCE(OG_Strain, '')
                 ELSE [OG_name]
             END) AS display_name,
       'organisms/' + LOWER(CASE
                                WHEN (OG_Domain IS NULL OR
                                      OG_Domain = 'na') THEN COALESCE(OG_Domain, 'Uncategorized')
                                ELSE [OG_Domain]
                            END + CASE
                                      WHEN (OG_Kingdom IS NULL OR
                                            OG_Kingdom = 'na' OR
                                            OG_Kingdom = '') THEN COALESCE('/' + OG_Kingdom, '')
                                      ELSE '/' + [OG_Kingdom]
                                  END + CASE
                                            WHEN (OG_Phylum IS NULL OR
                                                  OG_Phylum = 'na' OR
                                                  OG_Phylum = '') THEN COALESCE('/' + OG_Phylum, '')
                                            ELSE '/' + [OG_Phylum]
                                        END) AS search_terms
FROM DMS5.dbo.T_Organisms AS T_Organisms
WHERE (OG_name <> '(default)')
*/


GO
