/****** Object:  View [dbo].[V_Organism_Picker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Organism_Picker]
AS
SELECT 
    Org.Organism_ID AS ID, 
	Org.Name AS Short_Name, 
	ISNULL(Org.Short_Name, Org.Name) + COALESCE(' - ' + Org.Description, '') AS Display_Name, 
	REPLACE(Org.OrganismDBPath, '\Fasta', '') AS Storage_Location, 
	RTRIM(CASE WHEN (Org.Genus IS NOT NULL AND Org.Genus <> 'na') 
		  THEN COALESCE (Org.Genus, '') + ' ' + COALESCE (Org.Species, '') + ' ' + COALESCE (Org.Strain, '') 
		  ELSE Org.Name
		  END) AS Organism_Name, 
	RTRIM(CASE WHEN (Org.Genus IS NOT NULL AND Org.Genus <> 'na') AND (Org.Species IS NOT NULL AND Org.Species <> 'na') 
		  THEN COALESCE (SUBSTRING(Org.Genus, 1, 1) + '.', '') + ' ' + COALESCE (Org.Species, '') + ' ' + COALESCE (Org.Strain, '') 
		  ELSE Org.Name 
		  END) AS Organism_Name_Abbrev_Genus, 
	Org.Short_Name AS OG_Short_Name, 
	'organisms/' + LOWER(CASE WHEN (Org.Domain IS NULL OR Domain = 'na') THEN 'Uncategorized' ELSE Org.Domain END + 
	                     CASE WHEN (Org.Kingdom IS NOT NULL AND Kingdom <> 'na') THEN '/' + Org.Kingdom ELSE '' END + 
	                     CASE WHEN (Org.Phylum IS NOT NULL AND Phylum <> 'na') THEN '/' + Org.Phylum ELSE '' END
	                    ) AS Search_Terms, 
	IsNull(OrgCounts.collection_count, 0) AS Collection_Count
FROM MT_Main.dbo.T_DMS_Organisms AS Org LEFT OUTER JOIN
     dbo.V_Collection_Counts_By_Organism_ID OrgCounts 
       ON Org.Organism_ID = OrgCounts.organism_id

GO
GRANT SELECT ON [dbo].[V_Organism_Picker] TO [pnl\d3l243] AS [dbo]
GO
