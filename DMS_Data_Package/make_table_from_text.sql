/****** Object:  UserDefinedFunction [dbo].[make_table_from_text] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[make_table_from_text]
/****************************************************
**
**  Desc:
**  Returns a table filled with the contents of a delimited list
**
**  Return values:
**
**  Parameters:
**
**
**      Auth: grk
**      Date: 06/10/2009 grk - initial release
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @list varchar(max)
)
RETURNS @theTable TABLE
   (
    Item varchar(128)
   )
AS
BEGIN
        declare @delimiter char(1)
        set @delimiter = ','

        declare @EOL int
        declare @count int

        declare @myError int
        set @myError = 0

        declare @myRowCount int
        set @myRowCount = 0
        --
        declare @id int
        --
        declare @curPos int
        set @curPos = 1
        declare @field varchar(128)

        --if @list is null set to empty string
        Set @list = isnull(@list, '')

        -- process lists into rows
        -- and insert into DB table
        --
        set @count = 0
        set @EOL = 0
        declare @EndOfField int

        while @EOL = 0
        begin
            set @count = @count + 1

            -- process the  next field from the list
            --
            set @field = ''
            set @EOL = 0

            -- find position of delimiter
            --
            set @EndOfField = charindex(@delimiter, @list, @curPos)

            -- if delimiter not found, field contains rest of string
            -- and end-of-line condition is set
            --
            if @EndOfField = 0
            begin
                set @EndOfField = LEN(@list) + 1
                set @EOL = 1
            end

            -- extract field based on positions
            --
            set @field = ltrim(rtrim(substring(@list, @curPos, @EndOfField - @curPos)))

            -- advance current starting position beyond current field
            -- and set end-of-line condidtion if it is past the end of the line
            --
            set @curPos = @EndOfField + 1
            if @curPos > LEN(@list)
                set @EOL = 1

            if @field <> ''
            begin
                INSERT INTO @theTable
                    (Item)
                VALUES
                    (@field)
            end
        end

        RETURN
    END

GO
GRANT VIEW DEFINITION ON [dbo].[make_table_from_text] TO [DDL_Viewer] AS [dbo]
GO
