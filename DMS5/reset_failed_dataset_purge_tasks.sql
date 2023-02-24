/****** Object:  StoredProcedure [dbo].[ResetFailedDatasetPurgeTasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ResetFailedDatasetPurgeTasks
/****************************************************
** 
**	Desc:	Looks for dataset archive entries with state 8=Purge Failed
**			Examines the "Archive State Last Affected" column and 
**			  resets any entries that entered the Purge Failed state
**			  at least @ResetHoldoffHours hours before the present
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**	Date:	07/12/2010 mem - Initial version
**			12/13/2010 mem - Changed @ResetHoldoffHours from tinyint to real
**			02/23/2016 mem - Add set XACT_ABORT on
**			01/30/2017 mem - Switch from DateDiff to DateAdd
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**    
*****************************************************/
(
	@ResetHoldoffHours real = 2,			-- Holdoff time to apply to column AS_state_Last_Affected
	@MaxTasksToReset int = 0,				-- If greater than 0, then will limit the number of tasks to reset
	@InfoOnly tinyint = 0,					-- 1 to preview the tasks that would be reset
	@message varchar(512) = '' output,		-- Status message
	@ResetCount int = 0 output				-- Number of tasks reset
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

	Set @ResetHoldoffHours = IsNull(@ResetHoldoffHours, 2)
	Set @MaxTasksToReset = IsNull(@MaxTasksToReset, 0)
	Set @InfoOnly = IsNull(@InfoOnly, 0)

	Set @message = ''
	Set @ResetCount = 0
	
	If @MaxTasksToReset <= 0
		Set @MaxTasksToReset = 1000000
		
	BEGIN TRY

		If @infoOnly <> 0
		Begin
			------------------------------------------------
			-- Preview all datasets with an Archive State of 8=Purge Failed
			------------------------------------------------

			SELECT SPath.SP_vol_name_client AS Server,
			       SPath.SP_instrument_name AS Instrument,
			       DS.Dataset_Num AS Dataset,
			       DA.AS_Dataset_ID AS Dataset_ID,
			       DA.AS_state_ID AS State,
			       DA.AS_state_Last_Affected AS Last_Affected
			FROM T_Dataset_Archive DA
			     INNER JOIN T_Dataset DS
			       ON DA.AS_Dataset_ID = DS.Dataset_ID
			     INNER JOIN t_storage_path SPath
			       ON DS.DS_storage_path_ID = SPath.SP_path_ID
			WHERE DA.AS_state_ID = 8 AND
			      DA.AS_state_Last_Affected < DateAdd(minute, -@ResetHoldoffHours * 60, GETDATE())
			ORDER BY SPath.SP_vol_name_client, SPath.SP_instrument_name, DS.Dataset_Num
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

		End
		Else
		Begin
			------------------------------------------------
			-- Reset up to @MaxTasksToReset archive tasks
			-- that currently have an archive state of 8
			------------------------------------------------

			UPDATE T_Dataset_Archive
			SET AS_state_ID = 3
			FROM T_Dataset_Archive DA
			     INNER JOIN ( SELECT TOP ( @MaxTasksToReset ) AS_Dataset_ID
			                  FROM T_Dataset_Archive DA
			                  WHERE (DA.AS_state_ID = 8) AND
			                        (DATEDIFF(MINUTE, DA.AS_state_Last_Affected, GETDATE()) >= @ResetHoldoffHours * 60) 
			                ) LookupQ
			       ON DA.AS_Dataset_ID = LookupQ.AS_Dataset_ID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			Set @ResetCount = @myRowCount
			
			If @ResetCount > 0
				Set @message = 'Reset dataset archive state from "Purge Failed" to "Complete" for ' + Convert(varchar(12), @myRowCount) + ' Datasets'
			Else
				Set @message = 'No candidate tasks were found to reset'
		End
	

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output		
		Exec PostLogEntry 'Error', @message, 'ResetFailedDatasetPurgeTasks'
	END CATCH

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ResetFailedDatasetPurgeTasks] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ResetFailedDatasetPurgeTasks] TO [Limited_Table_Write] AS [dbo]
GO
