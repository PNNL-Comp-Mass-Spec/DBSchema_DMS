use master
GO
CREATE PROC [dbo].[dba_BlockTracer]
AS
/*--------------------------------------------------
 
Purpose: Shows details of the root blocking process, together with details of any blocked processed

----------------------------------------------------

Parameters: None.

Revision History:
      19/07/2007   Ian_Stirk@yahoo.com Initial version

Example Usage:
   1. exec YourServerName.master.dbo.dba_BlockTracer

--------------------------------------------------*/

BEGIN

   -- Do not lock anything, and do not get held up by any locks. 
   SET TRANSACTION ISOLATION LEVEL READ 
      UNCOMMITTED

   -- If there are blocked processes...
   IF EXISTS(SELECT 1 FROM sys.sysprocesses WHERE 
      blocked != 0) 
   BEGIN

      -- Identify the root-blocking spid(s)
      SELECT  distinct t1.spid  AS [Root blocking spids]
         , t1.[loginame] AS [Owner]
         , master.dbo.dba_GetSQLForSpid(t1.spid) AS 
            'SQL Text' 
         , t1.[cpu]
         , t1.[physical_io]
         , DatabaseName = DB_NAME(t1.[dbid])
         , t1.[program_name]
         , t1.[hostname]
         , t1.[status]
         , t1.[cmd]
         , t1.[blocked]
         , t1.[ecid] 
      FROM  sys.sysprocesses t1, sys.sysprocesses t2
      WHERE t1.spid = t2.blocked
        AND t1.ecid = t2.ecid
        AND t1.blocked = 0 
      ORDER BY t1.spid, t1.ecid

      -- Identify the spids being blocked.
      SELECT t2.spid AS 'Blocked spid'
         , t2.blocked AS 'Blocked By'
         , t2.[loginame] AS [Owner]
         , master.dbo.dba_GetSQLForSpid(t2.spid) AS 
            'SQL Text' 
         , t2.[cpu]
         , t2.[physical_io]
         , DatabaseName = DB_NAME(t2.[dbid])
         , t2.[program_name]
         , t2.[hostname]
         , t2.[status]
         , t2.[cmd]
         , t2.ecid
      FROM sys.sysprocesses t1, sys.sysprocesses t2 
      WHERE t1.spid = t2.blocked
        AND t1.ecid = t2.ecid
      ORDER BY t2.blocked, t2.spid, t2.ecid
   END

   ELSE -- No blocked processes.
      PRINT 'No processes blocked.' 

END
GO

CREATE Function [dbo].[dba_GetSQLForSpid]
(
   @spid SMALLINT
)
RETURNS NVARCHAR(4000)

/*-------------------------------------------------

Purpose:   Returns the SQL text for a given spid.

---------------------------------------------------

Parameters:   @spid   - SQL Server process ID.
Returns:   @SqlText - SQL text for a given spid.
Revision History:
      01/12/2006   Ian_Stirk@yahoo.com Initial version
Example Usage:
   SELECT dbo.dba_GetSQLForSpid(51)
   SELECT dbo.dba_GetSQLForSpid(spid) AS [SQL text]
      , * FROM sys.sysprocesses WITH (NOLOCK) 

--------------------------------------------------*/

BEGIN
   DECLARE @SqlHandle BINARY(20)
   DECLARE @SqlText NVARCHAR(4000)
   -- Get sql_handle for the given spid.
   SELECT @SqlHandle = sql_handle 
      FROM sys.sysprocesses WITH (nolock) WHERE 
      spid = @spid
   -- Get the SQL text for the given sql_handle.
   SELECT @SqlText = [text] FROM 
      sys.dm_exec_sql_text(@SqlHandle)
   RETURN @SqlText

END
GO

-- Example Usage
exec dbo.dba_BlockTracer
