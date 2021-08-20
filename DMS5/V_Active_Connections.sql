/****** Object:  View [dbo].[V_Active_Connections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Active_Connections]
AS
SELECT Rtrim(Cast(hostname AS nvarchar(128))) AS Host,
       Rtrim(Cast(program_name AS nvarchar(128))) AS Application,
       Rtrim(Cast(loginame AS nvarchar(128))) AS LoginName,
       DB_NAME(dbid) AS DBName,
       spid,
       login_time,
       last_batch,
       Rtrim(Cast(cmd AS nvarchar(32))) AS cmd,
       Rtrim(Cast(Status AS nvarchar(32))) Status
FROM sys.sysprocesses
WHERE dbid > 0 AND
      IsNull(hostname, '') <> ''

GO
