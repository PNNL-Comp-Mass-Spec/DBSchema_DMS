/****** Object:  View [dbo].[V_MTS_MT_DBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MTS_MT_DBs]
AS

SELECT MTDBs.mt_db_id,
       MTDBs.mt_db_name,
       MTDBs.state,
       MTDBs.description,
       MTDBs.organism,
       MTDBs.campaign,
       MTDBs.msms_jobs,
       MTDBs.ms_jobs,
       MTDBs.peptide_db,
       MTDBs.server_name,
       MTDBs.state_id
FROM T_MTS_MT_DBs_Cached MTDBs
--WHERE NOT MTDBs.State IN ('Deleted', 'Frozen', 'Unused')


GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_MT_DBs] TO [DDL_Viewer] AS [dbo]
GO
