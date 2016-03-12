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
       PTDBs.MSMS_Jobs,       
       PTDBs.SIC_Jobs,
       dbo.GetMTDBsForPeptideDB(PTDBs.Peptide_DB_Name) AS Mass_Tag_DBs,
       PTDBs.Server_Name,
       PTDBs.State,
       PTDBs.State_ID,
       PTDBs.Last_Affected
FROM T_MTS_PT_DBs_Cached PTDBs



GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_PT_DBs_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
