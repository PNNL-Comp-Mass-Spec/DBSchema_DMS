/****** Object:  StoredProcedure [dbo].[get_signature] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_signature]
/****************************************************
**
**  Desc:
**    Get signature ID for given input string
**
**    Input string is hashed to pattern, and stored in table T_Signatures
**    Signature is integer reference to pattern
**
**  Auth:   grk
**  Date:   08/22/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          03/22/2011 mem - Now populating String, Entered, and Last_Used in T_Signatures
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**                         - Replace call to function bin2hex with CONVERT(varchar, varbinary value, 2)
**          03/13/2023 mem - Restore behavior of the SHA-1 hash being 32 characters long
**
*****************************************************/
(
    @s varchar(max)
)
AS
    Declare @pattern varchar(32)
    Declare @reference int

    Set @reference = 0

    ---------------------------------------------------
    -- Convert @s to hash (upper case hex string)
    --
    -- Use HashBytes() to get the full SHA-1 hash, as a varbinary
    -- Use Convert() to convert to text, truncating to only use the first 32 characters
    -- The '2' sent to Convert() means 'no 0x prefix'
    ---------------------------------------------------

    Set @pattern = CONVERT(varchar(32), HashBytes('SHA1', @s), 2)

    ---------------------------------------------------
    -- Is it already in the signatures table?
    ---------------------------------------------------
    --
    SELECT @reference = Reference
    FROM T_Signatures
    WHERE Pattern = @pattern

    If @reference = 0
    Begin

        ---------------------------------------------------
        -- Pattern not found; add it
        ---------------------------------------------------

        INSERT INTO T_Signatures( Pattern,
                                  String,
                                  Entered,
                                  Last_Used )
        VALUES(@pattern, @s, GetDate(), GetDate())

        ---------------------------------------------------
        -- Get Reference for newly-inserted Pattern
        ---------------------------------------------------
        --
        SELECT @reference = Reference
        FROM T_Signatures
        WHERE Pattern = @pattern

    End
    Else
    Begin
        ---------------------------------------------------
        -- Update Last_Used and possibly update String
        ---------------------------------------------------
        --
        IF Exists (SELECT * FROM T_Signatures WHERE Reference = @reference AND string IS NULL)
            UPDATE T_Signatures
            SET Last_Used = GetDate(),
                String = @s
            WHERE Reference = @reference
        Else
            UPDATE T_Signatures
            SET Last_Used = GetDate()
            WHERE Reference = @reference
    End


    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    RETURN @reference

GO
GRANT VIEW DEFINITION ON [dbo].[get_signature] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_signature] TO [Limited_Table_Write] AS [dbo]
GO
