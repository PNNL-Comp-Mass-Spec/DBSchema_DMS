/****** Object:  StoredProcedure [dbo].[add_update_separation_type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_separation_type]
/****************************************************
**
**  Desc: Adds new or edits existing T_Secondary_Sep entry
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   bcg
**  Date:   12/19/2019 bcg - Initial release
**          08/11/2021 mem - Determine the next ID to use when adding a new separation type
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @id int,
    @sepTypeName varchar(50),
    @sepGroupName varchar(64),
    @comment varchar(256),
    @sampleType varchar(32),
    @state varchar(12) = 'Active',                    -- Active or Inactive
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    Declare @debugMsg varchar(512) = ''
    Declare @nextID Int

    Set @message = ''

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @ID = IsNull(@ID, 0)
    Set @sepTypeName = IsNull(@sepTypeName, '')
    Set @state = IsNull(@state, 'Active')
    Set @mode = IsNull(@mode, 'add')

    If @state = ''
        Set @state = 'Active'

    ---------------------------------------------------
    -- Validate @state
    ---------------------------------------------------
    --
    If Not @state IN ('Active', 'Inactive')
    Begin
        Set @message = 'Separation type state must be Active or Inactive; ' + @state + ' is not allowed'
        RAISERROR (@message, 10, 1)
        Return 51005
    End

    ---------------------------------------------------
    -- Convert text state to integer
    ---------------------------------------------------
    Declare @stateInt integer = 0
    If @state = 'Active'
        Set @stateInt = 1
    Else
        Set @stateInt = 0

    ---------------------------------------------------
    -- Validate the cart configuration name
    -- First assure that it does not have invalid characters and is long enough
    ---------------------------------------------------

    Declare @badCh varchar(128) = dbo.validate_chars(@sepTypeName, '')
    If @badCh <> ''
    Begin
        If @badCh = '[space]'
            Set @message  ='Separation Type name may not contain spaces'
        Else
            Set @message = 'Separation Type name may not contain the character(s) "' + @badCh + '"'

        RAISERROR (@message, 10, 1)
        Return 51005
    End

    If Len(@sepTypeName) < 6
    Begin
        Set @message = 'Separation Type name must be at least 6 characters in length; currently ' + Cast(Len(@sepTypeName) as varchar(9)) + ' characters'
        RAISERROR (@message, 10, 1)
        Return 51005
    End

    ---------------------------------------------------
    -- Validate the sample type and get the ID
    ---------------------------------------------------
    Declare @sampleTypeID integer = 0
    Begin
        SELECT @sampleTypeID = SampleType_ID
        FROM T_Secondary_Sep_SampleType
        WHERE Name = @sampleType

        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'No matching sample type could be found in the database'
            RAISERROR (@message, 10, 1)
            Return 51007
        End
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------
    --

    If @mode = 'update'
    Begin
        -- Lookup the current name and state
        Declare @existingName varchar(128) = ''
        Declare @oldState integer = 0
        Declare @ignoreDatasetChecks tinyint = 0

        SELECT @existingName = SS_Name,
               @oldState = SS_active
        FROM T_Secondary_Sep
        WHERE SS_ID = @ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'No entry could be found in database for update'
            RAISERROR (@message, 10, 1)
            Return 51008
        End

        If @sepTypeName <> @existingName
        Begin
            Declare @conflictID int = 0

            SELECT @conflictID = SS_ID
            FROM T_Secondary_Sep
            WHERE SS_name = @sepTypeName
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @conflictID > 0
            Begin
                Set @message = 'Cannot rename separation type from ' + @existingName + ' to ' + @sepTypeName + ' because the new name is already in use by ID ' + Cast(@conflictID as varchar(9))
                RAISERROR (@message, 10, 1)
                Return 51009
            End
        End

        ---------------------------------------------------
        -- Only allow updating the state of Separation Type items that are associated with a dataset
        ---------------------------------------------------
        --
        If @ignoreDatasetChecks = 0 And Exists (Select * FROM T_Dataset Where DS_sec_sep = @sepTypeName)
        Begin
            Declare @datasetCount int = 0
            Declare @maxDatasetID int = 0

            SELECT @datasetCount = Count(*),
                   @maxDatasetID = Max(Dataset_ID)
            FROM T_Dataset
            WHERE DS_sec_sep = @ID

            Declare @datasetDescription varchar(196)
            Declare @datasetName varchar(128)

            SELECT @datasetName = Dataset_Num
            FROM T_Dataset
            WHERE Dataset_ID = @maxDatasetID

            If @datasetCount = 1
                Set @datasetDescription = 'dataset ' + @datasetName
            Else
                Set @datasetDescription = Cast(@datasetCount as varchar(9)) + ' datasets'

            If @stateInt <> @oldState
            Begin
                UPDATE T_Secondary_Sep
                SET SS_active = @stateInt
                WHERE SS_ID = @ID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                Set @message = 'Updated state to ' + @state + '; any other changes were ignored because this separation type is associated with ' + @datasetDescription

                Return 0
            End

            Set @message = 'Separation Type ID ' + Cast(@ID as varchar(9)) + ' is associated with ' + @datasetDescription +
                           ', most recently ' + @datasetName + '; contact a DMS admin to update the configuration'

            RAISERROR (@message, 10, 1)
            Return 51010
        End

    End

    ---------------------------------------------------
    -- Validate that the LC Cart Config name is unique when creating a new entry
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin
        If Exists (Select * FROM T_Secondary_Sep Where SS_name = @sepTypeName)
        Begin
            Set @message = 'Separation Type already exists; cannot add a new separation type named ' + @sepTypeName
            RAISERROR (@message, 10, 1)
            Return 51011
        End
    End

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin
        Begin Tran

        SELECT @nextID = MAX(SS_ID) + 1
        FROM T_Secondary_Sep

        INSERT INTO T_Secondary_Sep( SS_name,
                                     SS_ID,
                                     Sep_Group,
                                     SS_comment,
                                     SampleType_ID,
                                     SS_active,
                                     Created )
        VALUES (
            @sepTypeName,
            @nextID,
            @sepGroupName,
            @comment,
            @sampleTypeID,
            @stateInt,
            GetDate()
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Insert operation failed'
            RAISERROR (@message, 10, 1)
            Return 51012
        End

        -- Return ID of newly created entry
        --
        Set @ID = @nextID

        Commit

    End -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        Set @myError = 0
        --
        UPDATE T_Secondary_Sep
        SET SS_name = @sepTypeName,
            Sep_Group = @sepGroupName,
            SS_comment = @comment,
            SampleType_ID = @sampleTypeID,
            SS_active = @stateInt
        WHERE SS_ID = @ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Update operation failed: "' + Cast(@ID as varchar(12)) + '"'
            RAISERROR (@message, 10, 1)
            Return 51013
        End

    End -- update mode

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_separation_type] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_separation_type] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_separation_type] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_separation_type] TO [Limited_Table_Write] AS [dbo]
GO
