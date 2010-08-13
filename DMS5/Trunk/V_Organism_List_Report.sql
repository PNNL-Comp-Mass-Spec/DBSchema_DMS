/****** Object:  View [dbo].[V_Organism_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Organism_List_Report]
AS
SELECT Organism_ID AS ID,
       OG_name AS Name,
       OG_Genus AS Genus,
       OG_Species AS Species,
       OG_Strain AS Strain,
       OG_description AS Description,
       OG_Short_Name AS Short_Name,
       OG_Domain AS Domain,
       OG_Kingdom AS Kingdom,
       OG_Phylum AS Phylum,
       OG_Class AS Class,
       OG_Order AS [Order],
       OG_Family AS Family,
       OG_created AS Created,
       OG_Active AS Active
FROM dbo.T_Organisms


GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_List_Report] TO [PNL\D3M580] AS [dbo]
GO
