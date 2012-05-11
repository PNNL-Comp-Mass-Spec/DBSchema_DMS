/****** Object:  StoredProcedure [dbo].[MasterUpdateProteinDatabase] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.MasterUpdateProteinDatabase
/****************************************************
**
**	Desc:	Calls routine update procedures for the protein database
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	09/13/2007
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

	Set @message = ''

	Declare @result int
	
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Begin Try
	
		set @result = 0
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'PromoteProteinCollectionStates')
		If @result > 0
		Begin
			Set @CurrentLocation = 'Call PromoteProteinCollectionState'
			Exec @myError = PromoteProteinCollectionState @message = @message output
			If @myError <> 0
				Goto Done
		End

		
		Set @message = ''
		
	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'MasterUpdateProteinDatabase')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done
	End Catch
		
Done:
	Return @myError

GO
