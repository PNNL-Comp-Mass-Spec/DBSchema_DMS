/****** Object:  UserDefinedFunction [dbo].[has_whitespace_chars] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[has_whitespace_chars]
/****************************************************
**  Checks for whitespace characters: CRLF, tab, and space
**  Allows symbols and letters, including periods, dashes,
**  and underscores
**
**  Returns 0 if no problems
**  Returns 1 if whitespace characters are present
**
**  This function is called by numerous Check Constraints,
**  including on tables T_Dataset and T_Experiments
**
**  Auth:   mem
**  Date:   02/15/2011
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
****************************************************/
(
    @entityName varchar(512),
    @allowSpace tinyint = 0
)
RETURNS tinyint
AS
BEGIN
    Declare @InvalidChars tinyint = 0

    If CharIndex(Char(10), @EntityName) > 0 OR                  -- CR
       CharIndex(Char(13), @EntityName) > 0 OR                  -- LF
       CharIndex(Char(9), @EntityName) > 0 OR                   -- Tab
       (@AllowSpace = 0 AND CharIndex(' ', @EntityName) > 0)    -- Space
    Begin
       Set @InvalidChars =1
    End

    RETURN @InvalidChars
END

GO
GRANT VIEW DEFINITION ON [dbo].[has_whitespace_chars] TO [DDL_Viewer] AS [dbo]
GO
