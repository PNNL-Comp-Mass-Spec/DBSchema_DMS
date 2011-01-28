/****** Object:  StoredProcedure [dbo].[RefreshCachedMTSInfoIfRequired] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.RefreshCachedMTSInfoIfRequired
/****************************************************
**
**	Desc: 
**		Calls the various RefreshCachedMTS procedures if the
**		Last_Refreshed date in T_MTS_Cached_Data_Status is over
**		@UpdateInterval hours before the present
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	02/02/2010 mem - Initial Version
**			04/21/2010 mem - Now calling RefreshCachedMTSJobMappingPeptideDB' and RefreshCachedMTSJobMappingMTDBs
**    
*****************************************************/
(
	@UpdateInterval real = 1,						-- Minimum interval in hours to limit update frequency; Set to 0 to force update now
	@DynamicMinimumCountThreshold int = 5000,		-- When updating every @UpdateInterval hours, uses the maximum cached ID value in the given T_MTS_%_Cached table to determine the minimum ID number to update; for example, for T_MTS_Analysis_Job_Info_Cached, MinimumJob = MaxJobInTable - @DynamicMinimumCountThreshold; set to 0 to update all items, regardless of ID
	@UpdateIntervalAllItems real = 24,				-- Interval (in hours) to update all items, regardless of ID
	@InfoOnly tinyint = 0,
 	@message varchar(255) = '' output
)
As
	Set NoCount On

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	set @message = ''

	Declare @CurrentTime datetime
	Set @CurrentTime = GetDate()

	Declare @LastRefreshed datetime
	Declare @LastFullRefresh datetime

	Declare @CacheTable varchar(256)
	Declare @IDColumnName varchar(64)
	Declare @SP varchar(128)

	Declare @S nvarchar(2048)
	Declare @Params nvarchar(256)

	Declare @IDMinimum int
	Declare @MaxID int
	Declare @HoursSinceLastRefresh decimal(9,3)
	Declare @HoursSinceLastFullRefresh decimal(9,3)
	
	Declare @Iteration int
	Declare @LimitToMaxKnownDMSJobs tinyint
	Declare @MaxKnownDMSJob int
	
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	Begin Try
		Set @CurrentLocation = 'Validate the inputs'
		--
		Set @UpdateInterval = IsNull(@UpdateInterval, 1)
		Set @DynamicMinimumCountThreshold = IsNull(@DynamicMinimumCountThreshold, 10000)
		Set @UpdateIntervalAllItems = IsNull(@UpdateIntervalAllItems, 24)
		Set @InfoOnly = IsNull(@InfoOnly, 0)
		
		Set @message = ''
		
		-- Lookup the largest DMS Job ID (used to filter out bogus job numbers in MTS when performing a partial refresh
		Set @MaxKnownDMSJob = 0
		
		SELECT @MaxKnownDMSJob = MAX(ID)
		FROM T_Analysis_Job_ID
		
							 
		Set @Iteration = 1
		While @Iteration <= 5
		Begin -- <a>
			Set @CacheTable = ''
			Set @LimitToMaxKnownDMSJobs = 0
			Set @SP = ''
			
			If @Iteration = 1
			Begin
				Set @CacheTable = 'T_MTS_Peak_Matching_Tasks_Cached'
				Set @IDColumnName = 'MTS_Job_ID'
				Set @SP = 'RefreshCachedMTSPeakMatchingTasks'
			End
			
			If @Iteration = 2
			Begin
				Set @CacheTable = 'T_MTS_MT_DBs_Cached'
				Set @IDColumnName = ''
				Set @SP = 'RefreshCachedMTDBs'
			End
			
			If @Iteration = 3
			Begin
				Set @CacheTable = 'T_MTS_PT_DBs_Cached'
				Set @IDColumnName = ''
				Set @SP = 'RefreshCachedPTDBs'
			End
			
			If @Iteration = 4
			Begin
				Set @CacheTable = 'T_MTS_PT_DB_Jobs_Cached'
				Set @IDColumnName = 'Job'
				Set @SP = 'RefreshCachedMTSJobMappingPeptideDBs'
				Set @LimitToMaxKnownDMSJobs = 1
			End
			
			If @Iteration = 5
			Begin
				Set @CacheTable = 'T_MTS_MT_DB_Jobs_Cached'
				Set @IDColumnName = 'Job'
				Set @SP = 'RefreshCachedMTSJobMappingMTDBs'
				Set @LimitToMaxKnownDMSJobs = 1
			End
			
			If Len(@CacheTable) > 0
			Begin -- <b>
				Set @CurrentLocation = 'Check refresh time for ' + @CacheTable
				--
				Set @LastRefreshed = '1/1/2000'
				Set @LastFullRefresh = '1/1/2000'
				--
				SELECT  @LastRefreshed = Last_Refreshed,
						@LastFullRefresh = Last_Full_Refresh
				FROM T_MTS_Cached_Data_Status
				WHERE Table_Name = @CacheTable
				--
				SELECT @myRowCount = @@RowCount, @myError = @@Error

				if @infoOnly <> 0
					Print 'Processing ' + @CacheTable
					
				Set @HoursSinceLastRefresh = DateDiff(minute, IsNull(@LastRefreshed, '1/1/2000'), @CurrentTime) / 60.0
				If @infoOnly <> 0
					Print 'Hours since last refresh: ' + Convert(varchar(12), @HoursSinceLastRefresh) + Case When @HoursSinceLastRefresh >= @UpdateInterval Then ' -> Partial refresh required' Else '' End

				Set @HoursSinceLastFullRefresh = DateDiff(minute, IsNull(@LastFullRefresh, '1/1/2000'), @CurrentTime) / 60.0
				If @infoOnly <> 0
					Print 'Hours since last full refresh: ' + Convert(varchar(12), @HoursSinceLastFullRefresh) + Case When @HoursSinceLastFullRefresh >= @UpdateIntervalAllItems Then ' -> Full refresh required' Else '' End
					
				If @HoursSinceLastRefresh >= @UpdateInterval OR @HoursSinceLastFullRefresh >= @UpdateIntervalAllItems
				Begin -- <c>
				
					Set @IDMinimum = 0
					If @IDColumnName <> '' AND @HoursSinceLastFullRefresh < @UpdateIntervalAllItems
					Begin
						-- Less than @UpdateIntervalAllItems hours has elapsed since the last full update
						-- Bump up @IDMinimum to @DynamicMinimumCountThreshold less than the max ID in the target table
						
						Set @S = 'SELECT @MaxID = MAX([' + @IDColumnName + ']) FROM ' + @CacheTable
						
						If @LimitToMaxKnownDMSJobs = 1
							 Set @S = @S + ' WHERE [' + @IDColumnName + '] <= ' + Convert(varchar(12), @MaxKnownDMSJob)
						
						-- Params string for sp_ExecuteSql
						Set @Params = '@MaxID int output'
						
						Set @MaxID = 0
						exec sp_executesql @S, @Params, @MaxID = @MaxID output
						
						If IsNull(@MaxID, 0) > 0
						Begin
							Set @IDMinimum = @MaxID - @DynamicMinimumCountThreshold
							If @IDMinimum < 0
								Set @IDMinimum = 0
								
							If @InfoOnly <> 0
								Print 'Max ' + @IDColumnName + ' in ' + @CacheTable + ' is ' + Convert(Varchar(12), @MaxID) + '; will set minimum to ' + Convert(varchar(12), @IDMinimum)
						End
					End

					Set @S = 'Exec ' + @SP
					
					If @IDMinimum <> 0
						Set @S = @S + ' ' + Convert(varchar(12), @IDMinimum)
					
					
					If @InfoOnly = 0
						Exec (@S)
					Else
						Print 'Need to call ' + @SP + ' since last refreshed ' + Convert(varchar(32), @LastRefreshed) + '; ' + @S
						
				End -- </c>
			End -- </b>
			
			If @infoOnly <> 0
				Print ''
				
			Set @Iteration = @Iteration + 1
		End -- </a>
				
	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'RefreshCachedMTSInfoIfRequired')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done		
	End Catch
			
Done:
	Return @myError



GO
GRANT VIEW DEFINITION ON [dbo].[RefreshCachedMTSInfoIfRequired] TO [Limited_Table_Write] AS [dbo]
GO
