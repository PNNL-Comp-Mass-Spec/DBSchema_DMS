/****** Object:  View [dbo].[V_MTS_PT_DBs_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_MTS_PT_DBs_Detail_Report]
AS
SELECT PTDBs.peptide_db_name,
       PTDBs.peptide_db_id,
       PTDBs.description,
       PTDBs.organism,
       PTDBs.msms_jobs,
       PTDBs.sic_jobs,
       dbo.get_mtdbs_for_peptide_db(PTDBs.Peptide_DB_Name) AS mass_tag_dbs,
       PTDBs.server_name,
       PTDBs.state,
       PTDBs.state_id,
       PTDBs.last_affected
FROM T_MTS_PT_DBs_Cached PTDBs

GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_PT_DBs_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
