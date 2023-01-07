/****** Object:  View [dbo].[V_Organism_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Organism_Detail_Report]
AS
SELECT O.Organism_ID AS id,
       O.OG_name AS name,
       O.OG_Short_Name AS short_name,
       O.OG_description AS description,
       NCBI.Name AS ncbi_taxonomy,
       O.NCBI_Taxonomy_ID AS ncbi_taxonomy_id,
       NCBI.Synonyms AS ncbi_synonyms,
       NCBI.Synonym_List AS ncbi_synonym_list,
       NEWT.Term_Name AS newt_name,
       dbo.S_GetTaxIDTaxonomyList(NCBI_Taxonomy_ID, 0) AS taxonomy_list,
       O.OG_Domain AS domain,
       O.OG_Kingdom AS kingdom,
       O.OG_Phylum AS phylum_or_division,
       O.OG_Class AS class,
       O.OG_Order AS [order],
       O.OG_Family AS family,
       O.OG_Genus AS genus,
       O.OG_Species AS species,
       O.OG_Strain AS strain,
       O.NEWT_ID_List AS newt_id_list,
       O.OG_created AS created,
       COUNT(PC.Name) AS protein_collections,
       O.OG_Storage_Location AS organism_storage_path,
       O.OG_Storage_URL AS organism_storage_link,
       O.OG_organismDBName AS default_protein_collection,
       FASTALookupQ.Legacy_FASTA_Files AS legacy_fasta_files,
       O.OG_Active AS active,
       T_YesNo.Description AS auto_define_taxonomy
FROM dbo.T_Organisms O
     INNER JOIN T_YesNo
       ON O.Auto_Define_Taxonomy = T_YesNo.Flag
     LEFT OUTER JOIN
        S_V_CV_NEWT NEWT ON O.NCBI_Taxonomy_ID = NEWT.identifier
     LEFT OUTER JOIN V_Protein_Collection_Name PC
       ON O.OG_Name = PC.Organism_Name
     LEFT OUTER JOIN S_V_NCBI_Taxonomy_Cached NCBI
       ON O.NCBI_Taxonomy_ID = NCBI.Tax_ID
     LEFT OUTER JOIN (
           SELECT Organism_ID, COUNT(*) AS Legacy_FASTA_Files
           FROM T_Organism_DB_File ODF
           WHERE (Active > 0) AND (Valid > 0)
           GROUP BY Organism_ID ) AS FASTALookupQ
       ON O.Organism_ID = FASTALookupQ.Organism_ID
GROUP BY O.Organism_ID, O.OG_name, O.OG_Genus, O.OG_Species, O.OG_Strain, O.OG_description,
         O.OG_Short_Name, O.OG_Domain, O.OG_Kingdom, O.OG_Phylum, O.OG_Class, O.OG_Order,
         O.OG_Family, O.NEWT_ID_List, NEWT.Term_Name, O.OG_created, O.OG_Active,
         O.OG_Storage_Location, O.OG_Storage_URL, O.OG_organismDBName, FASTALookupQ.Legacy_FASTA_Files,
         O.NCBI_Taxonomy_ID, NCBI.Name, NCBI.Synonyms, NCBI.Synonym_List,
         T_YesNo.Description


GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
