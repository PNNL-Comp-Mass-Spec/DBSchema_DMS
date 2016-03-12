/****** Object:  StoredProcedure [dbo].[UpdateMTSCachedDataStatus] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.UpdateMTSCachedDataStatus
/****************************************************
**
**	Desc:	Updates the data in T_MTS_Cached_Data_Status using MTS
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	02/05/2010 mem - Initial Version
**			02/23/2016 mem - Add set XACT_ABORT on
**
*****************************************************/
(
	@CachedDataTableName varchar(128),
	@IncrementRefreshCount tinyint = 0,
	@InsertCountNew int = 0,				-- Ignored if @IncrementRefreshCount = 0
	@UpdateCountNew int = 0,				-- Ignored if @IncrementRefreshCount = 0
	@DeleteCountNew int = 0,				-- Ignored if @IncrementRefreshCount = 0
	@FullRefreshPerformed tinyint = 0,		-- When 1, then updates both Last_Refreshed and Last_Full_Refresh; otherwise, just updates Last_Refreshed
	@LastRefreshMinimumID int = 0,
	@message varchar(255) = '' output
)
AS

	Set XACT_ABORT, nocount on

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	set @message = ''
	
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	Begin Try
		Set @CurrentLocation = 'Validate the inputs'

		Set @CachedDataTableName = LTrim(RTrim(IsNull(@CachedDataTableName, '')))

		-- Abort if @CachedDataTableName is blank
		If Len(@CachedDataTableName) = 0
		Begin
			Set @message = '@CachedDataTableName is blank; unable to continue'
			SELECT @message AS Error_Message
			Goto Done
		End

		Set @IncrementRefreshCount = IsNull(@IncrementRefreshCount, 0)

		-- Assure that @IncrementRefreshCount is 0 or 1
		If @IncrementRefreshCount <> 0
			Set @IncrementRefreshCount = 1
		
		If @IncrementRefreshCount = 0
		Begin
			-- Force the new counts to 0
			Set @InsertCountNew = 0
			Set @UpdateCountNew = 0
			Set @DeleteCountNew = 0
		End
		Else
		Begin
			-- Validate the new counts
			Set @InsertCountNew = IsNull(@InsertCountNew, 0)
			Set @UpdateCountNew = IsNull(@UpdateCountNew, 0)
			Set @DeleteCountNew = IsNull(@DeleteCountNew, 0)
		End				

		Set @FullRefreshPerformed = IsNull(@FullRefreshPerformed, 0)
		Set @LastRefreshMinimumID = IsNull(@LastRefreshMinimumID, 0)
		Set @message = ''
		
		
		Set @CurrentLocation = 'Make sure @CachedDataTableName exists in T_MTS_Cached_Data_Status'
		--
		If Not Exists (SELECT Table_Name FROM T_MTS_Cached_Data_Status WHERE Table_Name = @CachedDataTableName)
			INSERT INTO T_MTS_Cached_Data_Status (Table_Name, Refresh_Count)
			Values (@CachedDataTableName, 0)
		
		Set @CurrentLocation = 'Update the stats in T_MTS_Cached_Data_Status'
		--
		UPDATE T_MTS_Cached_Data_Status
		SET Refresh_Count = Refresh_Count + @IncrementRefreshCount,
			Insert_Count = Insert_Count + @InsertCountNew,
			Update_Count = Update_Count + @UpdateCountNew,
			Delete_Count = Delete_Count + @DeleteCountNew,
			Last_Refreshed = GetDate(),
			Last_Refresh_Minimum_ID = @LastRefreshMinimumID,
			Last_Full_Refresh = CASE WHEN @FullRefreshPerformed = 0 THEN Last_Full_Refresh ELSE GetDate() END
		WHERE Table_Name = @CachedDataTableName
		--
		SELECT @myRowCount = @@RowCount, @myError = @@Error
		
	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateMTSCachedDataStatus')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done
	End Catch
	
Done:
	Return @myError



GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMTSCachedDataStatus] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMTSCachedDataStatus] TO [PNL\D3M578] AS [dbo]
GO
