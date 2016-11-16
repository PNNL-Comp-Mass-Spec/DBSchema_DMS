/****** Object:  StoredProcedure [dbo].[usp_MemoryUsageStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC dbo.usp_MemoryUsageStats (@InsertFlag BIT = 0)
AS
/**************************************************************************************************************
**  Purpose: 
**
**  Revision History  
**  
**  Date			Author					Version				Revision  
**  ----------		--------------------	-------------		-------------
**  02/21/2012		Michael Rounds			1.0					Comments creation
**	08/31/2012		Michael Rounds			1.1					Changed VARCHAR to NVARCHAR
**	04/12/2013		Michael Rounds			1.2					Added SQL Server 2012 compatibility - column differences in sys.dm_os_sys_info
**	04/17/2013		Michael Rounds			1.2.1				Fixed Buffer Hit Cache and Buffer Page Life showing 0 for SQL Server 2012
***************************************************************************************************************/
BEGIN
	SET NOCOUNT ON 

	DECLARE @pg_size INT, @Instancename NVARCHAR(50), @MemoryUsageHistoryID INT, @SQLVer NVARCHAR(20)

	SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'

	SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

	CREATE TABLE #TEMP (
		DateStamp DATETIME NOT NULL CONSTRAINT [DF_TEMP_TEMP] DEFAULT (GETDATE()),
		SystemPhysicalMemoryMB NVARCHAR(20),
		SystemVirtualMemoryMB NVARCHAR(20),
		DBUsageMB NVARCHAR(20),
		DBMemoryRequiredMB NVARCHAR(20),
		BufferCacheHitRatio NVARCHAR(20),
		BufferPageLifeExpectancy NVARCHAR(20),	
		BufferPoolCommitMB NVARCHAR(20),
		BufferPoolCommitTgtMB NVARCHAR(20),
		BufferPoolTotalPagesMB NVARCHAR(20),
		BufferPoolDataPagesMB NVARCHAR(20),
		BufferPoolFreePagesMB NVARCHAR(20),
		BufferPoolReservedPagesMB NVARCHAR(20),
		BufferPoolStolenPagesMB NVARCHAR(20),
		BufferPoolPlanCachePagesMB NVARCHAR(20),
		DynamicMemConnectionsMB NVARCHAR(20),
		DynamicMemLocksMB NVARCHAR(20),
		DynamicMemSQLCacheMB NVARCHAR(20),
		DynamicMemQueryOptimizeMB NVARCHAR(20),
		DynamicMemHashSortIndexMB NVARCHAR(20),
		CursorUsageMB NVARCHAR(20)
		)

	SELECT @SQLVer = LEFT(CONVERT(NVARCHAR(20),SERVERPROPERTY('productversion')),4)

	IF CAST(@SQLVer AS NUMERIC(4,2)) < 11
	BEGIN
		-- (SQL 2008R2 And Below)
		EXEC sp_executesql
			N'INSERT INTO #TEMP (SystemPhysicalMemoryMB, SystemVirtualMemoryMB, BufferPoolCommitMB, BufferPoolCommitTgtMB)
			SELECT physical_memory_in_bytes/1048576.0 as [SystemPhysicalMemoryMB],
				 virtual_memory_in_bytes/1048576.0 as [SystemVirtualMemoryMB],
				 (bpool_committed*8)/1024.0 as [BufferPoolCommitMB],
				 (bpool_commit_target*8)/1024.0 as [BufferPoolCommitTgtMB]
			FROM sys.dm_os_sys_info'	
	END
	ELSE BEGIN
		-- (SQL 2012 And Above)
		EXEC sp_executesql
			N'INSERT INTO #TEMP (SystemPhysicalMemoryMB, SystemVirtualMemoryMB, BufferPoolCommitMB, BufferPoolCommitTgtMB)
			SELECT physical_memory_kb/1024.0 as [SystemPhysicalMemoryMB],
				virtual_memory_kb/1024.0 as [SystemVirtualMemoryMB],
				(committed_kb)/1024.0 as [BufferPoolCommitMB],
				(committed_target_kb)/1024.0 as [BufferPoolCommitTgtMB]
		FROM sys.dm_os_sys_info'
	END

	UPDATE #TEMP
	SET [DBUsageMB] = (cntr_value/1024.0)
	FROM sys.dm_os_performance_counters
	WHERE counter_name = 'Total Server Memory (KB)'

	UPDATE #TEMP
	SET [DBMemoryRequiredMB] = (cntr_value/1024.0)
	FROM sys.dm_os_performance_counters
	WHERE counter_name = 'Target Server Memory (KB)'

	UPDATE #TEMP
	SET [BufferPoolTotalPagesMB] = ((cntr_value*@pg_size)/1048576.0)
	FROM sys.dm_os_performance_counters
	WHERE object_name= @Instancename+'Buffer Manager' and counter_name = 'Total pages' 

	UPDATE #TEMP
	SET [BufferPoolDataPagesMB] = ((cntr_value*@pg_size)/1048576.0)
	FROM sys.dm_os_performance_counters
	WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Database pages' 

	UPDATE #TEMP
	SET [BufferPoolFreePagesMB] = ((cntr_value*@pg_size)/1048576.0)
	FROM sys.dm_os_performance_counters
	WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Free pages'

	UPDATE #TEMP
	SET [BufferPoolReservedPagesMB] = ((cntr_value*@pg_size)/1048576.0)
	FROM sys.dm_os_performance_counters
	WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Reserved pages'

	UPDATE #TEMP
	SET [BufferPoolStolenPagesMB] = ((cntr_value*@pg_size)/1048576.0)
	FROM sys.dm_os_performance_counters
	WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Stolen pages'

	UPDATE #TEMP
	SET [BufferPoolPlanCachePagesMB] = ((cntr_value*@pg_size)/1048576.0)
	FROM sys.dm_os_performance_counters
	WHERE object_name=@Instancename+'Plan Cache' and counter_name = 'Cache Pages'  and instance_name = '_Total'

	UPDATE #TEMP
	SET [DynamicMemConnectionsMB] = (cntr_value/1024.0)
	FROM sys.dm_os_performance_counters
	WHERE counter_name = 'Connection Memory (KB)'

	UPDATE #TEMP
	SET [DynamicMemLocksMB] = (cntr_value/1024.0)
	FROM sys.dm_os_performance_counters
	WHERE counter_name = 'Lock Memory (KB)'

	UPDATE #TEMP
	SET [DynamicMemSQLCacheMB] = (cntr_value/1024.0)
	FROM sys.dm_os_performance_counters
	WHERE counter_name = 'SQL Cache Memory (KB)'

	UPDATE #TEMP
	SET [DynamicMemQueryOptimizeMB] = (cntr_value/1024.0)
	FROM sys.dm_os_performance_counters
	WHERE counter_name = 'Optimizer Memory (KB) '

	UPDATE #TEMP
	SET [DynamicMemHashSortIndexMB] = (cntr_value/1024.0)
	FROM sys.dm_os_performance_counters
	WHERE counter_name = 'Granted Workspace Memory (KB) '

	UPDATE #TEMP
	SET [CursorUsageMB] = (cntr_value/1024.0)
	FROM sys.dm_os_performance_counters
	WHERE counter_name = 'Cursor memory usage' and instance_name = '_Total'

	UPDATE #TEMP
	SET [BufferCacheHitRatio] = (a.cntr_value * 1.0 / b.cntr_value) * 100.0
	FROM sys.dm_os_performance_counters  a
	JOIN  (SELECT cntr_value,OBJECT_NAME 
			FROM sys.dm_os_performance_counters  
			WHERE counter_name = 'Buffer cache hit ratio base'
			AND OBJECT_NAME = @Instancename+'Buffer Manager') b 
	ON  a.OBJECT_NAME = b.OBJECT_NAME
	WHERE a.counter_name = 'Buffer cache hit ratio'
	AND a.OBJECT_NAME = @Instancename+'Buffer Manager'

	UPDATE #TEMP
	SET [BufferPageLifeExpectancy] = cntr_value
	FROM sys.dm_os_performance_counters  
	WHERE counter_name = 'Page life expectancy'
	AND OBJECT_NAME = @Instancename+'Buffer Manager'

	SELECT SystemPhysicalMemoryMB, SystemVirtualMemoryMB, DBUsageMB, DBMemoryRequiredMB, BufferCacheHitRatio, BufferPageLifeExpectancy, BufferPoolCommitMB, BufferPoolCommitTgtMB, BufferPoolTotalPagesMB, BufferPoolDataPagesMB, BufferPoolFreePagesMB, BufferPoolReservedPagesMB, BufferPoolStolenPagesMB, BufferPoolPlanCachePagesMB, DynamicMemConnectionsMB, DynamicMemLocksMB, DynamicMemSQLCacheMB, DynamicMemQueryOptimizeMB, DynamicMemHashSortIndexMB, CursorUsageMB FROM #TEMP

	IF @InsertFlag = 1
	BEGIN
		INSERT INTO [dba].dbo.MemoryUsageHistory (SystemPhysicalMemoryMB, SystemVirtualMemoryMB, DBUsageMB, DBMemoryRequiredMB, BufferCacheHitRatio, BufferPageLifeExpectancy, BufferPoolCommitMB, BufferPoolCommitTgtMB, BufferPoolTotalPagesMB, BufferPoolDataPagesMB, BufferPoolFreePagesMB, BufferPoolReservedPagesMB, BufferPoolStolenPagesMB, BufferPoolPlanCachePagesMB, DynamicMemConnectionsMB, DynamicMemLocksMB, DynamicMemSQLCacheMB, DynamicMemQueryOptimizeMB, DynamicMemHashSortIndexMB, CursorUsageMB)
		SELECT SystemPhysicalMemoryMB, SystemVirtualMemoryMB, DBUsageMB, DBMemoryRequiredMB, BufferCacheHitRatio, BufferPageLifeExpectancy, BufferPoolCommitMB, BufferPoolCommitTgtMB, BufferPoolTotalPagesMB, BufferPoolDataPagesMB, BufferPoolFreePagesMB, BufferPoolReservedPagesMB, BufferPoolStolenPagesMB, BufferPoolPlanCachePagesMB, DynamicMemConnectionsMB, DynamicMemLocksMB, DynamicMemSQLCacheMB, DynamicMemQueryOptimizeMB, DynamicMemHashSortIndexMB, CursorUsageMB
		FROM #TEMP
	END

	DROP TABLE #TEMP
END

GO
