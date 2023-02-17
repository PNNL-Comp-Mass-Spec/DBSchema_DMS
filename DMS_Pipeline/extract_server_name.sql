/****** Object:  UserDefinedFunction [dbo].[extract_server_name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[extract_server_name]
/****************************************************
**  Extracts the server name from the given path
**
**  Auth:   mem
**  Date:   03/03/2010
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
****************************************************/
(
    @Path varchar(2048)
)
RETURNS varchar(2048)
AS
BEGIN
    Declare @ServerName varchar(2048)
    Declare @CharLoc int

    Set @Path = LTrim(IsNull(@Path, ''))

    -- Initially set @ServerName equal to @Path
    Set @ServerName = @Path

    If Len(@Path) > 0
    Begin
        -- Remove any "\" characters from the front of @Path
        While @Path LIKE '\%'
        Begin
            Set @Path = SubString(@Path, 2, Len(@Path))
        End

        -- Look for the next "\" character
        Set @CharLoc = CharIndex('\', @Path)

        If @CharLoc = 0
            Set @ServerName = @Path
        Else
            Set @ServerName = SubString(@Path, 1, @CharLoc-1)

    End

    RETURN  @ServerName
END

GO
GRANT VIEW DEFINITION ON [dbo].[extract_server_name] TO [DDL_Viewer] AS [dbo]
GO
