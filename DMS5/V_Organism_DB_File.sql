/****** Object:  View [dbo].[V_Organism_DB_File] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Organism_DB_File]
AS
SELECT OrgDBFile.ID,
       OrgDBFile.FileName,
       OrgDBFile.Organism_ID,
       Org.OG_name,
       OrgDBFile.Description,
       OrgDBFile.NumProteins,
       OrgDBFile.NumResidues,
       OrgDBFile.Valid,
       OrgDBFile.File_Size_KB,
       OrgDBFile.Active,
       OrgDBFile.OrgFile_RowVersion,
       Org.OG_organismDBPath AS Folder_Server,
       Replace(Org.OG_organismDBPath, MPath.Server, MPath.Client) AS Folder_Client
FROM T_Organism_DB_File OrgDBFile
     INNER JOIN T_Organisms Org
       ON OrgDBFile.Organism_ID = Org.Organism_ID
     CROSS JOIN ( SELECT Server, Client
                  FROM T_MiscPaths
                  WHERE ([Function] = 'DMSOrganismFiles') ) AS MPath


GO
