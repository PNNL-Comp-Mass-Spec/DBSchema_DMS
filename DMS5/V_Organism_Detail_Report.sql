/****** Object:  View [dbo].[V_Organism_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Organism_Detail_Report]
AS
SELECT O.Organism_ID AS ID,
       O.OG_name AS Name,
       O.OG_Short_Name AS [Short Name],
       O.OG_description AS Description,
	   NCBI.Name AS [NCBI Taxonomy],
	   O.NCBI_Taxonomy_ID AS [NCBI Taxonomy ID],
	   NCBI.Synonyms AS [NCBI Synonyms],
	   NCBI.Synonym_List AS [NCBI Synonym List],
       NEWT.Term_Name AS [NEWT Name],
	   dbo.S_GetTaxIDTaxonomyList(NCBI_Taxonomy_ID, 0) AS [Taxonomy List], 
       O.OG_Domain AS Domain,
       O.OG_Kingdom AS Kingdom,
       O.OG_Phylum AS [Phylum (Division)],
       O.OG_Class AS Class,
       O.OG_Order AS [Order],
       O.OG_Family AS Family,
       O.OG_Genus AS Genus,
       O.OG_Species AS Species,
       O.OG_Strain AS Strain,
       O.NEWT_ID_List AS NEWT_ID_List,
       O.OG_created AS Created,
       COUNT(PC.Name) AS [Protein Collections],
       O.OG_Storage_Location AS [Org. Storage Path],
       O.OG_organismDBName AS [Default Protein Collection],
       O.OG_DNA_Translation_Table_ID AS [DNA Trans Table],
       O.OG_Mito_DNA_Translation_Table_ID AS [Mito DNA Trans Table],
       O.OG_Active AS Active,
	   T_YesNo.Description AS [Auto Define Taxonomy]
FROM dbo.T_Organisms O
     INNER JOIN T_YesNo
       ON O.Auto_Define_Taxonomy = T_YesNo.Flag
     LEFT OUTER JOIN
        S_V_CV_NEWT NEWT ON Cast(O.NCBI_Taxonomy_ID as varchar(24)) = NEWT.identifier
     LEFT OUTER JOIN V_Protein_Collection_Name PC
       ON O.OG_Name = PC.[Organism Name]
	 LEFT OUTER JOIN S_V_NCBI_Taxonomy_Cached NCBI 
	   ON O.NCBI_Taxonomy_ID = NCBI.Tax_ID
GROUP BY O.Organism_ID, O.OG_name, O.OG_Genus, O.OG_Species, O.OG_Strain, O.OG_description,
         O.OG_Short_Name, O.OG_Domain, O.OG_Kingdom, O.OG_Phylum, O.OG_Class, O.OG_Order, 
         O.OG_Family, O.NEWT_ID_List, NEWT.Term_Name, O.OG_created, O.OG_Active,
         O.OG_Storage_Location, O.OG_organismDBName, 
         O.OG_DNA_Translation_Table_ID, O.OG_Mito_DNA_Translation_Table_ID,
		 O.NCBI_Taxonomy_ID, NCBI.Name, NCBI.Synonyms, NCBI.Synonym_List,
		 T_YesNo.Description


GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
