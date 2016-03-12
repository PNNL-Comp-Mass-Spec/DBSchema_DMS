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
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date: 	02/21/2010
**			09/02/2011 mem - Now calling PostUsageLogEntry
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

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	DECLARE @xml AS xml
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	SET @message = ''

	-----------------------------------------------------------
	-- 
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
	-- 
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
GRANT EXECUTE ON [dbo].[UpdateRequestedRunBlockingAndFactors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBlockingAndFactors] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBlockingAndFactors] TO [PNL\D3M578] AS [dbo]
GO
