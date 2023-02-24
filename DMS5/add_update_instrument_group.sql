/****** Object:  StoredProcedure [dbo].[AddUpdateInstrumentGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateInstrumentGroup]
/****************************************************
**
**  Desc:
**    Adds new or edits existing item in T_Instrument_Group
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   08/28/2010 grk - Initial version
**          08/30/2010 mem - Added parameters @usage and @comment
**          09/02/2010 mem - Added parameter @defaultDatasetType
**          10/18/2012 mem - Added parameter @allocationTag
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/12/2017 mem - Added parameter @samplePrepVisible
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/18/2021 mem - Added parameter @requestedRunVisible
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @instrumentGroup varchar(64),
    @usage varchar(64),
    @comment varchar(512),
    @active tinyint,
    @samplePrepVisible tinyint,
    @requestedRunVisible tinyint,
    @allocationTag varchar(24),
    @defaultDatasetTypeName varchar(64),            -- This is allowed to be blank
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @datasetTypeID int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateInstrumentGroup', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @comment = IsNull(@comment, '')
    Set @active = IsNull(@active, 0)
    Set @samplePrepVisible = IsNull(@samplePrepVisible, 0)
    Set @requestedRunVisible= IsNull(@requestedRunVisible, 0)

    Set @message = ''
    Set @defaultDatasetTypeName = IsNull(@defaultDatasetTypeName, '')

    If @defaultDatasetTypeName <> ''
        execute @datasetTypeID = GetDatasetTypeID @defaultDatasetTypeName
    Else
        Set @datasetTypeID = 0

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If @mode = 'update'
    Begin
        -- cannot update a non-existent entry
        --
        declare @tmp varchar(64)
        set @tmp = ''
        --
        SELECT @tmp = IN_Group
        FROM  T_Instrument_Group
        WHERE (IN_Group = @instrumentGroup)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 OR @tmp = ''
            RAISERROR ('No entry could be found in database for update', 11, 16)
    End

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    If @mode = 'add'
    Begin

        INSERT INTO T_Instrument_Group( IN_Group,
                                        [Usage],
                                        [Comment],
                                        Active,
                                        Sample_Prep_Visible,
                                        Requested_Run_Visible,
                                        Allocation_Tag,
                                        Default_Dataset_Type )
        VALUES(@instrumentGroup, @usage, @comment,
               @active, @samplePrepVisible, @requestedRunVisible,
               @allocationTag,
               CASE
                   WHEN @datasetTypeID > 0 THEN @datasetTypeID
                   ELSE NULL
               END)

        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
            RAISERROR ('Insert operation failed', 11, 7)

    End -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        set @myError = 0
        --
        UPDATE T_Instrument_Group
        SET Usage = @usage,
            Comment = @comment,
            Active = @active,
            Sample_Prep_Visible = @samplePrepVisible,
            Requested_Run_Visible = @requestedRunVisible,
            Allocation_Tag = @allocationTag,
            Default_Dataset_Type = CASE WHEN @datasetTypeID > 0 Then @datasetTypeID Else Null End
        WHERE (IN_Group = @instrumentGroup)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
            RAISERROR ('Update operation failed: "%s"', 11, 4, @instrumentGroup)

    End -- update mode

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'AddUpdateInstrumentGroup'
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentGroup] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrumentGroup] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentGroup] TO [Limited_Table_Write] AS [dbo]
GO
