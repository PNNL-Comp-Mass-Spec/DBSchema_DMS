/****** Object:  View [dbo].[V_Organism_Picker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Organism_Picker]
AS
SELECT 
    Org.Organism_ID AS ID, 
	Org.OG_name AS Short_Name, 
	CASE 
		WHEN NOT OG_Short_Name IS NULL 
		THEN OG_Short_Name 
		ELSE OG_Name 
	END + COALESCE(' - ' + Org.OG_description, '') AS Display_Name, 
	Org.OG_Storage_Location AS Storage_Location, 
	RTRIM(CASE WHEN (OG_genus IS NOT NULL AND OG_Genus <> 'na') 
		  THEN COALESCE (OG_Genus, '') + ' ' + COALESCE (OG_Species, '') + ' ' + COALESCE (OG_Strain, '') 
		  ELSE [OG_name] 
		  END) AS Organism_Name, 
	RTRIM(CASE WHEN (OG_genus IS NOT NULL AND OG_Genus <> 'na') AND	(OG_Species IS NOT NULL AND OG_Species <> 'na') 
		  THEN COALESCE (SUBSTRING(OG_Genus, 1, 1) + '.', '') + ' ' + COALESCE (OG_Species, '') + ' ' + COALESCE (OG_Strain, '') 
		  ELSE OG_Name 
		  END) AS Organism_Name_Abbrev_Genus, 
	Org.OG_Short_Name, 
	'organisms/' + LOWER(CASE WHEN (OG_Domain IS NULL OR OG_Domain = 'na') THEN 'Uncategorized' ELSE [OG_Domain] END + 
	                     CASE WHEN (OG_Kingdom IS NOT NULL AND OG_Kingdom <> 'na') THEN '/' + [OG_Kingdom] ELSE '' END + 
	                     CASE WHEN (OG_phylum IS NOT NULL AND OG_Phylum <> 'na') THEN '/' + [OG_Phylum] ELSE '' END
	                    ) AS Search_Terms, 
	IsNull(OrgCounts.collection_count, 0) AS Collection_Count
FROM GIGASAX.DMS5.dbo.T_Organisms AS Org LEFT OUTER JOIN
     dbo.V_Collection_Counts_By_Organism_ID OrgCounts 
       ON Org.Organism_ID = OrgCounts.organism_id


GO
GRANT SELECT ON [dbo].[V_Organism_Picker] TO [pnl\d3l243] AS [dbo]
GO
