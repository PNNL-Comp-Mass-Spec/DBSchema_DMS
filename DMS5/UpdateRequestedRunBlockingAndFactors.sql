/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunBlockingAndFactors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.UpdateRequestedRunBlockingAndFactors
/****************************************************
**
**	Desc: 
**		Update requested run factors and blocking from input XML lists 
**		Called from http://dmsdev.pnl.gov/requested_run_batch_blocking/param
**
**		Example contents of @blockingList:
**		<r i="545496" t="Run_Order" v="2" /><r i="545496" t="Block" v="2" />
**		<r i="545497" t="Run_Order" v="1" /><r i="545497" t="Block" v="1" />
**
**		Example contents of @factorList: 
**		<id type="Request" /><r i="545496" f="TempFactor" v="a" /><r i="545497" f="TempFactor" v="b" />
**
**		@blockingList can be empty if @factorList is defined
**		Conversely, @factorList may be simply '<id type="Request" />' if updating run order and blocking
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date: 	02/21/2010
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			11/07/2016 mem - Add optional logging via PostLogEntry
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
	@blockingList text,
	@factorList text,
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = ''
)
As
	SET NOCOUNT ON 

	declare @myError int = 0
	declare @myRowCount int = 0

	DECLARE @xml AS xml
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	Set @message = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'UpdateRequestedRunBlockingAndFactors', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	Declare @debugEnabled tinyint = 0
	
	If @debugEnabled > 0
	Begin
		Declare @logMessage varchar(4096)
		
		Set @logMessage = Cast(@blockingList as varchar(4000))
		If IsNull(@logMessage, '') = ''
			Set @logMessage = '@blockingList is empty'
		Else
			Set @logMessage = '@blockingList: ' + @logMessage
		
		exec PostLogEntry 'Debug', @logMessage, 'UpdateRequestedRunBlockingAndFactors'
			
		Set @logMessage = Cast(@factorList as varchar(4000))
		If IsNull(@logMessage, '') = ''
			Set @logMessage = '@factorList is empty'
		Else
			Set @logMessage = '@factorList: ' + @logMessage
		
		exec PostLogEntry 'Debug', @logMessage, 'UpdateRequestedRunBlockingAndFactors'
	End
		
	-----------------------------------------------------------
	-- Update the blocking and run order
	-----------------------------------------------------------
	--
	IF DATALENGTH(@blockingList) > 0
	BEGIN
		EXEC @myError = UpdateRequestedRunBatchParameters
							@blockingList,
							'update',
							@message OUTPUT,
							@callingUser
		IF @myError <> 0
		BEGIN
			GOTO Done
		END
	END


	-----------------------------------------------------------
	-- Update the factors
	-----------------------------------------------------------
	--

	EXEC @myError = UpdateRequestedRunFactors
							@factorList,
							@message  OUTPUT,
							@callingUser 
	IF @myError <> 0
	BEGIN
		GOTO Done
	END

Done:
	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512) = ''
	Set @UsageMessage = ''
	Exec PostUsageLogEntry 'UpdateRequestedRunBlockingAndFactors', @UsageMessage


	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBlockingAndFactors] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunBlockingAndFactors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBlockingAndFactors] TO [Limited_Table_Write] AS [dbo]
GO
