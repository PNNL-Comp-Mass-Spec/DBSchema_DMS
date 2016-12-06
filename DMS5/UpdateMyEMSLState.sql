/****** Object:  StoredProcedure [dbo].[UpdateMyEMSLState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.UpdateMyEMSLState
/****************************************************
**
**	Desc:	Updates the MyEMSL State for a given dataset and/or its analysis jobs
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	09/11/2013 mem - Initial Version
**			10/18/2013 mem - No excluding jobs that are in-progress when @AnalysisJobResultsFolder is empty
**
*****************************************************/
(
	@DatasetID int,
	@AnalysisJobResultsFolder varchar(128),
	@MyEMSLState int
)
AS

	Set NoCount On

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	If IsNull(@AnalysisJobResultsFolder, '') = ''
	Begin
		-- Update the dataset and all existing jobs
		--
		UPDATE T_Dataset_Archive
		SET MyEMSLState = @MyEMSLState
		WHERE AS_Dataset_ID = @DatasetID AND
				MyEMSLState < @MyEMSLState

		UPDATE T_Analysis_Job
		SET AJ_MyEMSLState = @MyEMSLState
		WHERE AJ_DatasetID = @DatasetID AND
				AJ_MyEMSLState < @MyEMSLState AND
				AJ_StateID IN (4, 7, 14)

	End
	Else
	Begin
		-- Update the job that corresponds to @AnalysisJobResultsFolder
		--
		UPDATE T_Analysis_Job
		SET AJ_MyEMSLState = @MyEMSLState
		WHERE AJ_DatasetID = @DatasetID AND
				AJ_ResultsFolderName = @AnalysisJobResultsFolder AND
				AJ_MyEMSLState < @MyEMSLState
				
	End

Done:
	Return @myError



GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMyEMSLState] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateMyEMSLState] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMyEMSLState] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateMyEMSLState] TO [svc-dms] AS [dbo]
GO
