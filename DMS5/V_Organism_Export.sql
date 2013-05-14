/****** Object:  View [dbo].[V_Organism_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[V_Organism_Export]
AS
SELECT Organism_ID,
       OG_name AS Name,
       OG_description AS Description,
       OG_Short_Name AS Short_Name,
       OG_Domain AS Domain,
       OG_Kingdom AS Kingdom,
       OG_Phylum AS Phylum,
       OG_Class AS Class,
       OG_Order AS [Order],
       OG_Family AS Family,
       OG_Genus AS Genus,
       OG_Species AS Species,
       OG_Strain AS Strain,
       OG_DNA_Translation_Table_ID AS DNA_Translation_Table_ID,
       OG_Mito_DNA_Translation_Table_ID AS Mito_DNA_Translation_Table_ID,
       NEWT_Identifier AS NEWT_ID,
       OG_created AS Created,
       OG_Active AS Active,
       OG_organismDBPath AS OrganismDBPath,
       OG_RowVersion
FROM dbo.T_Organisms



GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Export] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Export] TO [PNL\D3M580] AS [dbo]
GO
