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
**    
*****************************************************/
(
	@resetHoldoffHours real = 2,			-- Holdoff time to apply to column DS_Last_Affected
	@maxDatasetsToReset int = 0,			-- If greater than 0, then will limit the number of datasets to reset
	@infoOnly tinyint = 0,					-- 1 to preview the datasets that would be reset
	@message varchar(512) = '' output,		-- Status message
	@resetCount int = 0 output				-- Number of datasets reset
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

		If @infoOnly <> 0
		Begin
			------------------------------------------------
			-- Preview all datasets with a Dataset State of 5=Capture Failed
			-- and a comment containing Exception validating constan
			------------------------------------------------

			SELECT DS.Dataset_Num AS Dataset,
			       DS.Dataset_ID AS Dataset_ID,
			       Inst.IN_name AS Instrument,
			       DS.DS_state_ID AS State,
			       DS.DS_Last_Affected AS Last_Affected,
			       DS.DS_comment AS COMMENT
			FROM T_Dataset DS
			     INNER JOIN T_Instrument_Name Inst
			       ON DS.DS_instrument_name_ID = Inst.Instrument_ID
			WHERE DS.DS_state_ID = 5 AND
			      DS.DS_comment LIKE '%Exception validating constant%' AND
			      DATEDIFF(MINUTE, DS.DS_Last_Affected, GETDATE()) >= @resetHoldoffHours * 60
			ORDER BY Inst.IN_name, DS.Dataset_Num
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

		End
		Else
		Begin
			------------------------------------------------
			-- Reset up to @maxDatasetsToReset datasets
			-- that currently have a state of 5
			------------------------------------------------

			UPDATE T_Dataset
			SET DS_state_ID = 1,
			    DS_Comment = dbo.RemoveFromString(dbo.RemoveFromString(DS_Comment, 
			                   'Dataset not ready: Exception validating constant file size'), 
			                   'Dataset not ready: Exception validating constant folder size')
			FROM T_Dataset DS
			     INNER JOIN ( SELECT TOP ( @maxDatasetsToReset ) Dataset_ID
			                  FROM T_Dataset DS
			                  WHERE DS.DS_state_ID = 5 AND
			                        DS.DS_comment LIKE '%Exception validating constant%' AND
			                        DATEDIFF(MINUTE, DS.DS_Last_Affected, GETDATE()) >= @resetHoldoffHours * 60 
			                  ) LookupQ
			       ON DS.Dataset_ID = LookupQ.Dataset_ID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			Set @resetCount = @myRowCount
			
			If @resetCount > 0
			Begin
				Set @message = 'Reset dataset state from "Capture Failed" to "New" for ' + Convert(varchar(12), @myRowCount) + ' Datasets'
				Exec PostLogEntry 'Normal', @message, 'ResetFailedDatasetCaptureTasks'
			End
			Else
			Begin
				Set @message = 'No candidate datasets were found to reset'
			End
		End

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
	END CATCH

	return @myError

GO
