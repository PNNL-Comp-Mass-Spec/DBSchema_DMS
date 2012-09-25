/****** Object:  StoredProcedure [dbo].[RefreshCachedMTDBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE RefreshCachedMTDBs
/****************************************************
**
**	Desc:	Updates the data in T_MTS_MT_DBs_Cached using MTS
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	02/05/2010 mem - Initial Version
**
*****************************************************/
(
	@message varchar(255) = '' output
)
AS

	Set NoCount On

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	set @message = ''

	Declare @MergeUpdateCount int
	Declare @MergeInsertCount int
	Declare @MergeDeleteCount int
	
	Set @MergeUpdateCount = 0
	Set @MergeInsertCount = 0
	Set @MergeDeleteCount = 0

	---------------------------------------------------
	-- Create the temporary table that will be used to
	-- track the number of inserts, updates, and deletes 
	-- performed by the MERGE statement
	---------------------------------------------------
	
	CREATE TABLE #Tmp_UpdateSummary (
		UpdateAction varchar(32)
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_UpdateSummary ON #Tmp_UpdateSummary (UpdateAction)
	
		
	Declare @FullRefreshPerformed tinyint
	
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	Begin Try
		Set @CurrentLocation = 'Validate the inputs'

		-- Validate the inputs
		Set @FullRefreshPerformed = 1

		Set @CurrentLocation = 'Update T_MTS_Cached_Data_Status'
		-- 
		Exec UpdateMTSCachedDataStatus 'T_MTS_MT_DBs_Cached', @IncrementRefreshCount = 0, @FullRefreshPerformed = @FullRefreshPerformed, @LastRefreshMinimumID = 0



		
		-- Use a MERGE Statement (introduced in Sql Server 2008) to synchronize T_MTS_MT_DBs_Cached with S_MTS_MT_DBs

		MERGE T_MTS_MT_DBs_Cached AS target
		USING 
			(SELECT Server_Name, MT_DB_ID, MT_DB_Name,
					State_ID, State, [Description],
					Organism, Campaign,
					Last_Affected
			 FROM   S_MTS_MT_DBs AS MTSDBInfo
			) AS Source (	Server_Name, MT_DB_ID, MT_DB_Name,
							State_ID, State, [Description],
							Organism, Campaign,
							Last_Affected)
		ON (target.MT_DB_ID = source.MT_DB_ID)
		WHEN Matched AND 
					(	target.Server_Name <> source.Server_Name OR
						target.MT_DB_Name <> source.MT_DB_Name OR
						target.State_ID <> source.State_ID OR 
						target.State <> source.State OR 
						IsNull(target.[Description],'') <> IsNull(source.[Description],'') OR
						IsNull(target.Organism,'') <> IsNull(source.Organism,'') OR
						IsNull(target.Campaign,'') <> IsNull(source.Campaign,'') OR
						IsNull(target.Last_Affected ,'')<> IsNull(source.Last_Affected,'')
					)
			THEN UPDATE 
				Set	Server_Name = source.Server_Name, 
					MT_DB_Name = source.MT_DB_Name,
					State_ID = source.State_ID, 
					State = source.State, 
					[Description] = source.[Description],
					Organism = source.Organism, 
					Campaign = source.Campaign,
					Last_Affected = source.Last_Affected
		WHEN Not Matched THEN
			INSERT (Server_Name, MT_DB_ID, MT_DB_Name,
					State_ID, State, [Description],
					Organism, Campaign,
					Last_Affected
					)
			VALUES (source.Server_Name, source.MT_DB_ID, source.MT_DB_Name,
					source.State_ID, source.State, source.[Description],
					source.Organism, source.Campaign,
					source.Last_Affected)
		WHEN NOT MATCHED BY SOURCE THEN
			DELETE 
		OUTPUT $action INTO #Tmp_UpdateSummary
		;
	
		if @myError <> 0
		begin
			set @message = 'Error merging S_MTS_MT_DBs with T_MTS_MT_DBs_Cached (ErrorID = ' + Convert(varchar(12), @myError) + ')'
			execute PostLogEntry 'Error', @message, 'SyncJobInfo'
			goto Done
		end


		set @MergeUpdateCount = 0
		set @MergeInsertCount = 0
		set @MergeDeleteCount = 0

		SELECT @MergeInsertCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'INSERT'

		SELECT @MergeUpdateCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'UPDATE'

		SELECT @MergeDeleteCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'DELETE'


		Set @CurrentLocation = 'Update stats in T_MTS_Cached_Data_Status'
		--
		-- 
		Exec UpdateMTSCachedDataStatus 'T_MTS_MT_DBs_Cached', 
											@IncrementRefreshCount = 1, 
											@InsertCountNew = @MergeInsertCount, 
											@UpdateCountNew = @MergeUpdateCount, 
											@DeleteCountNew = @MergeDeleteCount,
											@FullRefreshPerformed = @FullRefreshPerformed, 
											@LastRefreshMinimumID = 0

	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'RefreshCachedMTSAnalysisJobInfo')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done		
	End Catch
			
Done:
	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RefreshCachedMTDBs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RefreshCachedMTDBs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RefreshCachedMTDBs] TO [PNL\D3M580] AS [dbo]
GO
