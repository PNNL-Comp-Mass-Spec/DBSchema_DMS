/****** Object:  UserDefinedFunction [dbo].[append_to_text] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[append_to_text]
/****************************************************
**
**  Desc:   Appends a new string to an existing string, using the specified delimiter
**          Use @addDuplicateText = 0 to prevent duplicate text from being added
**          Use @addDuplicateText = 1 to allow duplicate text to be added
**
**  Returns the updated comment
**
**  Auth:   mem
**  Date:   05/12/2010 mem - Initial version
**          06/12/2018 mem - Add parameter @maxLength
***         08/20/2022 mem - Do not append the delimiter if already present at the end of the base text
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @text varchar(1024),
    @addnlText varchar(1024),
    @addDuplicateText tinyint = 0,
    @delimiter varchar(10) = '; ',
    @maxLength int = 1024
)
    RETURNS varchar(1024)
AS
Begin

    Declare @charLoc int

    If IsNull(@text, '') = ''
        Set @text = ''

    If IsNull(@addnlText, '') <> ''
    Begin
        Set @charLoc = 0
        Set @charLoc = CharIndex(@addnlText, @text)

        If @charLoc = 0 Or @addDuplicateText <> 0
        Begin
            If @text = ''
            Begin
                Set @text = @addnlText
            End
            Else
            Begin
                If Len(Ltrim(Rtrim(@delimiter))) > 0 And RTrim(@text) Like '%' + RTrim(@delimiter)
                Begin
                    -- The text already ends with the delimiter, though we may need to add a space
                    If @delimiter Like '% ' And Not @text Like '% '
                        Set @text = @text + ' '
                End
                Else
                Begin
                    Set @text = @text + @delimiter
                End

                Set @text = @text + @addnlText
            End
        End
    End

    If @maxLength > 0 And Len(@text) > @maxLength
    Begin
        Set @text = Substring(@text, 1, @maxLength)
    End

    Return @text
End

GO
GRANT VIEW DEFINITION ON [dbo].[append_to_text] TO [DDL_Viewer] AS [dbo]
GO
