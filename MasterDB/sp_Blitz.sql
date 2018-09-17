USE [master];
GO

print 'Get the latest version of sp_Blitz and the related scripts at https://www.brentozar.com/blitz/'


/* Example stored procedure calls */

-- sp_Blitz: detailed server check and stats
--
--Sample execution call with the most common parameters:
EXEC [master].[dbo].[sp_Blitz]
    @CheckUserDatabaseObjects = 1 ,
    @CheckProcedureCache = 0 ,
    @OutputType = 'TABLE' ,
    @OutputProcedureCache = 0 ,
    @CheckProcedureCacheFilter = NULL,
    @CheckServerInfo = 1


-- sp_BlitzIndex, Diagnose Indices
--
EXEC dbo.sp_BlitzIndex @DatabaseName='AdventureWorks';

-- sp_BlitzIndex, detail for a specific table's indices
--
EXEC dbo.sp_BlitzIndex @DatabaseName='AdventureWorks', @SchemaName='Person', @TableName='Person';


-- sp_BlitzCache: examine cached plans to find resource-intensive queries
--
exec sp_BlitzCache @get_help=1

EXEC sp_BlitzCache @top=30, @results = 'Expert'


-- sp_AskBrent: look for major problems slowing down a server
--
EXEC dbo.sp_AskBrent

-- With extra diagnostic info:
EXEC dbo.sp_AskBrent @ExpertMode = 1;

-- Ask any question, get a magic 8-ball response
EXEC dbo.sp_AskBrent 'Is this cursor bad?';
EXEC dbo.sp_askbrent @Question=3


-- sp_BlitzTrace, advanced tracing
--
-- See http://www.brentozar.com/BlitzTrace/


