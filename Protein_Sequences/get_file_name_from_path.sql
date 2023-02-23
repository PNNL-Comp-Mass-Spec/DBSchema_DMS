/****** Object:  UserDefinedFunction [dbo].[get_file_name_from_path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_file_name_from_path]
/****************************************************
**  Looks for the final \ in @FilePath, then returns the filename after the slash
**  If no slash in @FilePath, or if no text after the slash, then returns an empty string
**
**  Auth:   mem
**  Date:   10/09/2006
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
****************************************************/
(
    @filePath varchar(4096)
)
RETURNS varchar(2048)
AS
BEGIN
    Declare @SlashLoc int
    Declare @PathLength int

    Declare @FileName varchar(2048)
    Set @FileName = ''

    Set @FilePath = LTrim(RTrim(IsNull(@FilePath, '')))

    Set @PathLength = Len(@FilePath)
    If @PathLength > 0
    Begin
        Set @SlashLoc = CharIndex('\', reverse(@FilePath))
        If @SlashLoc > 0
        Begin
            Set @SlashLoc = @PathLength - @SlashLoc + 1
            If @SlashLoc < @PathLength
            Begin
                Set @FileName = Substring(@FilePath, @SlashLoc+1, @PathLength)
            End
        End
    End

    RETURN @FileName
END

GO
GRANT EXECUTE ON [dbo].[get_file_name_from_path] TO [MTUser] AS [dbo]
GO
