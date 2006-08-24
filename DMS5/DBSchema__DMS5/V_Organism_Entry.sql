/****** Object:  View [dbo].[V_Organism_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Organism_Entry
AS
SELECT    
Organism_ID AS ID,
OG_name AS orgName,
OG_organismDBPath AS orgDBPath,
OG_organismDBLocalPath AS orgDBLocalPath,
OG_organismDBName AS orgDBName,
OG_description AS orgDescription,
OG_Short_Name AS orgShortName,
OG_Storage_Location AS orgStorageLocation,
OG_Domain AS orgDomain,
OG_Kingdom AS orgKingdom,
OG_Phylum AS orgPhylum,
OG_Class AS orgClass,
OG_Order AS orgOrder,
OG_Family AS orgFamily,
OG_Genus AS orgGenus,
OG_Species AS orgSpecies,
OG_Strain AS orgStrain,
OG_DNA_Translation_Table_ID as orgDNATransTabID, 
OG_Mito_DNA_Translation_Table_ID as orgMitoDNATransTabID
FROM         T_Organisms

GO
