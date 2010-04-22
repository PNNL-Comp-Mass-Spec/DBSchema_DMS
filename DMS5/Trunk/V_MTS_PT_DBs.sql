/****** Object:  View [dbo].[V_MTS_PT_DBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MTS_PT_DBs]
AS
SELECT Peptide_DB_ID, Peptide_DB_Name, State, Description, 
    Organism, Server_Name, State_ID
FROM T_MTS_PT_DBs_Cached



GO
