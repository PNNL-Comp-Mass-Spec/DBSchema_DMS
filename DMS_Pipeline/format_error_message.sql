/****** Object:  StoredProcedure [dbo].[format_error_message] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[format_error_message]
/****************************************************
**
**  Desc:   Formats error message string
**          Must be called from within CATCH block
**
**  Return values:  Message string
**
**  Auth:   grk
**  Date:   04/16/2010 grk - Initial release
**          06/20/2018 mem - Allow for Error_Procedure() to be null
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @message varchar(512) output,
    @myError int output
)
AS
    Set @myError = ERROR_NUMBER()

    If @myError = 50000
    Begin
        Set @myError = 51000 + ERROR_STATE()
    End

    If ERROR_PROCEDURE() Is Null
        Set @message = ERROR_MESSAGE() + ' (Line ' + Cast(ERROR_LINE() As varchar(12)) + ')'
    Else
        Set @message = ERROR_MESSAGE() + ' (' + ERROR_PROCEDURE() + ':' + Cast(ERROR_LINE() As varchar(12)) + ')'

GO
GRANT VIEW DEFINITION ON [dbo].[format_error_message] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[format_error_message] TO [Limited_Table_Write] AS [dbo]
GO
