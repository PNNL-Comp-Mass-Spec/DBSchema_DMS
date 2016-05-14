/****** Object:  StoredProcedure [dbo].[SetRequestedRunFactors] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[SetRequestedRunFactors]
/****************************************************
**
**	Desc: 
**	Update requested run factors from input XML list 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date: 	03/22/2010 grk - initial release
**			09/02/2011 mem - Now calling PostUsageLogEntry
**    
*****************************************************/
(
	@factorList text,
	@message varchar(512) OUTPUT
)
As
	SET NOCOUNT ON 

	declare @myError int
	set @myError = 0

	DECLARE @callingUser varchar(128)
	SET @callingUser = REPLACE(SUSER_SNAME(), 'PNL\', '')
	
	IF NOT EXISTS (SELECT * FROM T_Users WHERE U_PRN = @callingUser)
	BEGIN 
		SET @myError = 51001
		SET @message = 'User "' + @callingUser + '" does not appear among DMS users'
		RETURN @myError
	END 

	EXEC @myError = UpdateRequestedRunFactors
						@factorList,
						@message OUTPUT,
						@callingUser

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = ''
	Exec PostUsageLogEntry 'SetRequestedRunFactors', @UsageMessage
	
	RETURN @myError

GO

GRANT EXECUTE ON [dbo].[SetRequestedRunFactors] TO [DMS2_SP_User] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetRequestedRunFactors] TO [Limited_Table_Write] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetRequestedRunFactors] TO [PNL\D3M578] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetRequestedRunFactors] TO [PNL\D3M580] AS [dbo]
GO

