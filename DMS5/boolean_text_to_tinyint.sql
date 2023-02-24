/****** Object:  UserDefinedFunction [dbo].[boolean_text_to_tinyint] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[boolean_text_to_tinyint]
/****************************************************
**
**  Desc:
**      Returns 1 if @booleanText is Yes, Y, 1, True, or T
**      Otherwise, returns 0
**
**  Auth:   mem
**  Date:   05/28/2019 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @booleanText Varchar(32)
)
RETURNS tinyint
AS
Begin

    Declare @value Tinyint = 0
    Set @booleanText = LTrim(Rtrim(IsNull(@booleanText, '')))

    If @booleanText = 'Yes' Or @booleanText = 'Y' OR @booleanText = '1' Or @booleanText = 'True' Or @booleanText = 'T'
        Set @value = 1

    Return @value
End

GO
