/****** Object:  StoredProcedure [dbo].[ResetFailedDatasetCaptureTasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ResetFailedDatasetCaptureTasks
/****************************************************
** 
**	Desc:	Looks for dataset entries with state=5 (Capture Failed)
**			and a comment that indicates that we should be able to automatically
**			retry capture.  For example:
**			  "Dataset not ready: Exception validating constant folder size"
**			  "Dataset not ready: Exception validating constant file size"
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**	Date:	10/25/2016 mem - Initial version
**			10/27/2016 mem - Update T_Log_Entries in DMS_Capture
**			11/02/2016 mem - Check for Folder size changed and File size changed
**			01/30/2017 mem - Switch from DateDiff to DateAdd
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			08/08/2017 mem - Call RemoveCaptureErrorsFromString instead of RemoveFromString
**    
*****************************************************/
(
	@resetHoldoffHours real = 2,			-- Holdoff time to apply to column DS_Last_Affected
	@maxDatasetsToReset int = 0,			-- If greater than 0, then will limit the number of datasets to reset
	@infoOnly tinyint = 0,					-- 1 to preview the datasets that would be reset
	@message varchar(512) = '' output,		-- Status message
	@resetCount int = 0 output				-- Number of datasets that were reset
)
As
	Set XACT_ABORT, nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	------------------------------------------------
	-- Validate the inputs
	------------------------------------------------

	Set @resetHoldoffHours = IsNull(@resetHoldoffHours, 2)
	Set @maxDatasetsToReset = IsNull(@maxDatasetsToReset, 0)
	Set @infoOnly = IsNull(@infoOnly, 0)

	Set @message = ''
	Set @resetCount = 0
	
	If @maxDatasetsToReset <= 0
		Set @maxDatasetsToReset = 1000000

	
	BEGIN TRY

		------------------------------------------------
		-- Create a temporary table
		------------------------------------------------
		--
		CREATE TABLE #Tmp_Datasets (
			Dataset_ID int not null,
			Dataset varchar(128) not null
		)
		
		------------------------------------------------
		-- Populate a temporary table with datasets
		-- that have Dataset State 5=Capture Failed
		-- and a comment containing Exception validating constant
		------------------------------------------------
		--
		INSERT INTO #Tmp_Datasets( Dataset_ID,
		                           Dataset )
		SELECT TOP ( @maxDatasetsToReset ) Dataset_ID,
		       Dataset_Num AS Dataset
		FROM T_Dataset
		WHERE DS_state_ID = 5 AND
		      (DS_comment LIKE '%Exception validating constant%' OR
		       DS_comment LIKE '%File size changed%' OR
		       DS_comment LIKE '%Folder size changed%') AND
		       DS_Last_Affected < DateAdd(Minute, -@resetHoldoffHours * 60, GetDate())
		ORDER BY Dataset_ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount = 0
		Begin
			Set @message = 'No candidate datasets were found to reset'
			If @infoOnly <> 0
				SELECT @message AS Message

		End
		Else
		Begin -- <a>
			If @infoOnly <> 0
			Begin -- <b1>
				------------------------------------------------
				-- Preview the datasets to reset
				------------------------------------------------
				--
				SELECT DS.Dataset_Num AS Dataset,
					DS.Dataset_ID AS Dataset_ID,
					Inst.IN_name AS Instrument,
					DS.DS_state_ID AS State,
					DS.DS_Last_Affected AS Last_Affected,
					DS.DS_comment AS [Comment]
				FROM #Tmp_Datasets Src
					INNER JOIN T_Dataset DS
					ON Src.Dataset_ID = DS.Dataset_ID
					INNER JOIN T_Instrument_Name Inst
					ON DS.DS_instrument_name_ID = Inst.Instrument_ID
				ORDER BY Inst.IN_name, DS.Dataset_Num
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount

			End -- </b1>
			Else
			Begin -- <b2>
				------------------------------------------------
				-- Reset the datasets
				------------------------------------------------
				--
				UPDATE T_Dataset
				SET DS_state_ID = 1,
					DS_Comment = dbo.RemoveCaptureErrorsFromString(DS_Comment)
				FROM #Tmp_Datasets Src
					INNER JOIN T_Dataset DS
					ON Src.Dataset_ID = DS.Dataset_ID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount

				Set @resetCount = @myRowCount
				
				Set @message = 'Reset dataset state from "Capture Failed" to "New" for ' + Cast(@resetCount as varchar(9)) + 
				               dbo.CheckPlural(@resetCount, ' Dataset', ' Datasets')
				Exec PostLogEntry 'Normal', @message, 'ResetFailedDatasetCaptureTasks'
				
				------------------------------------------------
				-- Look for log entries in DMS_Capture to auto-update
				------------------------------------------------
				--
				
				Declare @DatasetID int = -1
				Declare @DatasetName varchar(128)				
				Declare @continue tinyint = 1
				
				While @continue = 1
				Begin -- <cc>
				
					SELECT TOP 1 @DatasetID = Dataset_ID,
					             @DatasetName = Dataset
					FROM #Tmp_Datasets
					WHERE Dataset_ID > @DatasetID
					ORDER BY Dataset_ID
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount

					If @myRowCount = 0
					Begin
						Set @continue = 0
					End
					Else
					Begin -- <d>
						UPDATE DMS_Capture.dbo.T_Log_Entries
						SET [Type] = 'ErrorAutoFixed'
						WHERE ([Type] = 'error') AND
						      (message LIKE '%' + @DatasetName + '%') AND
						      (message LIKE '%exception%') AND
						      (posting_time < GetDate())
						--
						SELECT @myError = @@error, @myRowCount = @@rowcount

					End -- </d>
				End -- </c>
								
			End -- </b2>
		End -- </a>
		
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output		
		Exec PostLogEntry 'Error', @message, 'ResetFailedDatasetCaptureTasks'
	END CATCH

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ResetFailedDatasetCaptureTasks] TO [DDL_Viewer] AS [dbo]
GO
