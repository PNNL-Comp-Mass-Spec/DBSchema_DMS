/****** Object:  UserDefinedFunction [dbo].[merge_text] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[merge_text]
/****************************************************
**  Merges together the text in two variables
**  However, if the same text is present in each,
**  then it will be skipped
**
**  Auth:   mem
**  Date:   08/03/2007
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
****************************************************/
(
    @text1 varchar(2048),
    @text2 varchar(2048)
)
RETURNS varchar(8000)
AS
BEGIN
    Declare @CombinedText varchar(8000)

    Set @CombinedText = LTrim(RTrim(IsNull(@Text1, '')))
    Set @Text2 = LTrim(RTrim(IsNull(@Text2, '')))

    If Len(@Text2) > 0
    Begin
        If @CombinedText <> @Text2
        Begin
            If Len(@CombinedText) > 0
                Set @CombinedText = @CombinedText + '; ' + @Text2
            Else
                Set @CombinedText = @Text2
        End
    End

    RETURN  @CombinedText
END

GO
GRANT VIEW DEFINITION ON [dbo].[merge_text] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[merge_text] TO [public] AS [dbo]
GO
