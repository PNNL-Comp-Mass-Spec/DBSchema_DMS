USE [master];
GO

print 'Get the latest version of sp_Blitz and the related scripts at http://www.brentozar.com/blitz/'


/* Example stored procedure calls */

-- sp_Blitz
--
--Sample execution call with the most common parameters:
EXEC [master].[dbo].[sp_Blitz]
    @CheckUserDatabaseObjects = 1 ,
    @CheckProcedureCache = 0 ,
    @OutputType = 'TABLE' ,
    @OutputProcedureCache = 0 ,
    @CheckProcedureCacheFilter = NULL,
    @CheckServerInfo = 1


-- sp_BlitzIndex, Diagnose
--
EXEC dbo.sp_BlitzIndex @DatabaseName='AdventureWorks';

-- sp_BlitzIndex, detail for a specific table
--
EXEC dbo.sp_BlitzIndex @DatabaseName='AdventureWorks', @SchemaName='Person', @TableName='Person';


-- sp_BlitzCache
--
exec sp_BlitzCache


-- sp_AskBrent
--
EXEC dbo.sp_AskBrent

With extra diagnostic info:
EXEC dbo.sp_AskBrent @ExpertMode = 1;

In Ask a Question mode:
EXEC dbo.sp_AskBrent 'Is this cursor bad?';

-- sp_BlitzTrace, advanced tracing
-- See http://www.brentozar.com/BlitzTrace/
