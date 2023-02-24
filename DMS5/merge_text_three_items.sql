/****** Object:  UserDefinedFunction [dbo].[MergeTextThreeItems] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[MergeTextThreeItems]
/****************************************************
**  Merges together the text in three variables
**  However, if the same text is present in each,
**  then it will be skipped
**
**  Auth:   mem
**  Date:   08/03/2007
**
****************************************************/
(
    @Text1 varchar(2048),
    @Text2 varchar(2048),
    @Text3 varchar(2048)
)
RETURNS varchar(8000)
AS
BEGIN
    Declare @CombinedText varchar(8000)

    Set @Text1 = LTrim(RTrim(IsNull(@Text1, '')))
    Set @Text2 = LTrim(RTrim(IsNull(@Text2, '')))
    Set @Text3 = LTrim(RTrim(IsNull(@Text3, '')))

    Set @CombinedText = dbo.MergeText(@Text1, @Text2)

    If Len(@Text3) > 0
    Begin
        If @Text1 <> @Text3 AND @Text2 <> @Text3
        Begin
            If Len(@CombinedText) > 0
                Set @CombinedText = @CombinedText + '; ' + @Text3
            Else
                Set @CombinedText = @Text3
        End
    End

    RETURN @CombinedText
END

GO
GRANT VIEW DEFINITION ON [dbo].[MergeTextThreeItems] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[MergeTextThreeItems] TO [public] AS [dbo]
GO
