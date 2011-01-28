/****** Object:  StoredProcedure [dbo].[SetRequestedRunFactors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE SetRequestedRunFactors
/****************************************************
**
**	Desc: 
**	Update requested run factors from input XML list 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: grk
**	03/22/2010 grk - initial release
**    
*****************************************************/
	@factorList text,
	@message varchar(512) OUTPUT
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
						
	RETURN @myError
GO
GRANT EXECUTE ON [dbo].[SetRequestedRunFactors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetRequestedRunFactors] TO [Limited_Table_Write] AS [dbo]
GO
