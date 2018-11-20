/****** Object:  UserDefinedFunction [dbo].[udfParseDelimitedListOrdered] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udfParseDelimitedListOrdered]
/****************************************************    
**
**  Parses the text in @delimitedList and returns a table
**  containing the values. The table includes column EntryID
**  to allow the calling procedure to sort the data based on the 
**  data order in @delimitedList.  The first row will have EntryID = 1
**
**  @delimitedList should be of the form 'Value1,Value2'
**
**  Note that if two commas in a row are encountered, the resultant table
**  will contain an empty cell for that row
**
**  If @delimiter is Char(13) or Char(10), will split @delimitedList on CR or LF
**  In this case, blank lines will not be included in table @tmpValues
**
**  Auth:   mem
**  Date:   10/16/2007
**          03/27/2013 mem - Now replacing Tab characters, carriage returns and line feeds with @delimiter
**          11/19/2018 mem - Add special handling if @delimeter is CR, LF, or CRLF
**                         - Add parameter @maxRows
**  
****************************************************/
(
    @delimitedList varchar(max),
    @delimiter varchar(2) = ',',
    @maxRows int = 0               -- Optionally set this to a positive number to limit the number of rows returned in @tmpValues.
                                   -- This is useful if you are parsing a comma-separated list of items, 
                                   -- and the final item is a comment field, which itself might contain commas.
)
RETURNS @tmpValues TABLE(EntryID int NOT NULL, Value varchar(2048) NULL)
AS
BEGIN
    
    Declare @continue tinyint
    Declare @startPosition int

    Declare @delimiterPos int
    Declare @crPos int
    Declare @lfPos int
    
    Declare @delimiterIsCRorLF tinyint = 0

    Declare @value varchar(2048)
    Declare @entryID int = 1
    
    Set @delimitedList = IsNull(@delimitedList, '')
    
    If @delimiter Like '%' + Char(13) + '%' Or
       @delimiter Like '%' + Char(10) + '%'
    Begin
        Set @delimiterIsCRorLF = 1
        
        -- The logic below will match either CR or LF, so it doesn't matter what @delimiter is
        Set @delimiter = char(10)
    End

    If Len(@delimitedList) > 0
    Begin -- <a>
        
        If @delimiterIsCRorLF = 0
        Begin
            -- Replace any CR or LF characters with @delimiter
            If @delimitedList Like '%' + Char(13) + '%'
            Begin
                Set @delimitedList = LTrim(RTrim(Replace(@delimitedList, Char(13),  @delimiter)))
            End

            If @delimitedList Like '%' + Char(10) + '%'
            Begin
                Set @delimitedList = LTrim(RTrim(Replace(@delimitedList, Char(10),  @delimiter)))
            End

            If @delimiter <> Char(9)
            Begin
                -- Replace any tab characters with @delimiter
                If @delimitedList Like '%' + Char(9)  + '%'
                    Set @delimitedList = LTrim(RTrim(Replace(@delimitedList, Char(9),  @delimiter)))
            End
        End

        Set @startPosition = 1
        Set @continue = 1
        While @continue = 1
        Begin -- <b>
            If @delimiterIsCRorLF = 1
            Begin
                Set @crPos = CharIndex(Char(13), @delimitedList, @startPosition)
                Set @lfPos = CharIndex(Char(10), @delimitedList, @startPosition)

                If @crPos > 0 And @crPos <= @lfPos
                    Set @delimiterPos = @crPos
                Else If @lfPos > 0 And @lfPos <= @crPos
                    Set @delimiterPos = @lfPos
                Else If @crPos > 0
                    Set @delimiterPos = @crPos
                Else If @lfPos > 0
                    Set @delimiterPos = @lfPos
                Else 
                    Set @delimiterPos = 0
            End
            Else
            Begin
                Set @delimiterPos = CharIndex(@delimiter, @delimitedList, @startPosition)
            End

            If @delimiterPos = 0
            Begin
                -- Delimiter not found
                Set @delimiterPos = Len(@delimitedList) + 1
                Set @continue = 0
            End

            If @delimiterPos >= @startPosition
            Begin -- <c>
                If @delimiterPos > @startPosition
                Begin
                    Set @value = LTrim(RTrim(SubString(@delimitedList, @startPosition, @delimiterPos - @startPosition)))

                    If @delimiterIsCRorLF = 1
                    Begin
                        If @value = char(10)
                            Set @value = ''
                        Else If @value = char(13)
                            Set @value = ''
                    End                    
                End
                Else
                Begin
                    Set @value = ''
                End

                If @delimiterIsCRorLF = 0 Or Len(@value) > 0
                Begin
                    If @maxRows > 0 And @entryID >= @maxRows
                    Begin
                        Set @continue = 0

                        If @delimiterPos > 0 And @delimiterPos < Len(@delimitedList)
                        Begin
                            -- Append the remaining text
                            Set @value = @value + LTrim(RTrim(SubString(@delimitedList, @delimiterPos, Len(@delimitedList))))
                        End
                    End

                    INSERT INTO @tmpValues (EntryID, Value)
                    VALUES (@entryID, @value)
                
                    Set @entryID = @entryID + 1
                End
            End -- </c>

            Set @startPosition = @delimiterPos + 1

        End -- </b>
    End -- </a>
    
    RETURN
END

GO
GRANT VIEW DEFINITION ON [dbo].[udfParseDelimitedListOrdered] TO [DDL_Viewer] AS [dbo]
GO
