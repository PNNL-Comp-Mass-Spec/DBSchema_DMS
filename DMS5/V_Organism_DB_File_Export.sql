/****** Object:  View [dbo].[V_Organism_DB_File_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Organism_DB_File_Export]
AS
SELECT ODF.ID, 
    ODF.FileName, 
    O.OG_name AS Organism, 
    ODF.Description, 
    ODF.Active, 
    ODF.NumProteins, 
    ODF.NumResidues,
    ODF.Organism_ID,
    ODF.OrgFile_RowVersion,
	ODF.File_Size_KB
FROM dbo.T_Organism_DB_File ODF INNER JOIN
    dbo.T_Organisms O ON 
    ODF.Organism_ID = O.Organism_ID
WHERE Valid > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Organism_DB_File_Export] TO [DDL_Viewer] AS [dbo]
GO
