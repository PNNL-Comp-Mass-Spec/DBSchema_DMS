/****** Object:  View [dbo].[V_Organism_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_Organism_Detail_Report]
AS
SELECT Organism_ID AS ID, OG_name AS Name, 
    OG_Short_Name AS [Short Name], 
    OG_description AS Description, OG_Domain AS Domain, 
    OG_Kingdom AS Kingdom, OG_Phylum AS Phylum, 
    OG_Class AS Class, OG_Order AS [Order], 
    OG_Family AS Family, OG_Genus AS Genus, 
    OG_Species AS Species, OG_Strain AS Strain, 
    OG_created AS Created, 
    OG_organismDBPath AS [Org. DB File Storage Path], 
     OG_organismDBName AS [Default Org. DB file name], 
    OG_Storage_Location AS [File Archive Path], 
    OG_DNA_Translation_Table_ID AS [DNA Trans Table], 
    OG_Mito_DNA_Translation_Table_ID AS [Mito DNA Trans Table],
     OG_Active AS Active
FROM dbo.T_Organisms



GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
