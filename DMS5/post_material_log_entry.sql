/****** Object:  StoredProcedure [dbo].[post_material_log_entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[post_material_log_entry]
/****************************************************
**
**  Desc: Adds new entry to T_Material_Log
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/20/2008
**          03/25/2008 mem - Now validating that @callingUser is not blank
**          03/26/2008 grk - added handling for comment
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @type varchar(32),
    @item varchar(128),
    @initialState varchar(128),
    @finalState varchar(128),
    @callingUser varchar(128) = '',
    @comment varchar(512)
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    declare @message varchar(512)
    set @message = ''

    ---------------------------------------------------
    -- Make sure @callingUser is not blank
    ---------------------------------------------------

    Set @callingUser = IsNull(@callingUser, '')
    If Len(@callingUser) = ''
        Set @callingUser = suser_sname()

    ---------------------------------------------------
    -- weed out useless postings
    -- (example: movement where origin same as destination)
    ---------------------------------------------------

    if @InitialState = @FinalState
    begin
        return 0
    end

    ---------------------------------------------------
    -- action
    ---------------------------------------------------

    INSERT INTO T_Material_Log (
        Type,
        Item,
        Initial_State,
        Final_State,
        User_PRN,
        Comment
    ) VALUES (
        @Type,
        @Item,
        @InitialState,
        @FinalState,
        @callingUser,
        @comment
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Insert operation failed'
        RAISERROR (@message, 10, 1)
        return 51007
    end

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[post_material_log_entry] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[post_material_log_entry] TO [Limited_Table_Write] AS [dbo]
GO
