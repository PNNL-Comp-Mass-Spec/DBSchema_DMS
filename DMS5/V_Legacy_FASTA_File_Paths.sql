/****** Object:  View [dbo].[V_Legacy_FASTA_File_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Legacy_FASTA_File_Paths
AS
SELECT OrgDB.FileName AS file_name,
       Org.OG_organismDBPath + OrgDB.FileName AS file_path,
       Org.Organism_ID AS organism_id,
       OrgDB.FileName,
       Org.OG_organismDBPath + OrgDB.FileName AS FilePath
FROM dbo.T_Organism_DB_File OrgDB
     INNER JOIN dbo.T_Organisms Org
       ON OrgDB.Organism_ID = Org.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Legacy_FASTA_File_Paths] TO [DDL_Viewer] AS [dbo]
GO
