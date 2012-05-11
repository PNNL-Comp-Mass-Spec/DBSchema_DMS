/****** Object:  StoredProcedure [dbo].[FormatErrorMessage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE FormatErrorMessage
/****************************************************
**
**  Desc: 
**  Formats error message string
**  Must be called from within CATCH block
**
**  Return values: message string
**
**  Parameters:
**
**  Auth: grk
**  04/16/2010 grk - Initial release
**    
*****************************************************/
@message varchar(512) output,
@myError int output
AS
	SET @myError = ERROR_NUMBER()
	
	IF @myError = 50000
		SET @myError = 51000 + ERROR_STATE()

	SET @message = ERROR_MESSAGE() + ' (' + ERROR_PROCEDURE() + ':' + CONVERT(VARCHAR(12), ERROR_LINE()) + ')'

GO
GRANT VIEW DEFINITION ON [dbo].[FormatErrorMessage] TO [Limited_Table_Write] AS [dbo]
GO
