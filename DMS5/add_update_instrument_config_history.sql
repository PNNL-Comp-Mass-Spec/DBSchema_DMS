/****** Object:  StoredProcedure [dbo].[AddUpdateInstrumentConfigHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateInstrumentConfigHistory]
/****************************************************
**
**  Desc: Adds new or edits existing T_Instrument_Config_History
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/30/2008
**          03/19/2012 grk - added "PostedBy"
**          06/13/2017 mem - Use SCOPE_IDENTITY
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/30/2018 mem - Make @id an output parameter
**                           Validate @dateOfChange
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @id int output,             -- Input/output parameter
    @instrument varchar(24),
    @dateOfChange varchar(24),
    @postedBy VARCHAR(64),
    @description varchar(128),
    @note text,
    @mode varchar(12) = 'add',      -- 'add' or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateInstrumentConfigHistory', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    IF @postedBy IS NULL OR @postedBy = ''
    BEGIN
        Set @postedBy = @callingUser
    END

    Declare @validatedDate datetime = Try_Cast(@dateOfChange As datetime)
    If @validatedDate Is Null
    Begin
        Set @message = 'Date Of Change is not a valid date'
        RAISERROR (@message, 10, 1)
        return 51006
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    if @mode = 'update'
    begin
        -- Cannot update a non-existent entry
        --
        Declare @tmp int = 0
        --
        SELECT @tmp = ID
            FROM  T_Instrument_Config_History
        WHERE (ID = @id)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 OR @tmp = 0
        begin
            set @message = 'No entry could be found in database for update'
            RAISERROR (@message, 10, 1)
            return 51007
        end

    end


    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @Mode = 'add'
    begin

        INSERT INTO T_Instrument_Config_History (
            Instrument,
            Date_Of_Change,
            Description,
            Note,
            Entered,
            EnteredBy
        ) VALUES (
            @instrument,
            @validatedDate,
            @description,
            @note,
            getdate(),
            @postedBy
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

        -- Return ID of newly created entry
        --
        set @id = SCOPE_IDENTITY()

    end -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if @Mode = 'update'
    begin
        UPDATE T_Instrument_Config_History
        SET Instrument = @instrument,
            Date_Of_Change = @validatedDate,
            Description = @description,
            Note = @note,
            EnteredBy = @postedBy
        WHERE (ID = @id)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Update operation failed: "' + @id + '"'
            RAISERROR (@message, 10, 1)
            return 51004
        end
    end -- update mode

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentConfigHistory] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrumentConfigHistory] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentConfigHistory] TO [Limited_Table_Write] AS [dbo]
GO
