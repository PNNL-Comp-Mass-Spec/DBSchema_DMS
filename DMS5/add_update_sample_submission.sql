/****** Object:  StoredProcedure [dbo].[add_update_sample_submission] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_sample_submission]
/****************************************************
**
**  Desc:
**      Adds new or edits existing item in T_Sample_Submission
**
**  Auth:   grk
**  Date:   04/23/2010
**          04/30/2010 grk - Added call to CallSendMessage
**          09/23/2011 grk - Accomodate researcher field in assure_material_containers_exist
**          02/06/2013 mem - Added logic to prevent duplicate entries
**          12/08/2014 mem - Now using Name_with_PRN to obtain the user's name and username
**          03/26/2015 mem - Update duplicate sample submission message
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/18/2017 mem - Disable logging certain messages to T_Log_Entries
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**          11/19/2023 mem - Send campaign name to assure_material_containers_exist
**          11/21/2023 mem - If @containerList is 'na', assure that it is lowercase
**
*****************************************************/
(
    @id int output,
    @campaign varchar(64),
    @receivedBy varchar(64),
    @containerList varchar(1024) output,
    @newContainerComment varchar(1024),
    @description varchar(4096),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(512) = ''
    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_sample_submission', @raiseError = 1

    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin Try

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        Set @Campaign = IsNull(@Campaign, '')
        If @Campaign = ''
            RAISERROR('Campaign name cannot be empty', 11, 15)

        Set @ContainerList = IsNull(@ContainerList, '')
        If @ContainerList = ''
            RAISERROR('Container list cannot be empty', 11, 16)

        Set @ReceivedBy = IsNull(@ReceivedBy, '')
        If @ReceivedBy = ''
            RAISERROR('Received by name cannot be empty', 11, 17)

        Set @NewContainerComment = IsNull(@NewContainerComment, '')

        Set @Description = IsNull(@Description, '')
        If @Description = ''
            RAISERROR('Description must be specified', 11, 18)

        ---------------------------------------------------
        -- Resolve Campaign ID
        ---------------------------------------------------

        Declare @CampaignID int = 0

        SELECT @CampaignID = Campaign_ID
        FROM T_Campaign
        WHERE Campaign_Num = @Campaign

        If @CampaignID = 0
            RAISERROR('Campaign "%s" could not be found', 11, 19, @Campaign)

        ---------------------------------------------------
        -- Resolve username
        ---------------------------------------------------

        Declare @Researcher varchar(128)
        Declare @ReceivedByUserID int
        Set @ReceivedByUserID = 0

        SELECT
            @ReceivedByUserID = ID,
            @Researcher = Name_with_PRN
        FROM T_Users
        WHERE U_PRN = @ReceivedBy

        If @CampaignID = 0
            RAISERROR('Username "%s" could not be found', 11, 20, @ReceivedBy)

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If @mode = 'update'
        Begin
            -- Cannot update a non-existent entry
            --
            Declare @tmp int = 0

            SELECT @tmp = ID
            FROM  T_Sample_Submission
            WHERE ID = @ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0 OR @tmp = 0
                RAISERROR ('No entry could be found in database for update', 11, 21)
        End

        ---------------------------------------------------
        -- Define the transaction name
        ---------------------------------------------------

        Declare @transName varchar(32) = 'add_update_sample_submission'

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If @Mode = 'add'
        Begin

            ---------------------------------------------------
            -- Verify container list
            ---------------------------------------------------

            Declare @cl varchar(1024) = @ContainerList

            Exec @myError = assure_material_containers_exist
                                @containerList = @cl OUTPUT,
                                @comment = '',
                                @type = '',
                                @campaignName = @campaign,
                                @researcher = @researcher,
                                @mode = 'verify_only',
                                @message = @msg output,
                                @callingUser = ''

            If @myError <> 0
                RAISERROR('assure_material_containers_exist: %s', 11, 22, @msg)

            ---------------------------------------------------
            -- Verify that this doesn't duplicate an existing sample submission request
            ---------------------------------------------------

            Set @ID = -1

            SELECT @ID = ID
            FROM T_Sample_Submission
            WHERE Campaign_ID = @CampaignID AND
                  Received_By_User_ID = @ReceivedByUserID AND
                  Description = @Description

            If @ID > 0
                RAISERROR('New sample submission is duplicate of existing sample submission, ID %d; both have identical Campaign, Received By User, and Description', 11, 23, @ID)

            Set @logErrors = 1

            ---------------------------------------------------
            -- Add the new data
            ---------------------------------------------------

            Begin transaction @transName

            INSERT INTO T_Sample_Submission (
                Campaign_ID,
                Received_By_User_ID,
                Container_List,
                Description,
                Storage_Path
            ) VALUES (
                @CampaignID,
                @ReceivedByUserID,
                @ContainerList,
                @Description,
                NULL
            )
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0
                RAISERROR ('Insert operation failed', 11, 24)

            -- Return ID of newly created entry

            Set @ID = SCOPE_IDENTITY()

            ---------------------------------------------------
            -- Add containers (as needed)
            ---------------------------------------------------

            Declare @Comment varchar(1024)

            If @NewContainerComment = ''
                Set @Comment = '(created via sample submission ' + CONVERT(varchar(12), @ID) + ')'
            Else
                Set @Comment = @NewContainerComment + ' (sample submission ' + CONVERT(varchar(12), @ID) + ')'

            Exec @myError = assure_material_containers_exist
                                @containerList = @containerList OUTPUT,
                                @comment = @comment,
                                @type = 'Box',
                                @campaignName = @campaign,
                                @researcher = @researcher,
                                @mode = 'create',
                                @message = @msg output,
                                @callingUser = @callingUser

            If @myError <> 0
                RAISERROR('assure_material_containers_exist: %s', 11, 25, @msg)

            -- Update container list for sample submission

            UPDATE T_Sample_Submission
            SET Container_List = @ContainerList
            WHERE ID = @ID

            commit transaction @transName

        End

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If @Mode = 'update'
        Begin
            Set @logErrors = 1

            Set @myError = 0

            UPDATE T_Sample_Submission
            SET Campaign_ID = @CampaignID,
                Received_By_User_ID = @ReceivedByUserID,
                Container_List = @ContainerList,
                Description = @Description
            WHERE ID = @ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0
                RAISERROR ('Update operation failed: "%d"', 11, 26, @ID)

        End

    End Try
    Begin Catch
        Exec format_error_message @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec post_log_entry 'Error', @message, 'add_update_sample_submission'
        End
    End Catch

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_sample_submission] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_sample_submission] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_sample_submission] TO [Limited_Table_Write] AS [dbo]
GO
