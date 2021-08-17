/****** Object:  View [dbo].[V_Active_Connections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Active_Connections]
AS
SELECT hostname AS Host,
       program_name AS Application,
       loginame AS LoginName,
       DB_NAME(dbid) AS DBName,
       spid,
       login_time,
       last_batch,
       cmd,
       status
FROM sys.sysprocesses
WHERE dbid > 0 AND
      IsNull(hostname, '') <> ''


GO
