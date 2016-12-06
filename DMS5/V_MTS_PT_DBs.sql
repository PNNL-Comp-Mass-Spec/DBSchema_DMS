/****** Object:  View [dbo].[V_MTS_PT_DBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_MTS_PT_DBs]
AS

SELECT PTDBs.Peptide_DB_ID,
       PTDBs.Peptide_DB_Name,
       PTDBs.State,
       PTDBs.Description,
       PTDBs.Organism,
       PTDBs.MSMS_Jobs,       
       PTDBs.SIC_Jobs,
       PTDBs.Server_Name,
       PTDBs.State_ID     
FROM T_MTS_PT_DBs_Cached PTDBs



GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_PT_DBs] TO [DDL_Viewer] AS [dbo]
GO
