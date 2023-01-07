/****** Object:  View [dbo].[V_MTS_MT_DBs_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MTS_MT_DBs_Detail_Report]
AS
SELECT MTDBs.mt_db_name,
       MTDBs.mt_db_id,
       MTDBs.description,
       MTDBs.organism,
       MTDBs.campaign,
       MTDBs.msms_jobs,
       MTDBs.ms_jobs,
       SUM(CASE
               WHEN Task_ID IS NULL THEN 0
               ELSE 1
           END) AS pm_task_count,
       MTDBs.peptide_db,
       MTDBs.peptide_db_count,
       MTDBs.server_name,
       MTDBs.state,
       MTDBs.state_id,
       MTDBs.last_affected
FROM T_MTS_MT_DBs_Cached MTDBs
     LEFT OUTER JOIN T_MTS_Peak_Matching_Tasks_Cached PMTasks
       ON MTDBs.MT_DB_Name = PMTasks.Task_Database
GROUP BY MTDBs.MT_DB_Name, MTDBs.MT_DB_ID, MTDBs.Description, MTDBs.Organism, MTDBs.Campaign,
         MTDBs.MSMS_Jobs, MTDBs.MS_Jobs, MTDBs.Peptide_DB, MTDBs.Peptide_DB_Count,
         MTDBs.Server_Name, MTDBs.State, MTDBs.State_ID, MTDBs.Last_Affected


GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_MT_DBs_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
