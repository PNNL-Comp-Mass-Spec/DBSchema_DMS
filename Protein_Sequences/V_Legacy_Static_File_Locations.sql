/****** Object:  View [dbo].[V_Legacy_Static_File_Locations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Legacy_Static_File_Locations]
AS
SELECT ODBF.ID,
       ODBF.FileName,
       Org.OG_organismDBPath + 
         CASE WHEN Org.OG_organismDBPath LIKE '%\' THEN '' ELSE '\' END + 
         ODBF.FileName AS Full_Path,
       Org.Organism_ID,
       Org.OG_name AS Organism_Name,
       LEFT(ODBF.FileName, LEN(ODBF.FileName) - 6) AS Default_Collection_Name,
       IsNull(LFUR.Authentication_Hash, '') AS Authentication_Hash
FROM Gigasax.DMS5.dbo.T_Organism_DB_File ODBF
     INNER JOIN Gigasax.DMS5.dbo.T_Organisms Org
       ON ODBF.Organism_ID = Org.Organism_ID
     LEFT OUTER JOIN ( SELECT Legacy_Filename AS FileName,
                              Authentication_Hash
                       FROM T_Legacy_File_Upload_Requests ) LFUR
       ON ODBF.FileName = LFUR.FileName


GO
