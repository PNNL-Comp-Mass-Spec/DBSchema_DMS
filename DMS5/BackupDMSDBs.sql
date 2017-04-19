/****** Object:  StoredProcedure [dbo].[BackupDMSDBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE BackupDMSDBs
/****************************************************
**
**	Desc:	Performs database backups of the specified databases
**			Supports native backups or use of Ola Hallengren's Maintenance Solution
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
**			06/28/2013 mem - Now performing a log backup of the Model DB after the full backup to prevent the model DB's log file from growing over time (it grows because the Model DB's recovery model is "Full", and a database backup is a logged operation)
**			09/15/2015 mem - Added parameter @UseRedgateBackup
**			03/17/2016 mem - Now calling xp_delete_file to delete old backup files when @UseRedgateBackup = 0
**			03/18/2016 mem - Update e-mail address for the MAILTO_ONERROR parameter
**			03/22/2016 mem - Now calling VerifyDirectoryExists to create the output directory if missing
**			11/16/2016 mem - Mention Powershell script DeleteOldBackups.ps1
**			04/18/2017 mem - Remove support for Redgate backup, including removing several parameters
**			               - Added parameter @BackupTool for optionally using Ola Hallengren's Maintenance Solution
**    
*****************************************************/
(
	@BackupFolderRoot varchar(128) = '',			-- If blank, then looks up the value in T_MiscPaths
	@DBNameMatchList varchar(2048) = 'DMS%',		-- Comma-separated list of databases on this server to include; can include wildcard symbols since used with a LIKE clause.  Leave blank to ignore this parameter
	@TransactionLogBackup tinyint = 0,				-- Set to 0 for a full backup, 1 for a transaction log backup
	@IncludeSystemDBs tinyint = 0,					-- Set to 1 to include master, model and MSDB databases; these always get full DB backups since transaction log backups are not allowed
	@DaysToKeepOldBackups smallint = 20,			-- Defines the number of days to retain full or transaction log backups; files older than @DaysToKeepOldBackups days prior to the present will be deleted; minimum value is 3.  Only used if @BackupTool = 1
	@Verify tinyint = 1,							-- Set to 1 to verify each backup
	@InfoOnly tinyint = 1,							-- Set to 1 to display the backup SQL that would be run
	@CompressionLevel tinyint = 1,					-- Set to 1 to compress backups, 0 to disable compression
	@BackupTool tinyint = 0,						-- 0 to use native backup, 1 to use Ola Hallengren's Maintenance Solution
	@message varchar(2048) = '' OUTPUT
)
As	
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @ExitCode int = 0
	Declare @SqlErrorCode int = 0

	---------------------------------------
	-- Validate the inputs
	---------------------------------------
	--
	Set @BackupFolderRoot = IsNull(@BackupFolderRoot, '')
	Set @DBNameMatchList = LTrim(RTrim(IsNull(@DBNameMatchList, '')))

	Set @TransactionLogBackup = IsNull(@TransactionLogBackup, 0)
	Set @IncludeSystemDBs = IsNull(@IncludeSystemDBs, 0)
	
	Set @Verify = IsNull(@Verify, 0)
	Set @InfoOnly = IsNull(@InfoOnly, 0)

	Set @DaysToKeepOldBackups = IsNull(@DaysToKeepOldBackups, 20)
	If @DaysToKeepOldBackups < 3
		Set @DaysToKeepOldBackups = 3
	
	Set @CompressionLevel = IsNull(@CompressionLevel, 1)

	If @CompressionLevel < 1
		Set @CompressionLevel = 0
	Else
		Set @CompressionLevel = 1

	Set @BackupTool = IsNull(@BackupTool, 0)

	Set @message = ''

	---------------------------------------
	-- Define the local variables
	---------------------------------------
	--
	Declare @DBName varchar(255)
	Declare @DBList varchar(max)
	Declare @DBsProcessed varchar(max)
	Set @DBsProcessed = ''
	
	Declare @DBListMaxLength int = 25000

	Declare @DBsProcessedMaxLenth int = 1250

	Declare @Sql varchar(max)
	Declare @SqlRestore varchar(max)

	Declare @UnicodeSql nvarchar(4000)
	
	Declare @BackupType varchar(32)
	Declare @BackupTime varchar(64)
	Declare @BackupFileBaseName varchar(512)
	Declare @BackupFileBasePath varchar(1024)
	Declare @FileExtension varchar(6)
	
	Declare @BackupFileList varchar(2048)
	Declare @Periods varchar(6)
	
	Declare @continue tinyint
	Declare @AddDBsToBatch tinyint
	
	Declare @FullDBBackupMatchMode tinyint
	Declare @CharLoc int
	Declare @DBBackupFullCount int = 0
	Declare @DBBackupTransCount int = 0

	Declare @FailedBackupCount int = 0
	Declare @FailedVerifyCount int = 0
	
	---------------------------------------
	-- Validate @BackupFolderRoot
	---------------------------------------
	--
	Set @BackupFolderRoot = LTrim(RTrim(@BackupFolderRoot))
	If Len(@BackupFolderRoot) = 0
	Begin
		SELECT @BackupFolderRoot = [Server]
		FROM T_MiscPaths
		WHERE ([Function] = 'Database Backup Path')

		If @BackupTool > 0 and Len(@BackupFolderRoot) > 0
		Begin
			-- Backup path will be something like \\proto-7\MTS_Backup\Elmer_Backup\
			-- Change it to \\proto-7\MTS_Backup\
			
			Declare @CharIndex int
			Set @CharIndex = CHARINDEX(@@ServerName, @BackupFolderRoot)
			If @CharIndex > 0 
				Set @BackupFolderRoot = Substring(@BackupFolderRoot, 1, @CharIndex-1)
		End
	End
	
	Set @BackupFolderRoot = LTrim(RTrim(@BackupFolderRoot))
	If Len(@BackupFolderRoot) = 0
	Begin
		Set @myError = 50000
		Set @message = 'Backup path not defined via @BackupFolderRoot parameter, and could not be found in table T_MiscPaths'
		exec PostLogEntry 'Error', @message, 'BackupDMSDBs'
		Goto Done
	End
	
	-- Make sure that @BackupFolderRoot ends in a backslash
	If Right(@BackupFolderRoot, 1) <> '\'
		Set @BackupFolderRoot = @BackupFolderRoot + '\'

	---------------------------------------
	-- Create a temporary table to hold the databases to process
	---------------------------------------
	--
	If Exists (SELECT * from sys.tables where Name = '#Tmp_DB_Backup_List')
		DROP TABLE #Tmp_DB_Backup_List

	CREATE TABLE #Tmp_DB_Backup_List (
		DatabaseName varchar(255) NOT NULL,
		Recovery_Model varchar(64) NOT NULL DEFAULT 'Unknown',
		Perform_Full_DB_Backup tinyint NOT NULL DEFAULT 0
	)

	-- Note that this is not a unique index because the model database will be listed twice if it is using Full Recovery mode
	CREATE CLUSTERED INDEX #IX_Tmp_DB_Backup_List ON #Tmp_DB_Backup_List (DatabaseName)


	If Exists (SELECT * from sys.tables where Name = '#Tmp_Current_Batch')
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
	--
	If @IncludeSystemDBs > 0
	Begin
		INSERT INTO #Tmp_DB_Backup_List (DatabaseName, Perform_Full_DB_Backup) VALUES ('Master', 1)
		INSERT INTO #Tmp_DB_Backup_List (DatabaseName, Perform_Full_DB_Backup) VALUES ('Model', 1)
		INSERT INTO #Tmp_DB_Backup_List (DatabaseName, Perform_Full_DB_Backup) VALUES ('MSDB', 1)

		---------------------------------------
		-- Lookup the recovery mode of the Model DB
		-- If it is using Full Recovery, then we need to perform a log backup after the full backup, 
		--   otherwise the model DB's log file may grow indefinitely
		---------------------------------------
		
		Declare @ModelDbRecoveryModel varchar(12)

		SELECT @ModelDbRecoveryModel = recovery_model_desc
		FROM sys.databases
		where name = 'Model'

		If @ModelDbRecoveryModel = 'Full'
			INSERT INTO #Tmp_DB_Backup_List (DatabaseName, Perform_Full_DB_Backup) VALUES ('Model', 0)
	End


	---------------------------------------
	-- Look for databases on this server that match @DBNameMatchList
	---------------------------------------
	--
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
	--
	DELETE #Tmp_DB_Backup_List
	FROM #Tmp_DB_Backup_List DBL LEFT OUTER JOIN
		 master.dbo.sysdatabases SD ON SD.Name = DBL.DatabaseName
	WHERE SD.Name IS Null
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error
	
	If @myRowCount > 0
	Begin
		Set @message = 'Deleted ' + Convert(varchar(9), @myRowCount) + ' non-existent databases'
		If @InfoOnly > 0
			SELECT @message AS Warning_Message
	End
	
	
	---------------------------------------
	-- Update column Recovery_Model in #Tmp_DB_Backup_List
	-- This only works if on Sql Server 2005 or higher
	---------------------------------------
	--
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
	-- If @TransactionLogBackup = 0, update Perform_Full_DB_Backup to 1 for all DBs
	-- Otherwise, update Perform_Full_DB_Backup to 1 for databases with a Simple recovery model
	---------------------------------------
	--
	If @TransactionLogBackup = 0
	Begin
		UPDATE #Tmp_DB_Backup_List
		SET Perform_Full_DB_Backup = 1
		WHERE DatabaseName <> 'Model'
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


	If @InfoOnly > 0
		SELECT *
		FROM #Tmp_DB_Backup_List
		ORDER BY DatabaseName

	---------------------------------------
	-- Count the number of databases in #Tmp_DB_Backup_List
	---------------------------------------
	--
	Set @myRowCount = 0
	SELECT @myRowCount = COUNT(*)
	FROM #Tmp_DB_Backup_List
	
	If @myRowCount = 0
	Begin
		Set @Message = 'Warning: no databases were found matching the given specifications'
		exec PostLogEntry 'Warning', @message, 'BackupDMSDBs'
		Goto Done
	End
	
	---------------------------------------
	-- Determine the version of Sql Server that we are running on
	--   10.00 is Sql Server 2008
	--   10.50 is Sql Server 2008 R2
	--   11.00 is Sql Server 2012
	---------------------------------------
	
	Declare @Version numeric(18,10)
	Declare @Compress varchar(1)
	
	SET @Version = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - 1) + '.' + REPLACE(RIGHT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))),'.','') AS numeric(18,10))

	-- Initially assume compression is supported
	Set @Compress = 'Y'

	If @Version < 11
	Begin
		If (NOT ((@Version >= 10 AND @Version < 10.5 AND SERVERPROPERTY('EngineEdition') = 3) OR (@Version >= 10.5 AND (SERVERPROPERTY('EngineEdition') = 3 OR SERVERPROPERTY('EditionID') IN (-1534726760, 284895786))))) 
			-- Compression is Not Supported
			Set @Compress = 'N'
	End

	---------------------------------------
	-- Loop through the databases in #Tmp_DB_Backup_List
	-- First process DBs with Perform_Full_DB_Backup = 1
	-- Then process the remaining DBs
	---------------------------------------
	--
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
			WHERE @DBName = DatabaseName AND
				    Perform_Full_DB_Backup = @FullDBBackupMatchMode

			If @FullDBBackupMatchMode = 1
				Set @DBBackupFullCount = @DBBackupFullCount + 1
			Else
				Set @DBBackupTransCount = @DBBackupTransCount + 1

			---------------------------------------
			-- Construct the backup and restore commands for database @DBName
			---------------------------------------
			--
			If @BackupTool > 0
			Begin
				-- Native backup (using Ola Hallengren's Maintenance Solution; see http://ola.hallengren.com/ )
				
				Set @Sql = 'exec master.dbo.DatabaseBackup @Databases=''' + @DBName + ''', @Directory=''' + @BackupFolderRoot + ''''
				If @FullDBBackupMatchMode = 1
					Set @Sql = @Sql + ', @BackupType=''FULL'''
				Else
					Set @Sql = @Sql + ', @BackupType=''LOG'''
					
				If @DaysToKeepOldBackups > 0
				Begin
					Set @Sql = @Sql + ', @CleanupTime=' + Convert(varchar(12), @DaysToKeepOldBackups*24)
				End
				
				Set @Sql = @Sql + ', @Verify=''Y'', @Compress=''' + @Compress + ''', @ChangeBackupType=''Y'', @CheckSum=''Y'''
				
			End
			Else
			Begin
				-- Native backup

				If @FullDBBackupMatchMode = 1
				Begin
					Set @Sql = 'BACKUP DATABASE '
					Set @FileExtension = '.bak'
						
					Set @BackupType = 'FULL'
				End
				Else
				Begin
					Set @Sql = 'BACKUP LOG '
					Set @FileExtension = '.trn'
					
					Set @BackupType = 'LOG'
				End

				Set @Sql = @Sql + '[' + @DBName + '] TO '

				-- Generate a time stamp in the form: yyyy_mm_dd_hhnnss
				Set @BackupTime = Convert(varchar(64), GetDate(), 120 )
				Set @BackupTime = Replace(Replace(Replace(@BackupTime, ' ', '_'), ':', ''), '-', '_')
				Set @BackupFileBaseName = @DBName + '_backup_' + @BackupTime
				
				-- Append the database name to the base path	
				Set @BackupFileBasePath = dbo.udfCombinePaths(@BackupFolderRoot, @DBName)

				-- Verify that the output directory exists; create if missing
				--				
				EXEC @ExitCode = VerifyDirectoryExists @BackupFileBasePath, @createIfMissing=1, @message=@message OUTPUT, @showDebugMessages=@InfoOnly

				If @ExitCode <> 0
				Begin
					Set @myError = @ExitCode
					Set @message = 'Error verifying the backup folder with VerifyDirectoryExists, path=' + @BackupFileBasePath + ', errorCode=' + Cast(@ExitCode as varchar(12))
					
					If @InfoOnly = 0
						exec PostLogEntry 'Error', @message, 'BackupDMSDBs'
					else
						Print @message
						
					Goto Done
				End
						
				-- Append the file name to the base path
				Set @BackupFileBasePath = dbo.udfCombinePaths(@BackupFileBasePath, @BackupFileBaseName)

				-- Example command:
				-- TO DISK = '\\server\share\directory\DatabaseName\DatabaseName_backup_2016_03_22_103334.bak' 
				
				Set @BackupFileList = 'DISK = ''' + @BackupFileBasePath + @FileExtension + ''''
				
				Set @Sql = @Sql + @BackupFileList
				
				-- Note: Use of checksum slows the backup down a little, but it is best practice to enable this option
				Set @Sql = @Sql + ' WITH NOFORMAT, NOINIT,  NAME = ''' + @DBName + '-' + @BackupType + ''', SKIP, NOREWIND, NOUNLOAD, STATS = 10, CHECKSUM'
				
				If @CompressionLevel > 0
					Set @Sql = @Sql + ', COMPRESSION'

				Set @SqlRestore = 'RESTORE VERIFYONLY FROM ' + @BackupFileList
				
			End
			
			If @InfoOnly = 0
			Begin -- <f1>
			
				---------------------------------------
				-- Perform the backup
				---------------------------------------
				
				Set @UnicodeSql = @Sql
				exec @ExitCode = sp_executesql @UnicodeSql

				If (@ExitCode <> 0) OR (@SqlErrorCode <> 0)
				Begin
					---------------------------------------
					-- Error occurred
					-- Post a log entry but continue backing up other databases
					---------------------------------------
					
					Set @message = 'SQL Backup of DB ' + @DBName + ' failed with exitcode: ' + Convert(varchar(19), @ExitCode) + ' and SQL error code: ' + Convert(varchar(19), @SqlErrorCode)
					exec PostLogEntry 'Error', @message, 'BackupDMSDBs'
					
					Set @FailedBackupCount = @FailedBackupCount + 1
				End
				Else
				Begin
					If @Verify <> 0
					Begin
						-------------------------------------
						-- Verify the backup
						-------------------------------------
						
						Set @UnicodeSql = @SqlRestore
						exec @ExitCode = sp_executesql @UnicodeSql
						
						If (@ExitCode <> 0) OR (@SqlErrorCode <> 0)
						Begin
							---------------------------------------
							-- Error occurred
							-- Post a log entry but continue backing up other databases
							---------------------------------------
							
							Set @message = 'SQL Backup Verify of DB ' + @DBName + ' failed with exitcode: ' + Convert(varchar(19), @ExitCode) + ' and SQL error code: ' + Convert(varchar(19), @SqlErrorCode)
							exec PostLogEntry 'Error', @message, 'BackupDMSDBs'
							
							Set @FailedVerifyCount = @FailedVerifyCount + 1
						End
					End
				End
				
			End -- </f1>
			Else
			Begin -- <f2>
				---------------------------------------
				-- Preview the backup Sql 
				---------------------------------------
				--					
				Print @Sql
				
				If @Verify <> 0
					Print @SqlRestore

				Print ''
				
			End -- </f2>
			
			---------------------------------------
			-- Append @DBName to @DBsProcessed, limiting to @DBsProcessedMaxLenth characters, 
			--  afterwhich a period is added for each additional DB
			---------------------------------------
			--
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
				
	If @FailedBackupCount = 0
	Begin
		---------------------------------------
		-- Could use xp_delete_file to delete old full and/or transaction log files
		-- However, online posts point out that this is an undocumented system procedure 
		-- and that we should instead use Powershell
		--
		-- See https://github.com/PNNL-Comp-Mass-Spec/DBSchema_DMS/blob/master/Powershell/DeleteOldBackups.ps1
		-- That script is run via a SQL Server agent job
		--
		---------------------------------------
		
		Print 'Run Powershell script DeleteOldBackups.ps1 via a SQL Server Agent job to delete old backups'
	End

	If @DBBackupFullCount + @DBBackupTransCount = 0
		Set @Message = 'Warning: no databases were found matching the given specifications'
	Else
	Begin
		Set @Message = 'DB Backup Complete ('
		if @DBBackupFullCount > 0
			Set @Message = @Message + 'FullBU=' + Cast(@DBBackupFullCount as varchar(9))
			
		if @DBBackupTransCount > 0
		Begin
			If Right(@Message,1) <> '('
				Set @Message = @Message + '; '
			Set @Message = @Message + 'LogBU=' + Cast(@DBBackupTransCount as varchar(9))
		End

		Set @Message = @Message + '): ' + @DBsProcessed
		
		If @FailedBackupCount > 0
		Begin
			Set @Message = @Message + '; FailureCount=' + Cast(@FailedBackupCount as varchar(9))
		End
	End
	
	---------------------------------------
	-- Post a Log entry if @DBBackupFullCount + @DBBackupTransCount > 0 and @InfoOnly = 0
	---------------------------------------
	--
	If @InfoOnly = 0
	Begin
		If @DBBackupFullCount + @DBBackupTransCount > 0
		Begin
			If @FailedBackupCount > 0
				exec PostLogEntry 'Error',  @message, 'BackupDMSDBs'
			Else
				exec PostLogEntry 'Normal', @message, 'BackupDMSDBs'
		End
	End
	Else
	Begin
		SELECT @Message As TheMessage
	End

Done:
	DROP TABLE #Tmp_DB_Backup_List

	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[BackupDMSDBs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[BackupDMSDBs] TO [Limited_Table_Write] AS [dbo]
GO
