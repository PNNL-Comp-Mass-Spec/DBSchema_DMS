/****** Object:  View [dbo].[V_MTS_PT_DBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MTS_PT_DBs]
AS

SELECT PTDBs.peptide_db_id,
       PTDBs.peptide_db_name,
       PTDBs.state,
       PTDBs.description,
       PTDBs.organism,
       PTDBs.msms_jobs,
       PTDBs.sic_jobs,
       PTDBs.server_name,
       PTDBs.state_id
FROM T_MTS_PT_DBs_Cached PTDBs


GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_PT_DBs] TO [DDL_Viewer] AS [dbo]
GO
