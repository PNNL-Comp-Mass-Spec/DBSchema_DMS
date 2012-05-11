/****** Object:  StoredProcedure [dbo].[RefreshCachedMTSJobMappingMTDBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE RefreshCachedMTSJobMappingMTDBs
/****************************************************
**
**	Desc:	Updates the data in T_MTS_MT_DB_Jobs_Cached using MTS
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	04/21/2010 mem - Initial Version
**			10/21/2011 mem - Now checking for duplicate rows in T_MTS_MT_DB_Jobs_Cached
**
*****************************************************/
(
	@JobMinimum int = 0,		-- Set to a positive value to limit the jobs examined; when non-zero, then jobs outside this range are ignored
	@JobMaximum int = 0,
	@message varchar(255) = '' output
)
AS

	Set NoCount On

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	set @message = ''

	Declare @MaxInt int
	Set @MaxInt = 2147483647

	Declare @MergeUpdateCount int
	Declare @MergeInsertCount int
	Declare @MergeDeleteCount int
	
	Set @MergeUpdateCount = 0
	Set @MergeInsertCount = 0
	Set @MergeDeleteCount = 0

	-- Make sure we don't have duplicate rows in T_MTS_MT_DB_Jobs_Cached
	-- Duplicates were found in October 2011 after deleting several databases from MTS
	--
	DELETE T_MTS_MT_DB_Jobs_Cached
	FROM T_MTS_MT_DB_Jobs_Cached target
	     INNER JOIN ( SELECT Server_Name,
	                         MT_DB_Name,
	                         Job,
	                         ResultType,
	                         MIN(CachedInfo_ID) AS MinID
	                  FROM T_MTS_MT_DB_Jobs_Cached
	                  GROUP BY Server_Name, MT_DB_Name, Job, ResultType
	                  HAVING COUNT(*) > 1 
	                ) DupQ
	       ON target.Server_Name = DupQ.Server_Name AND
	          target.MT_DB_Name = DupQ.MT_DB_Name AND
	          target.Job = DupQ.Job AND
	          target.ResultType = DupQ.ResultType AND
	          target.CachedInfo_ID <> DupQ.MinID
	--
	Set @myRowCount = @@RowCount
	
	If @myRowCount > 0
	Begin
		Set @message = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' duplicate '
		If @myRowCount = 1
			Set @message = @message + 'entry'
		Else
			Set @message = @message + 'entries'			
		Set @message = @message + ' from T_MTS_MT_DB_Jobs_Cached; this is unexpected'
		
		execute PostLogEntry 'Error', @message, 'RefreshCachedMTSJobMappingMTDBs'
		
		Set @message = ''
	End

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
		Set @JobMinimum = IsNull(@JobMinimum, 0)
		Set @JobMaximum = IsNull(@JobMaximum, 0)
		
		If @JobMinimum = 0 AND @JobMaximum = 0
		Begin
			Set @FullRefreshPerformed = 1
			Set @JobMinimum = -@MaxInt
			Set @JobMaximum = @MaxInt
		End
		Else
		Begin
			Set @FullRefreshPerformed = 0
			If @JobMinimum > @JobMaximum
				Set @JobMaximum = @MaxInt
		End
	
		Set @CurrentLocation = 'Update T_MTS_Cached_Data_Status'
		-- 
		Exec UpdateMTSCachedDataStatus 'T_MTS_MT_DB_Jobs_Cached', @IncrementRefreshCount = 0, @FullRefreshPerformed = @FullRefreshPerformed, @LastRefreshMinimumID = @JobMinimum

		
		-- Use a MERGE Statement (introduced in Sql Server 2008) to synchronize T_MTS_MT_DB_Jobs_Cached with S_MTS_Analysis_Job_to_MT_DB_Map

		MERGE T_MTS_MT_DB_Jobs_Cached AS target
		USING 
			(SELECT  Server_Name, [DB_Name] AS MT_DB_Name, Job,
			         IsNull(ResultType, ''), Last_Affected, Process_State
			 FROM   S_MTS_Analysis_Job_to_MT_DB_Map AS MTSJobInfo
			 WHERE Job >= @JobMinimum AND
				   Job <= @JobMaximum
			) AS Source (	Server_Name, MT_DB_Name, Job,
			                ResultType, Last_Affected, Process_State)
		ON (target.Server_Name = source.Server_Name AND
			target.MT_DB_Name = source.MT_DB_Name AND
			target.Job = source.Job AND
			target.ResultType = source.ResultType)
		WHEN Matched AND 
					(	IsNull(target.Last_Affected ,'') <> IsNull(source.Last_Affected,'') OR
						IsNull(target.Process_State ,'') <> IsNull(source.Process_State,'')
					)
			THEN UPDATE 
				Set	Last_Affected = source.Last_Affected, 
					Process_State = source.Process_State
		WHEN Not Matched THEN
			INSERT ( Server_Name, MT_DB_Name, Job,
			         ResultType, Last_Affected, Process_State
					)
			VALUES (source.Server_Name, source.MT_DB_Name, source.Job,
					source.ResultType, source.Last_Affected, source.Process_State)
		WHEN NOT MATCHED BY SOURCE And @FullRefreshPerformed <> 0 THEN
			DELETE 
		OUTPUT $action INTO #Tmp_UpdateSummary
		;
	
		if @myError <> 0
		begin
			set @message = 'Error merging S_MTS_Analysis_Job_to_MT_DB_Map with T_MTS_MT_DB_Jobs_Cached (ErrorID = ' + Convert(varchar(12), @myError) + ')'
			execute PostLogEntry 'Error', @message, 'RefreshCachedMTSJobMappingMTDBs'
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
		Exec UpdateMTSCachedDataStatus 'T_MTS_MT_DB_Jobs_Cached', 
											@IncrementRefreshCount = 1, 
											@InsertCountNew = @MergeInsertCount, 
											@UpdateCountNew = @MergeUpdateCount, 
											@DeleteCountNew = @MergeDeleteCount,
											@FullRefreshPerformed = @FullRefreshPerformed, 
											@LastRefreshMinimumID = @JobMinimum
											
	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'RefreshCachedMTSJobMappingMTDBs')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done		
	End Catch
			
Done:
	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RefreshCachedMTSJobMappingMTDBs] TO [Limited_Table_Write] AS [dbo]
GO
