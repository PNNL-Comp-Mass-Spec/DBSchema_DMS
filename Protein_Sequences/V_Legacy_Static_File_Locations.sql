/****** Object:  View [dbo].[V_Legacy_Static_File_Locations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Legacy_Static_File_Locations]
AS
SELECT OrgDBInfo.ID,
       OrgDBInfo.FileName As File_Name,
       dbo.combine_paths(Org.OrganismDBPath, OrgDBInfo.FileName) AS Full_Path,
       Org.Organism_ID,
       Org.Name AS Organism_Name,
       Replace(OrgDBInfo.FileName, '.fasta', '') AS Default_Collection_Name,
       IsNull(LFUR.Authentication_Hash, '') AS Authentication_Hash
FROM MT_Main.dbo.T_DMS_Organism_DB_Info OrgDBInfo
     INNER JOIN MT_Main.dbo.T_DMS_Organisms Org
       ON OrgDBInfo.Organism_ID = Org.Organism_ID
     LEFT OUTER JOIN ( SELECT Legacy_Filename AS FileName,
                              Authentication_Hash
                       FROM T_Legacy_File_Upload_Requests ) LFUR
       ON OrgDBInfo.FileName = LFUR.FileName

GO
