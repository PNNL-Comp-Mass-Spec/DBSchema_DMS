/****** Object:  UserDefinedFunction [dbo].[dba_GetSQLForSpid] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Function [dbo].[dba_GetSQLForSpid]
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
