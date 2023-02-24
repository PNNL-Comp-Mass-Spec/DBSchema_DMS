/****** Object:  UserDefinedFunction [dbo].[replace_character_codes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[replace_character_codes]
/****************************************************
**
**  Desc:   Replaces character codes with punctuation marks
**
**  Returns the updated string
**
**  Auth:   mem
**  Date:   02/25/2021 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @text varchar(2048)             -- Text to update
)
    RETURNS varchar(2048)
AS
Begin

    Set @text = IsNull(@text, '')

    If @text LIKE '%&quot;%'
        Set @text = Replace(@text, '&quot;', '"')

    If @text LIKE '%&#34;%'
        Set @text = Replace(@text, '&#34;', '"')

    If @text LIKE '%&amp;%'
        Set @text = Replace(@text, '&amp;', '&')

    Return @text
End

GO
GRANT VIEW DEFINITION ON [dbo].[replace_character_codes] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[replace_character_codes] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[replace_character_codes] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[replace_character_codes] TO [Limited_Table_Write] AS [dbo]
GO
