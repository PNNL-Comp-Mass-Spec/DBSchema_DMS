/****** Object:  View [dbo].[V_Organism_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Organism_Entry]
AS
SELECT Organism_ID AS id,
       OG_name AS organism,
       OG_organismDBName AS default_protein_collection,
       OG_description AS description,
       OG_Short_Name AS short_name,
       OG_Storage_Location AS storage_location,
       ncbi_taxonomy_id,
       T_YesNo.Description AS auto_define_taxonomy,
       OG_Domain AS domain,
       OG_Kingdom AS kingdom,
       OG_Phylum AS phylum,
       OG_Class AS class,
       OG_Order AS [order],
       OG_Family AS family,
       OG_Genus AS genus,
       OG_Species AS species,
       OG_Strain AS strain,
       newt_id_list,
       OG_Active AS active
FROM dbo.T_Organisms Org
     INNER JOIN T_YesNo
       ON Org.Auto_Define_Taxonomy = T_YesNo.Flag


GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Entry] TO [DDL_Viewer] AS [dbo]
GO
