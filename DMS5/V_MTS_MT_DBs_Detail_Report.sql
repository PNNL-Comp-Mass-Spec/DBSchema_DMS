/****** Object:  View [dbo].[V_MTS_MT_DBs_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MTS_MT_DBs_Detail_Report]
AS
SELECT LookupQ.MT_DB_Name,
       LookupQ.MT_DB_ID,
       LookupQ.Description,
       LookupQ.Organism,
       LookupQ.Campaign,
       LookupQ.MSMS_Jobs,
       LookupQ.MS_Jobs,
       SUM(CASE
               WHEN Task_ID IS NULL THEN 0
               ELSE 1
           END) AS PM_Task_Count,
       LookupQ.Server_Name,
       LookupQ.State,
       LookupQ.State_ID,
       LookupQ.Last_Affected
FROM ( SELECT MTDBs.MT_DB_Name,
              MTDBs.MT_DB_ID,
              MTDBs.Description,
              MTDBs.Organism,
              MTDBs.Campaign,
              SUM(CASE
                      WHEN ISNULL(ResultType, '') LIKE '%Peptide_Hit' THEN 1
                      ELSE 0
                  END) AS MSMS_Jobs,
              SUM(CASE
                      WHEN ISNULL(ResultType, '') = 'HMMA_Peak' THEN 1
                      ELSE 0
                  END) AS MS_Jobs,
              MTDBs.Server_Name,
              MTDBs.State,
              MTDBs.State_ID,
              MTDBs.Last_Affected
       FROM T_MTS_MT_DBs_Cached MTDBs
            LEFT OUTER JOIN T_MTS_MT_DB_Jobs_Cached DBJobs
              ON MTDBs.MT_DB_Name = DBJobs.MT_DB_Name AND
                 MTDBs.Server_Name = DBJobs.Server_Name
       GROUP BY MTDBs.MT_DB_Name, MTDBs.MT_DB_ID, MTDBs.Description, MTDBs.Organism, MTDBs.Campaign,
                MTDBs.Server_Name, MTDBs.State, MTDBs.State_ID, MTDBs.Last_Affected ) LookupQ
     LEFT OUTER JOIN T_MTS_Peak_Matching_Tasks_Cached PMTasks
       ON LookupQ.MT_DB_Name = PMTasks.Task_Database
GROUP BY LookupQ.MT_DB_Name, LookupQ.MT_DB_ID, LookupQ.Description, LookupQ.Organism, LookupQ.Campaign,
         LookupQ.MSMS_Jobs, LookupQ.MS_Jobs, LookupQ.Server_Name, LookupQ.State, LookupQ.State_ID,
         LookupQ.Last_Affected


GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_MT_DBs_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_MT_DBs_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
