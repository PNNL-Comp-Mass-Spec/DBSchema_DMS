/****** Object:  UserDefinedFunction [dbo].[get_well_number] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_well_number]
/****************************************************
**
**  Desc:
**  Given 96 well plate index postion, return
**  the well number
**
**  Return values: next well number, or null if none found
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/15/2000
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @index int
)
RETURNS varchar(8)
AS
    BEGIN
        declare @wellNumber varchar(8)
        set @wellNumber = ''

        if @index > 0 and @index < 97
        begin
            declare @wpRow smallint
            declare @wpRowCharBase smallint
            set @wpRowCharBase = ASCII('A')
            --
            declare @numCols smallint
            set @numCols = 12
            declare @wpCol smallint

            select @wpRow =
            CASE
                WHEN @index <= 12 THEN 0
                WHEN @index <= 24 THEN 1
                WHEN @index <= 36 THEN 2
                WHEN @index <= 48 THEN 3
                WHEN @index <= 60 THEN 4
                WHEN @index <= 72 THEN 5
                WHEN @index <= 84 THEN 6
                WHEN @index <= 96 THEN 7
                ELSE 0
            END
            set @wpCol = @index - (@wpRow * @numCols)

            declare @row varchar(4)
            declare @col varchar(4)
            set @row = char(@wpRow + @wpRowCharBase)
            set @col = convert(varchar(4), @wpCol)
            if @col < 10
                set @col = '0' + @col

            set @wellNumber = @row + @col
        end

        RETURN @wellNumber
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_well_number] TO [DDL_Viewer] AS [dbo]
GO
