/****** Object:  View [dbo].[V_Organism_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Organism_Export]
AS
SELECT DISTINCT O.Organism_ID,
                O.OG_name AS Name,
                O.OG_description AS Description,
                O.OG_Short_Name AS Short_Name,
                NCBI.Name AS NCBI_Taxonomy,
                O.NCBI_Taxonomy_ID AS NCBI_Taxonomy_ID,
                NCBI.Synonyms AS NCBI_Synonyms,
                O.OG_Domain AS Domain,
                O.OG_Kingdom AS Kingdom,
                O.OG_Phylum AS Phylum,
                O.OG_Class AS Class,
                O.OG_Order AS [Order],
                O.OG_Family AS Family,
                O.OG_Genus AS Genus,
                O.OG_Species AS Species,
                O.OG_Strain AS Strain,
                O.OG_DNA_Translation_Table_ID AS DNA_Translation_Table_ID,
                O.OG_Mito_DNA_Translation_Table_ID AS Mito_DNA_Translation_Table_ID,
                O.NCBI_Taxonomy_ID AS NEWT_ID,
                NEWT.Term_Name AS NEWT_Name,
                O.NEWT_ID_List AS NEWT_ID_List,
                O.OG_created AS Created,
                O.OG_Active AS Active,
                O.OG_organismDBPath AS OrganismDBPath,
                O.OG_RowVersion
FROM dbo.T_Organisms O
     LEFT OUTER JOIN S_V_CV_NEWT NEWT
       ON CONVERT(varchar(24), O.NCBI_Taxonomy_ID) = NEWT.identifier
     LEFT OUTER JOIN S_V_NCBI_Taxonomy_Cached NCBI
       ON O.NCBI_Taxonomy_ID = NCBI.Tax_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Export] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Export] TO [PNL\D3M580] AS [dbo]
GO
