/****** Object:  View [dbo].[V_Helper_Organism_DB_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Helper_Organism_DB_List_Report]
AS
SELECT ODF.ID AS id,
       ODF.FileName AS name,
       O.OG_name AS organism,
       ODF.description,
       ODF.NumProteins AS num_proteins,
       ODF.NumResidues AS num_residues,
	   Cast(ODF.Created AS date) AS created,
	   Cast(ODF.File_Size_KB / 1024.0 AS Decimal(9,2)) AS size_mb
FROM dbo.T_Organism_DB_File ODF
     INNER JOIN dbo.T_Organisms O
       ON ODF.Organism_ID = O.Organism_ID
WHERE ODF.Active > 0 And ODF.Valid > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Organism_DB_List_Report] TO [DDL_Viewer] AS [dbo]
GO
