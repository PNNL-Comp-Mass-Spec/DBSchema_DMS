/****** Object:  View [dbo].[V_Organism_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Organism_List_Report]
AS
SELECT O.Organism_ID AS ID,
       O.OG_name AS Name,
       O.OG_Genus AS Genus,
       O.OG_Species AS Species,
       O.OG_Strain AS Strain,
       O.OG_description AS Description,
       COUNT(PC.Name) AS [Protein Collections],
       O.OG_organismDBName AS [Default Protein Collection],
       O.OG_Short_Name AS Short_Name,
       O.OG_Domain AS Domain,
       O.OG_Kingdom AS Kingdom,
       O.OG_Phylum AS Phylum,
       O.OG_Class AS Class,
       O.OG_Order AS [Order],
       O.OG_Family AS Family,
       O.OG_created AS Created,
       O.OG_Active AS Active
FROM dbo.T_Organisms O
     LEFT OUTER JOIN V_Protein_Collection_Name PC
       ON O.OG_Name = PC.[Organism Name]
GROUP BY O.Organism_ID, O.OG_name, O.OG_Genus, O.OG_Species, O.OG_Strain, O.OG_description, O.OG_organismDBName, O.OG_Short_Name,
         O.OG_Domain, O.OG_Kingdom, O.OG_Phylum, O.OG_Class, O.OG_Order, O.OG_Family, O.OG_created, O.OG_Active



GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_List_Report] TO [PNL\D3M580] AS [dbo]
GO
