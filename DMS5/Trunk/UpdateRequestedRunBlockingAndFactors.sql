/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunBlockingAndFactors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateRequestedRunBlockingAndFactors
/****************************************************
**
**	Desc: 
**	Update requested run factors and blocking 
**  from input XML lists 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 02/21/2010
**    
*****************************************************/
	@blockingList text,
	@factorList text,
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = ''
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

	-----------------------------------------------------------
	-- 
	-----------------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunBlockingAndFactors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBlockingAndFactors] TO [Limited_Table_Write] AS [dbo]
GO
