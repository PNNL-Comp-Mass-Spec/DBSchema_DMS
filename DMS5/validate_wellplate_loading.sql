/****** Object:  StoredProcedure [dbo].[validate_wellplate_loading] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_wellplate_loading]
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
**          11/25/2022 mem - Rename parameter to @wellplateName
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/09/2024 mem - Use a well index value of 0 if _wellPosition is an empty string
**
*****************************************************/
(
    @wellplateName varchar(64) output,
    @wellNumber varchar(8) output,
    @totalCount int,                    -- Number of consecutive wells to be filled
    @wellIndex int output,              -- index position of wellNum
    @message varchar(512) output
)
AS
    Set NOCOUNT On

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- normalize wellplate values
    ---------------------------------------------------

    -- normalize values meaning 'empty' to null
    --
    If @wellplateName = '' Or @wellplateName = 'na'
    Begin
        Set @wellplateName = null
    End

    If @wellNumber = '' Or @wellNumber = 'na'
    Begin
        Set @wellNumber = null
    End

    Set @wellNumber = UPPER(@wellNumber)

    -- Make sure that wellplate and well values are consistent
    -- with each other
    --
    If (@wellNumber is null And Not @wellplateName is null) Or (Not @wellNumber is null And @wellplateName is null)
    Begin
        Set @message = 'Wellplate and well must either both be empty or both be set'
        Return 51042
    End

    ---------------------------------------------------
    -- Get wellplate index
    ---------------------------------------------------
    --
    Set @wellIndex = 0

    -- Check for overflow

    If Not @wellNumber Is Null And @wellNumber <> ''
    Begin
        -- Note that function get_well_index() returns 0 if _wellPosition is an empty string or is only a single character

        Set @wellIndex = dbo.get_well_index(@wellNumber)

        If @wellIndex = 0
        Begin
            Set @message = 'Well number is not valid; should be in the format A4 or C12'
            Return 51043
        End

        If @wellIndex + @totalCount > 97 -- index is first new well, which understates available space by one
        Begin
            Set @message = 'Wellplate capacity would be exceeded'
            Return 51044
        End
    End

    ---------------------------------------------------
    -- Make sure wells are not in current use
    ---------------------------------------------------

    -- Don't bother if we are not adding new item
    If @totalCount = 0 Goto Done

    Declare @wells TABLE (
        wellIndex int
    )

    Declare @index int = @wellIndex
    Declare @count smallint = @totalCount

    While @count > 0
    Begin
        insert into @wells (wellIndex) values (@index)
        Set @count = @count - 1
        Set @index = @index + 1
    End

    Declare @hits int = 0
    Declare @wellList VARCHAR(8000) = ''

    SELECT
        @hits = @hits + 1,
        @wellList = CASE WHEN @wellList = '' THEN EX_well_num ELSE ', ' + EX_well_num END
    FROM T_Experiments
    WHERE
        EX_wellplate_num = @wellplateName AND
        dbo.get_well_index(EX_well_num) IN (
            SELECT wellIndex
            FROM @wells
        )

    If @hits > 0
    Begin
        Set @wellList = Substring(@wellList, 0, 256)

        If @hits = 1
            Set @message = 'Well '  + @wellList + ' on wellplate "' + @wellplateName + '" is currently filled'
        Else
            Set @message = 'Wells ' + @wellList + ' on wellplate "' + @wellplateName + '" are currently filled'

        Return 51045
    End

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[validate_wellplate_loading] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[validate_wellplate_loading] TO [Limited_Table_Write] AS [dbo]
GO
