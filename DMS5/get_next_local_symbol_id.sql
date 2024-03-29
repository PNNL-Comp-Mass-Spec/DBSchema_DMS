/****** Object:  UserDefinedFunction [dbo].[get_next_local_symbol_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_next_local_symbol_id]
/****************************************************
**
**  Desc: Gets Next Available LocalSymbolID for a given paramFileID
**
**  Return values: 0: failure, otherwise, LocalSymbolID
**
**  Auth:   kja
**  Date:   08/10/2004
**          10/01/2009 mem - Updated to jump from ID 3 to ID 9 for Sequest param files
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramFileID int
)
RETURNS int
AS
BEGIN
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @LocalSymbolID int
    Declare @NextSymbolID int = 0
    Declare @ParamFileTypeID int = 0

    -- Determine the param file type for this param file ID
    SELECT @ParamFileTypeID = Param_File_Type_ID
    FROM T_Param_Files
    WHERE (Param_File_ID = @ParamFileID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -- Determine the highest used Local_Symbol_ID for the mods for this parameter file
    SELECT @LocalSymbolID = MAX(Local_Symbol_ID)
    FROM T_Param_File_Mass_Mods
    WHERE (Param_File_ID = @ParamFileID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    if @myRowCount = 0 Or @LocalSymbolID is null
        set @LocalSymbolID = 0


    If @ParamFileTypeID = 1000
    Begin
        -- This is a Sequest parameter file
        -- The order of symbols needs to be
        --   * # @ ^ ~

        -- To do this, we need to handle cases when @LocalSymbolID is 3, 10, or 11
        -- Jump from symbol 3 to symbol 10
        --  and from symbol 10 to symbol 11
        --  and from symbol 11 to symbol 4

        If @LocalSymbolID = 3
            Set @NextSymbolID = 10      -- Max symbol is @, next needs to be ^

        If @LocalSymbolID = 10
            Set @NextSymbolID = 11      -- Max symbol is ^, next needs to be ~

        If @LocalSymbolID = 11
        Begin
            -- Max symbol is ~, we now need to loop back and start using 4, 5, 6, and 7
            SELECT @LocalSymbolID = MAX(Local_Symbol_ID)
            FROM T_Param_File_Mass_Mods
            WHERE (Param_File_ID = @ParamFileID) AND Local_Symbol_ID < 10
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            if @myRowCount = 0
                set @LocalSymbolID = 0

            Set @NextSymbolID = @LocalSymbolID + 1
        End

        -- See if @NextSymbolID is still 0
        -- If it is still 0, then none of the special cases was encountered above,
        --  so just assign @NextSymbolID to be one more than @LocalSymbolID
        If @NextSymbolID = 0
            Set @NextSymbolID = @LocalSymbolID + 1

    End
    Else
    Begin
        -- Assign @NextSymbolID to be one more than @LocalSymbolID
        Set @NextSymbolID = @LocalSymbolID + 1
    End

    return @NextSymbolID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_next_local_symbol_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_next_local_symbol_id] TO [Limited_Table_Write] AS [dbo]
GO
