/****** Object:  View [dbo].[V_MTS_MT_DBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MTS_MT_DBs]
AS
SELECT MT_DB_ID, MT_DB_Name, State, Description, Organism, 
    Campaign, Server_Name, State_ID
FROM T_MTS_MT_DBs_Cached


GO
