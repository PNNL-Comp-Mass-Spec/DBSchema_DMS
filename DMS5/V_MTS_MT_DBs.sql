/****** Object:  View [dbo].[V_MTS_MT_DBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_MTS_MT_DBs]
AS

SELECT MTDBs.MT_DB_ID,
       MTDBs.MT_DB_Name,
       MTDBs.State,
       MTDBs.Description,
       MTDBs.Organism,
       MTDBs.Campaign,
       SUM(CASE
              WHEN ISNULL(DBJobs.ResultType, '') LIKE '%Peptide_Hit' THEN 1
              ELSE 0
          END) AS MSMS_Jobs,
       SUM(CASE
              WHEN ISNULL(DBJobs.ResultType, '') = 'HMMA_Peak' THEN 1
              ELSE 0
          END) AS MS_Jobs,
       MTDBs.Server_Name,
       MTDBs.State_ID
FROM T_MTS_MT_DBs_Cached MTDBs
    LEFT OUTER JOIN T_MTS_MT_DB_Jobs_Cached DBJobs
      ON MTDBs.MT_DB_Name = DBJobs.MT_DB_Name AND
         MTDBs.Server_Name = DBJobs.Server_Name
GROUP BY MTDBs.MT_DB_ID, MTDBs.MT_DB_Name, MTDBs.State,
       MTDBs.Description, MTDBs.Organism, MTDBs.Campaign,
       MTDBs.Server_Name, MTDBs.State_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_MT_DBs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_MT_DBs] TO [PNL\D3M580] AS [dbo]
GO
