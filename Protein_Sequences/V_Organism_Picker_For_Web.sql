/****** Object:  View [dbo].[V_Organism_Picker_For_Web] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Organism_Picker_For_Web]
AS

SELECT ID,
       Short_Name AS dms_name,
       Display_Name AS display_name,
       Storage_Location AS storage_location,
       Organism_Name AS organism_name,
       Organism_Name_Abbrev_Genus as abbrev_name,
       OG_Short_Name AS short_dms_name,
       Search_Terms AS search_terms,
       Collection_Count AS collection_count
FROM V_Organism_Picker

/*
-- Old Version
SELECT Org.Organism_ID AS id,
       Org.OG_name AS dms_name,
       CASE
           WHEN OG_Short_Name IS NOT NULL THEN OG_Short_Name
           ELSE OG_Name
       END + ' - ' + Org.OG_description AS display_name,
       Org.OG_Storage_Location AS storage_location,
       RTRIM(CASE
                 WHEN (OG_genus IS NOT NULL AND
                       OG_Genus <> 'na') THEN COALESCE(OG_Genus, '') + ' ' + 
                                                COALESCE(OG_Species, '') + ' ' + 
                                                COALESCE(OG_Strain, '')
                 ELSE [OG_name]
             END) AS organism_name,
       RTRIM(CASE
                 WHEN (OG_genus IS NOT NULL AND
                       OG_Genus <> 'na') AND
                      (OG_Species IS NOT NULL AND
                       OG_Species <> 'na') THEN COALESCE(SUBSTRING(OG_Genus, 1, 1) + '.', '') + ' ' 
                                                + COALESCE(OG_Species, '') + ' ' + 
                                                  COALESCE(OG_Strain, '')
                 ELSE OG_Name
             END) AS abbrev_name,
       Org.OG_Short_Name AS short_dms_name,
       'organisms/' + LOWER(CASE
                                WHEN (OG_Domain IS NULL OR
                                      OG_Domain = 'na') THEN 'Uncategorized'
                                ELSE [OG_Domain]
                            END + CASE
                                      WHEN (OG_Kingdom IS NOT NULL AND
                                            OG_Kingdom <> 'na') THEN '/' + [OG_Kingdom]
                                      ELSE ''
                                  END + CASE
                                            WHEN (OG_phylum IS NOT NULL AND
                                                  OG_Phylum <> 'na') THEN '/' + [OG_Phylum]
                                            ELSE ''
                                        END) AS search_terms,
       CASE
           WHEN dbo.V_Collection_Counts_By_Organism_ID.collection_count IS NOT NULL THEN
             dbo.V_Collection_Counts_By_Organism_ID.collection_count
           ELSE 0
       END AS collection_count
FROM DMS5.dbo.T_Organisms AS T_Organisms

*/


GO
