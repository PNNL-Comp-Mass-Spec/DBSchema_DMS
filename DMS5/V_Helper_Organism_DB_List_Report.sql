/****** Object:  View [dbo].[V_Helper_Organism_DB_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_Helper_Organism_DB_List_Report]
AS
SELECT ODF.ID AS ID,
       ODF.FileName AS Name,
       O.OG_name AS Organism,
       ODF.Description,
       ODF.NumProteins,
       ODF.NumResidues,
	   Cast(ODF.Created as date) AS Created,
	   Cast(ODF.File_Size_KB / 1024.0 as Decimal(9,2)) AS Size_MB
FROM dbo.T_Organism_DB_File ODF
     INNER JOIN dbo.T_Organisms O
       ON ODF.Organism_ID = O.Organism_ID
WHERE ODF.Active > 0 And ODF.Valid > 0





GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Organism_DB_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Organism_DB_List_Report] TO [PNL\D3M580] AS [dbo]
GO
