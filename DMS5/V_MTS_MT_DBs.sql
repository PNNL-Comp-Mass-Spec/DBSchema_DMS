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
       MTDBs.MSMS_Jobs,
       MTDBs.MS_Jobs,
       MTDBs.Peptide_DB,
       MTDBs.Server_Name,
       MTDBs.State_ID
FROM T_MTS_MT_DBs_Cached MTDBs
--WHERE NOT MTDBs.State IN ('Deleted', 'Frozen', 'Unused')


GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_MT_DBs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_MT_DBs] TO [PNL\D3M580] AS [dbo]
GO
