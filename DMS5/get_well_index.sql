/****** Object:  UserDefinedFunction [dbo].[GetWellIndex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetWellIndex]
/****************************************************
**
**  Desc:
**  Given 96 well plate well number, return
**  the index position of the well
**
**  Return values: next well number, or null if none found
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/15/2000
**
*****************************************************/
(
    @wellNum varchar(8)
)
RETURNS int
AS
    BEGIN
        declare @index int
        set @index = 0

        declare @wpRow smallint
        declare @wpRowCharBase smallint
        set @wpRowCharBase = ASCII('A')
        --
        declare @wpCol smallint
        declare @numCols smallint
        set @numCols = 12

        -- get row and col for current well
        set @wpRow = ASCII(@wellNum) - @wpRowCharBase
        set @wpCol = convert(smallint, substring(@wellNum, 2, 20))

        if @wpRow <= 8 and @wpRow >= 0 and @wpCol <= 12 and @wpCol >= 0
        begin
            set @index = (@wpRow * @numCols) + @wpCol
        end

        RETURN @index
    END

GO
GRANT VIEW DEFINITION ON [dbo].[GetWellIndex] TO [DDL_Viewer] AS [dbo]
GO
