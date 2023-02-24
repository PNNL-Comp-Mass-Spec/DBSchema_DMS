/****** Object:  StoredProcedure [dbo].[ValidateWellplateLoading] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateWellplateLoading]
/****************************************************
**
**  Desc:
**      Checks to see if given set of consecutive well
**      loadings for a given wellplate are valid
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   07/24/2009
**          07/24/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/741)
**          11/30/2009 grk - fixed problem with filling last well causing error message
**          12/01/2009 grk - modified to skip checking of existing well occupancy if @totalCount = 0
**          05/16/2022 mem - Show example well numbers
**          11/25/2022 mem - Rename parameter to @wellplate
**
*****************************************************/
(
    @wellplate varchar(64) output,
    @wellNum varchar(8) output,
    @totalCount int,                    -- Number of consecutive wells to be filled
    @wellIndex int output,              -- index position of wellNum
    @message varchar(512) output
)
AS
    SET NOCOUNT On

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- normalize wellplate values
    ---------------------------------------------------

    -- normalize values meaning 'empty' to null
    --
    If @wellplate = '' Or @wellplate = 'na'
    begin
        set @wellplate = null
    End

    If @wellNum = '' Or @wellNum = 'na'
    begin
        set @wellNum = null
    End

    set @wellNum = UPPER(@wellNum)

    -- Make sure that wellplate and well values are consistent
    -- with each other
    --
    If (@wellNum is null And Not @wellplate is null) Or (Not @wellNum is null And @wellplate is null)
    begin
        set @message = 'Wellplate and well must either both be empty or both be set'
        return 51042
    end

    ---------------------------------------------------
    -- Get wellplate index
    ---------------------------------------------------
    --
    set @wellIndex = 0

    -- Check for overflow
    --
    If Not @wellNum is null
    begin
        set @wellIndex = dbo.GetWellIndex(@wellNum)

        If @wellIndex = 0
        begin
            set @message = 'Well number is not valid; should be in the format A4 or C12'
            return 51043
        end

        If @wellIndex + @totalCount > 97 -- index is first new well, which understates available space by one
        begin
            set @message = 'Wellplate capacity would be exceeded'
            return 51044
        end
    end

    ---------------------------------------------------
    -- Make sure wells are not in current use
    ---------------------------------------------------

    -- don't bother if we are not adding new item
    If @totalCount = 0 GOTO Done
    --
    declare @wells TABLE (
        wellIndex int
    )

    Declare @index int
    Declare @count smallint
    set @count = @totalCount
    set @index = @wellIndex

    while @count > 0
    begin
        insert into @wells (wellIndex) values (@index)
        set @count = @count - 1
        set @index = @index + 1
    end
    --
    Declare @hits int
    DECLARE @wellList VARCHAR(8000)
    --
    SET @wellList = ''
    set @hits = 0
    SELECT
        @hits = @hits + 1,
        @wellList = CASE WHEN @wellList = '' THEN EX_well_num ELSE ', ' + EX_well_num END
    FROM T_Experiments
    WHERE
        EX_wellplate_num = @wellplate AND
        dbo.GetWellIndex(EX_well_num) IN (
            select wellIndex
            from @wells
        )

    If @hits > 0
    begin
        SET @wellList = SUBSTRING(@wellList, 0, 256)

        If @hits = 1
            set @message = 'Well ' + @wellList + ' on wellplate "' + @wellplate + '" is currently filled'
        else
            set @message = 'Wells ' + @wellList + ' on wellplate "' + @wellplate + '" are currently filled'

        return 51045
    end

    ---------------------------------------------------
    -- OK
    ---------------------------------------------------
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ValidateWellplateLoading] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateWellplateLoading] TO [Limited_Table_Write] AS [dbo]
GO
