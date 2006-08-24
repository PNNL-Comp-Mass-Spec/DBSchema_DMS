/****** Object:  View [dbo].[V_Organism_DB_File_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Organism_DB_File_Export
AS
SELECT dbo.T_Organism_DB_File.ID, 
    dbo.T_Organism_DB_File.FileName, 
    dbo.T_Organisms.OG_name AS Organism, 
    dbo.T_Organism_DB_File.Description, 
    dbo.T_Organism_DB_File.Active, 
    dbo.T_Organism_DB_File.NumProteins, 
    dbo.T_Organism_DB_File.NumResidues
FROM dbo.T_Organism_DB_File INNER JOIN
    dbo.T_Organisms ON 
    dbo.T_Organism_DB_File.Organism_ID = dbo.T_Organisms.Organism_ID

GO
