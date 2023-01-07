/****** Object:  View [dbo].[V_Organism_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Organism_List_Report]
AS

SELECT O.Organism_ID AS id,
       O.OG_name AS name,
       O.OG_Genus AS genus,
       O.OG_Species AS species,
       O.OG_Strain AS strain,
       O.OG_description AS description,
       COUNT(PC.Name) AS protein_collections,
       O.OG_organismDBName AS default_protein_collection,
       O.OG_Short_Name AS short_name,
	   NCBI.Name AS ncbi_taxonomy,
	   O.NCBI_Taxonomy_ID AS ncbi_taxonomy_id,
	   NCBI.Synonyms AS ncbi_synonyms,
       O.OG_Storage_Location AS storage_path,
       O.OG_Domain AS domain,
       O.OG_Kingdom AS kingdom,
       O.OG_Phylum AS phylum,
       O.OG_Class AS class,
       O.OG_Order AS [order],
       O.OG_Family AS family,
	   FASTALookupQ.Legacy_FASTA_Files AS legacy_fastas,
       O.OG_created AS created,
       O.OG_Active AS active
FROM dbo.T_Organisms O
     LEFT OUTER JOIN V_Protein_Collection_Name PC
       ON O.OG_Name = PC.Organism_Name
     LEFT OUTER JOIN S_V_NCBI_Taxonomy_Cached NCBI
	   ON O.NCBI_Taxonomy_ID = NCBI.Tax_ID
	 LEFT OUTER JOIN (SELECT Organism_ID, COUNT(*) AS Legacy_FASTA_Files
		FROM T_Organism_DB_File ODF
		WHERE (Active > 0) AND (Valid > 0)
		GROUP BY Organism_ID) AS FASTALookupQ ON O.Organism_ID = FASTALookupQ.Organism_ID
GROUP BY O.Organism_ID, O.OG_name, O.OG_Genus, O.OG_Species, O.OG_Strain,
         O.OG_description, O.OG_organismDBName, O.OG_Short_Name, O.OG_Storage_Location,
         O.OG_Domain, O.OG_Kingdom, O.OG_Phylum, O.OG_Class, O.OG_Order, O.OG_Family, O.OG_created, O.OG_Active,
		 O.NCBI_Taxonomy_ID, NCBI.Name, NCBI.Synonyms, FASTALookupQ.Legacy_FASTA_Files


GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_List_Report] TO [DDL_Viewer] AS [dbo]
GO
