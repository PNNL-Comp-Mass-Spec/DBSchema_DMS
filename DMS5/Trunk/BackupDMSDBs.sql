/****** Object:  StoredProcedure [dbo].[BackupDMSDBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.BackupDMSDBs
/****************************************************
**
**	Desc: Uses Red-Gate's SQL Backup software to backup the specified databases
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	05/23/2006
**			05/25/2006 mem - Expanded functionality
**			07/02/2006 mem - Now combining the status log files created by SQL Backup into a single text file for each backup session
**			08/26/2006 mem - Updated to use GetServerVersionInfo
**			10/27/2006 mem - Added parameter @DaysToKeepOldBackups
**			05/02/2007 mem - Added parameters @BackupBatchSize and @UseLocalTransferFolder
**						   - Replaced parameter @FileAndThreadCount with parameters @FileCount and @ThreadCount
**						   - Upgraded for use with Sql Backup 5 (replacing the Threads argument with the ThreadCount argument)
**			05/31/2007 mem - Now including FILEOPTIONS only if @UseLocalTransferFolder is non-zero
**			09/07/2007 mem - Now returning the contents of #Tmp_DB_Backup_List when @InfoOnly = 1
**			11/08/2007 mem - Ported to DMS
**			07/20/2009 mem - Upgraded for use with Sql Backup 6
**						   - Added parameters @DiskRetryIntervalSec, @DiskRetryCount, and CompressionLevel
**						   - Changed the default number of threads to 3
**						   - Changed the default compression level to 4
**    
*****************************************************/
(
	@BackupFolderRoot varchar(128) = '',			-- If blank, then looks up the value in T_MiscPaths
	@DBNameMatchList varchar(2048) = 'DMS%',		-- Comma-separated list of databases on this server to include; can include wildcard symbols since used with a LIKE clause.  Leave blank to ignore this parameter
	@TransactionLogBackup tinyint = 0,				-- Set to 0 for a full backup, 1 for a transaction log backup
	@IncludeSystemDBs tinyint = 0,					-- Set to 1 to include master, model and MSDB databases; these always get full DB backups since transaction log backups are not allowed
	@FileCount tinyint = 1,							-- Set to 2 or 3 to create multiple backup files (will automatically use one thread per file); If @FileCount is > 1, then @ThreadCount is ignored
	@ThreadCount tinyint = 3,						-- Set to 2 or higher (up to the number of cores on the server) to use multiple compression threads but create just a single output file; @FileCount must be 1 if @ThreadCount is > 1
	@DaysToKeepOldBackups smallint = 20,			-- Defines the number of days worth of backup files to retain; files older than @DaysToKeepOldBackups days prior to the present will be deleted; minimum value is 3
	@Verify tinyint = 1,							-- Set to 1 to verify each backup
	@InfoOnly tinyint = 1,							-- Set to 1 to display the Backup SQL that would be run
	@BackupBatchSize tinyint = 32,					-- If greater than 1, then sends Sql Backup a comma separated list of databases to backup (up to 32 DBs at a time); this is much more efficient than calling Sql Backup with one database at a time, but has a downside of inability to explicitly define the log file names
	@UseLocalTransferFolder tinyint = 0,			-- Set to 1 to backup to the local "Redgate Backup Transfer Folder" then copy the file to @BackupFolderRoot; only used if @BackupFolderRoot starts with "\\"
	@DiskRetryIntervalSec smallint = 30,			-- Set to non-zero value to specify that the backup should be re-tried if a network error occurs; this is the delay time before the retry occurs
	@DiskRetryCount smallint = 10,					-- When @DiskRetryIntervalSec is non-zero, this specifies the maximum number of times to retry the backup
	@CompressionLevel tinyint = 4,					-- 1 is the fastest backup, but the largest file size; 4 is the slowest backup, but the smallest file size
	@message varchar(2048) = '' OUTPUT
)
As	
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @ExitCode int
	Declare @SqlErrorCode int

	---------------------------------------
	-- Validate the inputs
	---------------------------------------
	Set @BackupFolderRoot = IsNull(@BackupFolderRoot, '')
	Set @DBNameMatchList = LTrim(RTrim(IsNull(@DBNameMatchList, '')))

	Set @TransactionLogBackup = IsNull(@TransactionLogBackup, 0)
	Set @IncludeSystemDBs = IsNull(@IncludeSystemDBs, 0)
	
	Set @FileCount = IsNull(@FileCount, 1)
	Set @ThreadCount = IsNull(@ThreadCount, 1)
	If @FileCount < 1
		Set @FileCount = 1
	If @FileCount > 10
		Set @FileCount = 10
	
	If @ThreadCount < 1
		Set @ThreadCount = 1
	If @ThreadCount > 4
		Set @ThreadCount = 4
	
	Set @BackupBatchSize = IsNull(@BackupBatchSize, 32)
	If @BackupBatchSize < 1
		Set @BackupBatchSize = 1
	If @BackupBatchSize > 32
		Set @BackupBatchSize = 32
	
	Set @Verify = IsNull(@Verify, 0)
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	Set @UseLocalTransferFolder = IsNull(@UseLocalTransferFolder, 0)
	If @UseLocalTransferFolder <> 0
		Set @UseLocalTransferFolder = 1

	Set @DaysToKeepOldBackups = IsNull(@DaysToKeepOldBackups, 20)
	If @DaysToKeepOldBackups < 3
		Set @DaysToKeepOldBackups = 3

	Set @DiskRetryIntervalSec = IsNull(@DiskRetryIntervalSec, 0)
	If @DiskRetryIntervalSec < 0
		Set @DiskRetryIntervalSec = 0
	If @DiskRetryIntervalSec > 1800
		Set @DiskRetryIntervalSec = 1800
		
	Set @DiskRetryCount = IsNull(@DiskRetryCount, 10)
	If @DiskRetryCount < 1
		Set @DiskRetryCount = 1
	If @DiskRetryCount > 50
		Set @DiskRetryCount = 50

	Set @CompressionLevel = IsNull(@CompressionLevel, 3)
	If @CompressionLevel < 1 Or @CompressionLevel > 4
		Set @CompressionLevel = 3

	Set @message = ''

	---------------------------------------
	-- Define the local variables
	---------------------------------------
	Declare @DBName varchar(255)
	Declare @DBList varchar(max)
	Declare @DBsProcessed varchar(max)
	Set @DBsProcessed = ''
	
	Declare @DBListMaxLength int
	Set @DBListMaxLength = 25000

	Declare @DBsProcessedMaxLenth int
	Set @DBsProcessedMaxLenth = 1250

	Declare @Sql varchar(max)
	Declare @SqlRestore varchar(max)
	
	Declare @BackupType varchar(32)
	Declare @BackupTime varchar(64)
	Declare @BackupFileBaseName varchar(512)
	Declare @BackupFileBasePath varchar(1024)
	Declare @LocalTransferFolderRoot varchar(512)

	Declare @BackupFileList varchar(2048)
	Declare @Periods varchar(6)
	
	Declare @continue tinyint
	Declare @AddDBsToBatch tinyint
	
	Declare @FullDBBackupMatchMode tinyint
	Declare @CharLoc int
	Declare @DBBackupFullCount int
	Declare @DBBackupTransCount int
	Declare @DBCountInBatch int
	
	Set @DBBackupFullCount = 0
	Set @DBBackupTransCount = 0

	---------------------------------------
	-- Validate @BackupFolderRoot
	---------------------------------------
	Set @BackupFolderRoot = LTrim(RTrim(@BackupFolderRoot))
	If Len(@BackupFolderRoot) = 0
	Begin
		SELECT @BackupFolderRoot = "Server"
		FROM T_MiscPaths
		WHERE ("Function" = 'Database Backup Path')
	End
	
	Set @BackupFolderRoot = LTrim(RTrim(@BackupFolderRoot))
	If Len(@BackupFolderRoot) = 0
	Begin
		Set @myError = 50000
		Set @message = 'Backup path not defined via @BackupFolderRoot parameter, and could not be found in table T_MiscPaths'
		Goto Done
	End
	
	If Right(@BackupFolderRoot, 1) <> '\'
		Set @BackupFolderRoot = @BackupFolderRoot + '\'
	
	-- Set @UseLocalTransferFolder to 0 if @BackupFolderRoot does not point to a network share
	If Left(@BackupFolderRoot, 2) <> '\\'
		Set @UseLocalTransferFolder = 0
		
	---------------------------------------
	-- Define @DBBackupStatusLogPathBase
	---------------------------------------
	Declare @DBBackupStatusLogPathBase varchar(512)
	Declare @DBBackupStatusLogFileName varchar(512)
	
	Set @DBBackupStatusLogPathBase = ''
	SELECT @DBBackupStatusLogPathBase = "Server"
	FROM T_MiscPaths
	WHERE ("Function" = 'Database Backup Log Path')
	
	If Len(@DBBackupStatusLogPathBase) = 0
	Begin
		Set @message = 'Could not find entry ''Database Backup Log Path'' in table T_MiscPaths; assuming E:\SqlServerBackup\'
		Execute PostLogEntry 'Error', @message, 'BackupDMSDBs'
		Set @message = ''
		
		Set @DBBackupStatusLogPathBase = 'E:\SqlServerBackup\'
	End

	If Right(@DBBackupStatusLogPathBase, 1) <> '\'
		Set @DBBackupStatusLogPathBase = @DBBackupStatusLogPathBase + '\'
	
	If @UseLocalTransferFolder <> 0
	Begin
		---------------------------------------
		-- Define @LocalTransferFolderRoot
		---------------------------------------
		Set @LocalTransferFolderRoot = ''
		SELECT @LocalTransferFolderRoot = "Server"
		FROM T_MiscPaths
		WHERE ("Function" = 'Redgate Backup Transfer Folder')
		
		If Len(@LocalTransferFolderRoot) = 0
		Begin
			Set @message = 'Could not find entry ''Redgate Backup Transfer Folder'' in table T_MiscPaths; assuming C:\'
			Execute PostLogEntry 'Error', @message, 'BackupDMSDBs'
			Set @message = ''
			
			Set @LocalTransferFolderRoot = 'C:\'
		End

		If Right(@LocalTransferFolderRoot, 1) <> '\'
			Set @LocalTransferFolderRoot = @LocalTransferFolderRoot + '\'
	End

	---------------------------------------
	-- Define the summary status file file path (only used if @BackupBatchSize = 1)
	---------------------------------------
	Declare @DBBackupStatusLogSummary varchar(512)

	Set @BackupTime = Convert(varchar(64), GetDate(), 120 )
	Set @BackupTime = Replace(Replace(Replace(@BackupTime, ' ', '_'), ':', ''), '-', '')

	If @TransactionLogBackup = 0
		Set @DBBackupStatusLogSummary = @DBBackupStatusLogPathBase + 'DB_Backup_Full_' + @BackupTime + '.txt'
	Else
		Set @DBBackupStatusLogSummary = @DBBackupStatusLogPathBase + 'DB_Backup_Log_' + @BackupTime + '.txt'

	---------------------------------------
	-- Create a temporary table to hold the databases to process
	---------------------------------------
	If Exists (SELECT [Name] FROM sysobjects WHERE [Name] = '#Tmp_DB_Backup_List')
		DROP TABLE #Tmp_DB_Backup_List

	CREATE TABLE #Tmp_DB_Backup_List (
		DatabaseName varchar(255) NOT NULL,
		Recovery_Model varchar(64) NOT NULL DEFAULT 'Unknown',
		Perform_Full_DB_Backup tinyint NOT NULL DEFAULT 0
	)

	CREATE CLUSTERED INDEX #IX_Tmp_DB_Backup_List ON #Tmp_DB_Backup_List (DatabaseName)


	If Exists (SELECT [Name] FROM sysobjects WHERE [Name] = '#Tmp_Current_Batch')
		DROP TABLE #Tmp_Current_Batch

	CREATE TABLE #Tmp_Current_Batch (
		DatabaseName varchar(255) NOT NULL,
		IncludeDB tinyint NOT NULL Default(0)
	)

	CREATE CLUSTERED INDEX #IX_Tmp_Current_Batch ON #Tmp_Current_Batch (DatabaseName)

	---------------------------------------
	-- Optionally include the system databases
	-- Note that system DBs are forced to perform a full backup, even if @TransactionLogBackup = 1
	---------------------------------------
	If @IncludeSystemDBs <> 0
	Begin
		INSERT INTO #Tmp_DB_Backup_List (DatabaseName, Perform_Full_DB_Backup) VALUES ('Master', 1)
		INSERT INTO #Tmp_DB_Backup_List (DatabaseName, Perform_Full_DB_Backup) VALUES ('Model', 1)
		INSERT INTO #Tmp_DB_Backup_List (DatabaseName, Perform_Full_DB_Backup) VALUES ('MSDB', 1)
	End


	---------------------------------------
	-- Look for databases on this server that match @DBNameMatchList
	---------------------------------------
	If Len(@DBNameMatchList) > 0
	Begin
		-- Make sure @DBNameMatchList ends in a comma
		If Right(@DBNameMatchList,1) <> ','
			Set @DBNameMatchList = @DBNameMatchList + ','

		-- Split @DBNameMatchList on commas and loop

		Set @continue = 1
		While @continue <> 0
		Begin
			Set @CharLoc = CharIndex(',', @DBNameMatchList)
			
			If @CharLoc <= 0
				Set @continue = 0
			Else
			Begin
				Set @DBName = LTrim(RTrim(SubString(@DBNameMatchList, 1, @CharLoc-1)))
				Set @DBNameMatchList = LTrim(SubString(@DBNameMatchList, @CharLoc+1, Len(@DBNameMatchList) - @CharLoc))

				Set @Sql = ''
				Set @Sql = @Sql + ' INSERT INTO #Tmp_DB_Backup_List (DatabaseName)'
				Set @Sql = @Sql + ' SELECT [Name]'
				Set @Sql = @Sql + ' FROM master.dbo.sysdatabases SD LEFT OUTER JOIN '
				Set @Sql = @Sql +      ' #Tmp_DB_Backup_List DBL ON SD.Name = DBL.DatabaseName'
				Set @Sql = @Sql + ' WHERE [Name] LIKE ''' + @DBName + ''' And DBL.DatabaseName IS Null'
				
				Exec (@Sql)
				--
				SELECT @myRowCount = @@rowcount, @myError = @@error
			End
		End
	End


	---------------------------------------
	-- Delete databases defined in #Tmp_DB_Backup_List that are not defined in sysdatabases
	---------------------------------------
	DELETE #Tmp_DB_Backup_List
	FROM #Tmp_DB_Backup_List DBL LEFT OUTER JOIN
		 master.dbo.sysdatabases SD ON SD.Name = DBL.DatabaseName
	WHERE SD.Name IS Null
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error
	
	If @myRowCount > 0
	Begin
		Set @message = 'Deleted ' + Convert(varchar(9), @myRowCount) + ' non-existent databases'
		If @InfoOnly = 1
			SELECT @message AS Warning_Message
	End
	
	
	---------------------------------------
	-- Update column Recovery_Model in #Tmp_DB_Backup_List
	-- This only works if on Sql Server 2005 or higher
	---------------------------------------
	Declare @VersionMajor int
	
	exec GetServerVersionInfo @VersionMajor output

	If @VersionMajor >= 9
	Begin
		-- Sql Server 2005 or higher
		UPDATE #Tmp_DB_Backup_List
		SET Recovery_Model = SD.recovery_model_desc
		FROM #Tmp_DB_Backup_List DBL INNER JOIN
			 master.sys.databases SD ON DBL.DatabaseName = SD.Name
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
	End

	
	---------------------------------------
	-- If @TransactionLogBackup = 0, then update Perform_Full_DB_Backup to 1 for all DBs
	-- Otherwise, update Perform_Full_DB_Backup to 1 for databases with a Simple recovery model
	---------------------------------------
	If @TransactionLogBackup = 0
	Begin
		UPDATE #Tmp_DB_Backup_List
		SET Perform_Full_DB_Backup = 1
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
	End
	Else
	Begin
		UPDATE #Tmp_DB_Backup_List
		SET Perform_Full_DB_Backup = 1
		WHERE Recovery_Model = 'SIMPLE'
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
	End		


	If @InfoOnly = 1
		SELECT *
		FROM #Tmp_DB_Backup_List
		ORDER BY DatabaseName

	---------------------------------------
	-- Count the number of databases in #Tmp_DB_Backup_List
	---------------------------------------
	Set @myRowCount = 0
	SELECT @myRowCount = COUNT(*)
	FROM #Tmp_DB_Backup_List
	
	If @myRowCount = 0
	Begin
		Set @Message = 'Warning: no databases were found matching the given specifications'
		Goto Done
	End

	If @BackupBatchSize > 1
	Begin -- <Batched>
		---------------------------------------
		-- Loop through the databases in #Tmp_DB_Backup_List
		-- First process DBs with Perform_Full_DB_Backup = 1
		-- Then process the remaining DBs
		-- We can backup 32 databases at a time (this is a limitation of the master..sqlbackup extended stored procedure)
		---------------------------------------
		Set @FullDBBackupMatchMode = 1
		Set @continue = 1
		While @continue <> 0
		Begin -- <a>
			-- Clear #Tmp_Current_Batch
			DELETE FROM #Tmp_Current_Batch
			
			-- Populate #Tmp_Current_Batch with the next @BackupBatchSize available DBs
			-- Do not delete these from #Tmp_DB_Backup_List yet; this will be done below
			INSERT INTO #Tmp_Current_Batch (DatabaseName)
			SELECT TOP 32 DatabaseName
			FROM #Tmp_DB_Backup_List
			WHERE Perform_Full_DB_Backup = @FullDBBackupMatchMode
			ORDER BY DatabaseName
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error

			If @myRowCount = 0
			Begin
				If @FullDBBackupMatchMode = 1
					Set @FullDBBackupMatchMode = 0
				Else
					Set @continue = 0
			End
			Else
			Begin -- <b>
				-- Populate @DBList with a comma separated list of the DBs in #Tmp_Current_Batch
				-- However, don't let the length of @DBList get over @DBListMaxLength characters 
				-- (Red-Gate suggested no more than 60000 characters, or 30000 if nvarchar)
				
				Set @DBCountInBatch = 0
				Set @AddDBsToBatch = 1
				While @AddDBsToBatch = 1 And @DBCountInBatch < @BackupBatchSize
				Begin -- <c1>
					Set @DBName = ''
					SELECT TOP 1 @DBName = DatabaseName
					FROM #Tmp_Current_Batch
					WHERE IncludeDB = 0
					ORDER BY DatabaseName
					--
					SELECT @myRowCount = @@rowcount, @myError = @@error
					
					If @myRowCount = 0
						Set @AddDBsToBatch = 0
					Else
					Begin -- <c2>
						If @DBCountInBatch = 0
						Begin
							Set @DBList = @DBName
							Set @DBCountInBatch = @DBCountInBatch + 1
						End
						Else
						Begin
							If Len(@DBList) + Len(@DBName) + 1 < @DBListMaxLength
							Begin
								Set @DBList = @DBList + ',' + @DBName
								Set @DBCountInBatch = @DBCountInBatch + 1
							End
							Else
							Begin
								-- Cannot add the next DB to @DBList since the list would be too long
								Set @AddDBsToBatch = 0
							End
						End
						
						If @AddDBsToBatch = 1
						Begin
							UPDATE #Tmp_Current_Batch
							SET IncludeDB = 1
							WHERE DatabaseName = @DBName
						End
					End -- <c2>
				End -- </c1>
				
				If @DBCountInBatch = 0 Or Len(@DBList) = 0
				Begin
					Set @message = 'Error populating @DBList using #Tmp_Current_Batch; no databases were found'
					Execute PostLogEntry 'Error', @message, 'BackupDMSDBs'
					Goto Done
				End

				-- Delete any DBs from #Tmp_Current_Batch that don't have IncludeDB=1
				DELETE #Tmp_Current_Batch
				WHERE IncludeDB = 0
				
				-- Delete DBs from #Tmp_DB_Backup_List that are in #Tmp_Current_Batch
				DELETE #Tmp_DB_Backup_List
				FROM #Tmp_DB_Backup_List BL INNER JOIN 
					 #Tmp_Current_Batch CB ON BL.DatabaseName = CB.DatabaseName
					
				---------------------------------------
				-- Construct the backup command for the databases in @DBList
				---------------------------------------
				
				If @FullDBBackupMatchMode = 1
				Begin
					Set @Sql = '-SQL "BACKUP DATABASES '
					Set @BackupType = 'FULL'
					Set @DBBackupFullCount = @DBBackupFullCount + @DBCountInBatch
				End
				Else
				Begin
					Set @Sql = '-SQL "BACKUP LOGS '
					Set @BackupType = 'LOG'
					Set @DBBackupTransCount = @DBBackupTransCount + @DBCountInBatch
				End

				-- Add the backup folder path (<DATABASE> and <AUTO> are wildcards recognized by Sql Backup)
				Set @Sql = @Sql + '[' + @DBList + ']' 
				
				If @UseLocalTransferFolder <> 0
					Set @BackupFileBasePath = @LocalTransferFolderRoot
				Else
					Set @BackupFileBasePath = @BackupFolderRoot

				Set @Sql = @Sql + ' TO DISK = ''' + dbo.udfCombinePaths(@BackupFileBasePath, '<DATABASE>\<AUTO>') + ''''
				

				Set @Sql = @Sql + ' WITH NAME=''<AUTO>'', DESCRIPTION=''<AUTO>'','

				-- Only include the MAXDATABLOCK parameter if @BackupFileBasePath points to a network share
				If Left(@BackupFileBasePath, 2) = '\\'
					Set @Sql = @Sql + ' MAXDATABLOCK=524288,'

				If @UseLocalTransferFolder <> 0
					Set @Sql = @Sql + ' COPYTO=''' + dbo.udfCombinePaths(@BackupFolderRoot, '<DATABASE>') + ''','
					
				Set @Sql = @Sql + ' ERASEFILES=' + Convert(varchar(16), @DaysToKeepOldBackups) + ','

				-- FILEOPTIONS is the sum of the desired options:
				--   1: Delete old backup files in the secondary backup folders (specified using COPYTO) 
				--        if they are older than the number of days or hours specified in ERASEFILES or ERASEFILES_ATSTART.
				--   2: Delete old backup files in the primary backup folder (specified using DISK) 
				--        if they are older than the number of days or hours specified in ERASEFILES or ERASEFILES_ATSTART, 
				--        unless they have the ARCHIVE flag set.
				--   3: 1 and 2 both enabled
				--   4: Overwrite existing files in the COPYTO folder.
				--   7: All options enabled

				If @UseLocalTransferFolder <> 0
					Set @Sql = @Sql + ' FILEOPTIONS=1,'
					
				Set @Sql = @Sql + ' COMPRESSION=' + Convert(varchar(4), @CompressionLevel) + ','

				If @FileCount > 1
					Set @Sql = @Sql + ' FILECOUNT=' + Convert(varchar(6), @FileCount) + ','
				Else
				Begin
					If @ThreadCount > 1
						Set @Sql = @Sql + ' THREADCOUNT=' + Convert(varchar(4), @ThreadCount) + ','
				End

				If @DiskRetryIntervalSec > 0
				Begin
					Set @Sql = @Sql + ' DISKRETRYINTERVAL=' + Convert(varchar(6), @DiskRetryIntervalSec) + ','
					Set @Sql = @Sql + ' DISKRETRYCOUNT=' + Convert(varchar(6), @DiskRetryCount) + ','
				End
								
				If @Verify <> 0
					Set @Sql = @Sql + ' VERIFY,'
					
				Set @Sql = @Sql + ' LOGTO=''' + @DBBackupStatusLogPathBase + ''', MAILTO_ONERROR = ''matthew.monroe@pnl.gov''"'

				If @InfoOnly = 0
				Begin -- <c3>
					---------------------------------------
					-- Perform the backup
					---------------------------------------
					exec master..sqlbackup @Sql, @ExitCode OUTPUT, @SqlErrorCode OUTPUT

					If (@ExitCode <> 0) OR (@SqlErrorCode <> 0)
					Begin
						---------------------------------------
						-- Error occurred; post a log entry
						---------------------------------------
						Set @message = 'SQL Backup of DB batch failed with exitcode: ' + Convert(varchar(19), @ExitCode) + ' and SQL error code: ' + Convert(varchar(19), @SqlErrorCode)
						Set @message = @message + '; DB List: ' + @DBList
						Execute PostLogEntry 'Error', @message, 'BackupDMSDBs'
					End
				End -- </c3>
				Else
				Begin -- <c4>
					---------------------------------------
					-- Preview the backup Sql 
					---------------------------------------
					Set @Sql = Replace(@Sql, '''', '''' + '''')
					Print 'exec master..sqlbackup ''' + @Sql + ''''
				End -- </c4>
				
				---------------------------------------
				-- Append @DBList to @DBsProcessed, limiting to @DBsProcessedMaxLenth characters, 
				--  afterwhich a period is added for each additional DB
				---------------------------------------
				
				If @DBCountInBatch >= 3
					Set @Periods = '...'
				Else
					Set @Periods = '..'
					
				If Len(@DBsProcessed) = 0
				Begin
					Set @DBsProcessed = @DBList
					If Len(@DBsProcessed) > @DBsProcessedMaxLenth
						Set @DBsProcessed = Left(@DBsProcessed, @DBsProcessedMaxLenth) + @Periods
				End
				Else
				Begin					
					If Len(@DBsProcessed) + Len(@DBList) <= @DBsProcessedMaxLenth
						Set @DBsProcessed = @DBsProcessed + ', ' + @DBList
					Else
					Begin
						If Len(@DBsProcessed) < @DBsProcessedMaxLenth
							Set @DBsProcessed = @DBsProcessed + ', ' + Left(@DBList, @DBsProcessedMaxLenth-3-Len(@DBsProcessed)) + @Periods
						Else
							Set @DBsProcessed = @DBsProcessed + ' ' + @Periods
					End
				End

			End -- </b>
		End -- </a>
	End -- </Batched>
	Else
	Begin -- <NonBatched>
		---------------------------------------
		-- Loop through the databases in #Tmp_DB_Backup_List
		-- First process DBs with Perform_Full_DB_Backup = 1
		-- Then process the remaining DBs
		---------------------------------------
		Set @FullDBBackupMatchMode = 1
		Set @continue = 1
		While @continue <> 0
		Begin -- <d>
			SELECT TOP 1 @DBName = DatabaseName
			FROM #Tmp_DB_Backup_List
			WHERE Perform_Full_DB_Backup = @FullDBBackupMatchMode
			ORDER BY DatabaseName
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error

			If @myRowCount <> 1
			Begin
				If @FullDBBackupMatchMode = 1
					Set @FullDBBackupMatchMode = 0
				Else
					Set @continue = 0
			End
			Else
			Begin -- <e>
				DELETE FROM #Tmp_DB_Backup_List
				WHERE @DBName = DatabaseName

				---------------------------------------
				-- Construct the backup and restore commands for database @DBName
				---------------------------------------
				
				If @FullDBBackupMatchMode = 1
				Begin
					Set @Sql = '-SQL "BACKUP DATABASE '
					Set @BackupType = 'FULL'
					Set @DBBackupFullCount = @DBBackupFullCount + 1
				End
				Else
				Begin
					Set @Sql = '-SQL "BACKUP LOG '
					Set @BackupType = 'LOG'
					Set @DBBackupTransCount = @DBBackupTransCount + 1
				End

				Set @Sql = @Sql + '[' + @DBName + '] TO '

				-- Generate a time stamp in the form: yyyymmdd_hhnnss
				Set @BackupTime = Convert(varchar(64), GetDate(), 120 )
				Set @BackupTime = Replace(Replace(Replace(@BackupTime, ' ', '_'), ':', ''), '-', '')
				
				Set @BackupFileBaseName =  @DBName + '_' + @BackupType + '_' + @BackupTime
				Set @BackupFileBasePath = @BackupFolderRoot + @DBName + '\' + @BackupFileBaseName

				Set @BackupFileList = 'DISK = ''' + @BackupFileBasePath + '.sqb'''
				
				Set @Sql = @Sql + @BackupFileList
				Set @Sql = @Sql + ' WITH MAXDATABLOCK=524288, NAME=''<AUTO>'', DESCRIPTION=''<AUTO>'','
				Set @Sql = @Sql + ' ERASEFILES=' + Convert(varchar(16), @DaysToKeepOldBackups) + ','
				Set @Sql = @Sql + ' COMPRESSION=3,'

				If @FileCount > 1
					Set @Sql = @Sql + ' FILECOUNT=' + Convert(varchar(6), @FileCount) + ','
				Else
				Begin
					If @ThreadCount > 1
						Set @Sql = @Sql + ' THREADCOUNT=' + Convert(varchar(4), @ThreadCount) + ','
				End
			
				Set @DBBackupStatusLogFileName = @DBBackupStatusLogPathBase + @BackupFileBaseName + '.log'
				Set @Sql = @Sql + ' LOGTO=''' + @DBBackupStatusLogFileName + ''', MAILTO_ONERROR = ''matthew.monroe@pnl.gov''"'

				Set @SqlRestore = '-SQL "RESTORE VERIFYONLY FROM ' + @BackupFileList + '"'
				
				
				If @InfoOnly = 0
				Begin -- <f1>
					---------------------------------------
					-- Perform the backup
					---------------------------------------
					exec master..sqlbackup @Sql, @ExitCode OUTPUT, @SqlErrorCode OUTPUT

					If (@ExitCode <> 0) OR (@SqlErrorCode <> 0)
					Begin
						---------------------------------------
						-- Error occurred; post a log entry
						---------------------------------------
						Set @message = 'SQL Backup of DB ' + @DBName + ' failed with exitcode: ' + Convert(varchar(19), @ExitCode) + ' and SQL error code: ' + Convert(varchar(19), @SqlErrorCode)
						Execute PostLogEntry 'Error', @message, 'BackupDMSDBs'
					End
					Else
					Begin
						If @Verify <> 0
						Begin
							-------------------------------------
							-- Verify the backup
							-------------------------------------
							exec master..sqlbackup @SqlRestore, @ExitCode OUTPUT, @SqlErrorCode OUTPUT

							If (@ExitCode <> 0) OR (@SqlErrorCode <> 0)
							Begin
								---------------------------------------
								-- Error occurred; post a log entry
								---------------------------------------
								Set @message = 'SQL Backup Verify of DB ' + @DBName + ' failed with exitcode: ' + Convert(varchar(19), @ExitCode) + ' and SQL error code: ' + Convert(varchar(19), @SqlErrorCode)
								Execute PostLogEntry 'Error', @message, 'BackupDMSDBs'
							End
						End
					End
					
					---------------------------------------
					-- Append the contents of @DBBackupStatusLogFileName to @DBBackupStatusLogSummary
					---------------------------------------
					Exec @myError = AppendTextFileToTargetFile	@DBBackupStatusLogFileName, 
																@DBBackupStatusLogSummary, 
																@DeleteSourceAfterAppend = 1, 
																@message = @message output
					If @myError <> 0
					Begin
						Set @message = 'Error calling AppendTextFileToTargetFile: ' + @message
						Execute PostLogEntry 'Error', @message, 'BackupDMSDBs'
						Goto Done
					End
				End -- </f1>
				Else
				Begin -- <f2>
					---------------------------------------
					-- Preview the backup Sql 
					---------------------------------------
					Set @Sql = Replace(@Sql, '''', '''' + '''')
					Print 'exec master..sqlbackup ''' + @Sql + ''''
					
					Set @SqlRestore = Replace(@SqlRestore, '''', '''' + '''')
					Print 'exec master..sqlbackup ''' + @SqlRestore + ''''
				End -- </f2>
				
				---------------------------------------
				-- Append @DBName to @DBsProcessed, limiting to @DBsProcessedMaxLenth characters, 
				--  afterwhich a period is added for each additional DB
				---------------------------------------
				If Len(@DBsProcessed) = 0
					Set @DBsProcessed = @DBName
				Else
				Begin
					If Len(@DBsProcessed) <= @DBsProcessedMaxLenth
						Set @DBsProcessed = @DBsProcessed + ', ' + @DBName
					Else
						Set @DBsProcessed = @DBsProcessed + '.'
				End

			End -- </e>
		End -- </d>
	End -- </NonBatched>

	If @DBBackupFullCount + @DBBackupTransCount = 0
		Set @Message = 'Warning: no databases were found matching the given specifications'
	Else
	Begin
		Set @Message = 'DB Backup Complete ('
		if @DBBackupFullCount > 0
			Set @Message = @Message + 'FullBU=' + Convert(varchar(9), @DBBackupFullCount) 
		if @DBBackupTransCount > 0
		Begin
			If Right(@Message,1) <> '('
				Set @Message = @Message + '; '
			Set @Message = @Message + 'LogBU=' + Convert(varchar(9), @DBBackupTransCount) 
		End

		Set @Message = @Message + '): ' + @DBsProcessed
	End
	
	---------------------------------------
	-- Post a Log entry if @DBBackupFullCount + @DBBackupTransCount > 0 and @InfoOnly = 0
	---------------------------------------
	If @InfoOnly = 0
	Begin
		If @DBBackupFullCount + @DBBackupTransCount > 0
			Execute PostLogEntry 'Normal', @message, 'BackupDMSDBs'
	End
	Else
		SELECT @Message As TheMessage

Done:
	DROP TABLE #Tmp_DB_Backup_List

	Return @myError



GO
GRANT VIEW DEFINITION ON [dbo].[BackupDMSDBs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[BackupDMSDBs] TO [PNL\D3M580] AS [dbo]
GO
