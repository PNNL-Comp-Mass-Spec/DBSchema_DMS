/****** Object:  UserDefinedFunction [dbo].[get_filename] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_filename]
/****************************************************
** Examines @filePath to look for a filename
** If found, returns the filename, otherwise, returns @filePath
**
**  Auth:   mem
**  Date:   05/18/2017
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
****************************************************/
(
    @filePath varchar(255)
)
RETURNS varchar(255)
AS
BEGIN
    Declare @lastSlashIndex int
    Declare @charIndex int
    Declare @filename varchar(255) = null

    If Not @filePath Is Null
    Begin
        Set @charIndex = CHARINDEX('\', REVERSE(@filePath))
        If @charIndex = 0
            Set @filename = @filePath
        Else
        Begin
            Set @lastSlashIndex = Len(@filePath) - @charIndex + 1
            Set @filename = Substring(@filePath, @lastSlashIndex + 1, Len(@filePath))
        End
    End

    RETURN @filename
END

GO
