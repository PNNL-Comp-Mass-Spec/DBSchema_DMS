/****** Object:  View [dbo].[V_MTS_PT_DBs_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_MTS_PT_DBs_Detail_Report]
AS
SELECT PTDBs.Peptide_DB_Name,
       PTDBs.Peptide_DB_ID,
       PTDBs.Description,
       PTDBs.Organism,
       SUM(CASE
               WHEN ISNULL(ResultType, '') LIKE '%Peptide_Hit' THEN 1
               ELSE 0
           END) AS MSMS_Jobs,       
       SUM(CASE
               WHEN ISNULL(ResultType, '') = 'SIC' THEN 1
               ELSE 0
           END) AS SIC_Jobs,
       PTDBs.Server_Name,
       PTDBs.State,
       PTDBs.State_ID,
       PTDBs.Last_Affected
FROM T_MTS_PT_DBs_Cached PTDBs
     LEFT OUTER JOIN T_MTS_PT_DB_Jobs_Cached DBJobs
       ON PTDBs.Peptide_DB_Name = DBJobs.Peptide_DB_Name AND
          PTDBs.Server_Name = DBJobs.Server_Name
GROUP BY PTDBs.Peptide_DB_Name, PTDBs.Peptide_DB_ID, PTDBs.Description, 
         PTDBs.Organism, PTDBs.Server_Name, PTDBs.State,
         PTDBs.State_ID, PTDBs.Last_Affected


GO
