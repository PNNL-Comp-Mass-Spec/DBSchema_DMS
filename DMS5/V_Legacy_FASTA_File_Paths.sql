/****** Object:  View [dbo].[V_Legacy_FASTA_File_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Legacy_FASTA_File_Paths
AS
SELECT     dbo.T_Organism_DB_File.FileName, dbo.T_Organisms.OG_organismDBPath + dbo.T_Organism_DB_File.FileName AS FilePath, 
                      dbo.T_Organisms.Organism_ID
FROM         dbo.T_Organism_DB_File INNER JOIN
                      dbo.T_Organisms ON dbo.T_Organism_DB_File.Organism_ID = dbo.T_Organisms.Organism_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Legacy_FASTA_File_Paths] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Legacy_FASTA_File_Paths] TO [PNL\D3M580] AS [dbo]
GO
