/****** Object:  StoredProcedure [dbo].[FormatErrorMessage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FormatErrorMessage]
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
