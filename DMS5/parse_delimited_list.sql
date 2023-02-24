/****** Object:  UserDefinedFunction [dbo].[parse_delimited_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[parse_delimited_list]
/****************************************************
**
**  Parses the text in @delimitedList and
**  returns a table containing the values
**
**  @delimitedList should be of the form 'Value1,Value2'
**
**  Will not return empty string values, e.g. if the list is 'Value1,,Value2' or ',Value1,Value2'
**     then the table will only contain entries 'Value1' and 'Value2'
**
**  If @delimiter is Char(13) or Char(10), will split @delimitedList on CR or LF
**  In this case, blank lines will not be included in table @tmpValues
**
**  Auth:   mem
**  Date:   06/06/2006
**          11/10/2006 mem - Updated to prevent blank values from being returned in the table
**          03/14/2007 mem - Changed @delimitedList parameter from varchar(8000) to varchar(max)
**          04/02/2012 mem - Now removing Tab characters
**          03/27/2013 mem - Now replacing Tab characters, carriage returns and line feeds with @delimiter
**          01/20/2016 mem - Add numbers table example
**          03/17/2017 mem - Add parameter @callingProcedure
**                         - Add optional call to PostUsageLogEntry
**          11/19/2018 mem - Add special handling if @delimeter is CR, LF, or CRLF
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
****************************************************/
(
    @delimitedList varchar(max),
    @delimiter varchar(2) = ',',
    @callingProcedure varchar(128)= ''
)
RETURNS @tmpValues TABLE(Value varchar(2048))
AS
BEGIN

    Declare @continue tinyint
    Declare @startPosition int

    Declare @delimiterPos int
    Declare @crPos int
    Declare @lfPos int

    Declare @delimiterIsCRorLF tinyint = 0

    Declare @value varchar(2048)

    -- Declare @procedureNameForUsageLog varchar(255) = 'parse_delimited_list_' + @callingProcedure

    -- Uncomment the following to log usage of this procedure to a file in C:\temp\
    -- Requirements for this to work:
    --  - Enable xp_cmdshell
    --  - Enable the Server Proxy Account
    --  - Grant execute on master..xp_cmdshell to DMSWebUser and any other user that will call this udf

    --DECLARE @SQL varchar(500)
    --SELECT @SQL = '"C:\Program Files (x86)\Windows Resource Kits\Tools\Now.exe" ' + @procedureNameForUsageLog + ' >> C:\temp\UsageLogStats.txt'
    --EXEC master..xp_cmdshell @SQL


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
                Set @delimitedList = LTrim(RTrim(Replace(@delimitedList, Char(13), @delimiter)))
            End

            If @delimitedList Like '%' + Char(10) + '%'
            Begin
                Set @delimitedList = LTrim(RTrim(Replace(@delimitedList, Char(10), @delimiter)))
            End

            If @delimiter <> Char(9)
            Begin
                -- Replace any tab characters with @delimiter
                If @delimitedList Like '%' + Char(9)  + '%'
                    Set @delimitedList = LTrim(RTrim(Replace(@delimitedList, Char(9), @delimiter)))
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

            If @delimiterPos > @startPosition
            Begin -- <c>
                Set @value = LTrim(RTrim(SubString(@delimitedList, @startPosition, @delimiterPos - @startPosition)))

                If @delimiterIsCRorLF = 1
                Begin
                    If @value = char(10)
                        Set @value = ''
                    Else If @value = char(13)
                        Set @value = ''
                End

                If Len(@value) > 0
                Begin
                    INSERT INTO @tmpValues (Value)
                    VALUES (@value)
                End

            End -- </c>

            Set @startPosition = @delimiterPos + 1
        End -- </b>

        /*
         * The following is an alternative method, using a Numbers table
         * This method is faster than the above Loop-based method, but it
         * does require that the Numbers table be pre-generated
         * prior to using the query
         *
         *
         * Numbers table creation:
            -- DECLARE @UpperLimit INT = 1000000;
            --
            -- WITH n(rn) AS (
            --   SELECT ROW_NUMBER() OVER (ORDER BY s1.[object_id])
            --   FROM sys.all_columns AS s1
            --   CROSS JOIN sys.all_columns AS s2
            -- )
            -- SELECT [Number] = rn
            -- INTO dbo.T_Numbers
            -- FROM n
            -- WHERE rn <= @UpperLimit;
            --
            -- CREATE UNIQUE CLUSTERED INDEX IX_Numbers_Number ON dbo.T_Numbers([Number])
            -- -- WITH (DATA_COMPRESSION = PAGE);
         *
         *
            SELECT rn,
               vn = ROW_NUMBER() OVER ( PARTITION BY [Value] ORDER BY rn ),
               [Value]
            FROM ( SELECT rn = ROW_NUMBER() OVER ( ORDER BY CHARINDEX(@Delim, @List + @Delim) ),
                      [Value] = LTRIM(RTRIM(SUBSTRING(@List, [Number],
                                              CHARINDEX(@Delim, @List + @Delim, [Number]) - [Number])))
               FROM dbo.T_Numbers
               WHERE [Number] <= LEN(@List) AND
                     SUBSTRING(@Delim + @List, [Number], LEN(@Delim)) = @Delim ) AS x
         *
         *
         */

    End -- </a>

    RETURN
END

GO
GRANT VIEW DEFINITION ON [dbo].[parse_delimited_list] TO [DDL_Viewer] AS [dbo]
GO
