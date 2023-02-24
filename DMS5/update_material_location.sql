/****** Object:  StoredProcedure [dbo].[update_material_location] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_material_location]
/****************************************************
**
**  Desc:   Change properties of a single material location item
**          Only allows updating the comment or the active/inactive state
**
**          Additionally, prevents updating entries where the container limit is 100 or more
**          since those are special locations (typically for staging samples)
**
**  Auth:   mem
**  Date:   08/27/2018 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @locationTag varchar(64),
    @comment varchar(512),
    @status varchar(32),
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    Declare @errorMessage varchar(512)

    Declare @logErrors tinyint = 0
    Declare @logMessage varchar(512)

    Declare @locationId int
    Declare @containerLimit int

    Declare @oldStatus varchar(32)
    Declare @oldComment varchar(512)

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_material_location', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------

        Set @locationTag = Ltrim(Rtrim(IsNull(@locationTag, '')))
        Set @comment = Ltrim(Rtrim(IsNull(@comment, '')))
        Set @status = Ltrim(Rtrim(IsNull(@status, '')))

        If IsNull(@callingUser, '') = ''
            SET @callingUser = dbo.get_user_login_without_domain('')

        If LEN(@locationTag) < 1
            RAISERROR ('Location tag must be defined', 11, 30)

        If Not @status In ('Active', 'Inactive')
            RAISERROR ('Status must be Active or Inactive', 11, 30)

        -- Make sure @status is properly capitalized
        If @status = 'Active'
            Set @status = 'Active'

        If @status = 'Inactive'
            Set @status = 'Inactive'

        -----------------------------------------------------------
        -- Validate @locationTag and retrieve the current status
        -----------------------------------------------------------

        SELECT @locationId = ID,
               @oldComment = IsNull(Comment, ''),
               @containerLimit = Container_Limit,
               @oldStatus = [Status]
        FROM   T_Material_Locations
        WHERE Tag = @locationTag
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        if @myError <> 0
            RAISERROR ('Error resolving material location tag to ID', 11, 91)

        If @myRowCount < 1
            RAISERROR ('Material location tag not found; contact a DMS admin to add new locations', 11, 91)

        ---------------------------------------------------
        -- Do not allow updates to shared material locations
        ---------------------------------------------------

        If @containerLimit >= 100
        Begin
            Set @errorMessage = 'Cannot update the comment or active status of shared material location ' + @locationTag + '; contact a DMS admin for assistance'
            RAISERROR (@errorMessage, 11, 91)
        End

        ---------------------------------------------------
        -- Do not allow a location to be made Inactive if it has active containers
        ---------------------------------------------------

        If @oldStatus = 'Active' And @status ='Inactive'
        Begin
            Declare @activeContainers int = 0

            SELECT @activeContainers = Count(*)
            FROM   T_Material_Locations AS ML INNER JOIN
                         T_Material_Containers AS MC ON ML.ID = MC.Location_ID
            WHERE ML.ID = @locationId AND MC.Status = 'Active'
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @activeContainers > 0
            Begin
                Set @errorMessage = 'Location cannot be set to inactive because it has ' +
                                    Cast(@activeContainers As varchar(12)) + ' active ' +
                                    dbo.check_plural(@activeContainers, 'container', 'containers')
                RAISERROR (@errorMessage, 11, 91)
            End
        End


        ---------------------------------------------------
        -- Update the data
        ---------------------------------------------------

        -- Enable error logging if an exception is caught
        Set @logErrors = 1

        If @status <> @oldStatus
        Begin
            -- Update the status

            Update T_Material_Locations
            Set Status = @status
            Where ID = @locationId
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0
            Begin
                Set @errorMessage = 'Error changing status to ' + @status + ' for material location ' + @locationTag
                RAISERROR (@errorMessage, 11, 91)
            End

            Set @logMessage = 'Material location status changed from ' + @oldStatus + ' to ' + @status +
                              ' by ' + @callingUser + ' for material location ' + @locationTag

            Exec post_log_entry 'Normal', @logMessage, 'update_material_location'

            Set @message = 'Set status to ' + @status
        End

        If @oldComment <> @comment
        Begin
            -- Update the comment

            Update T_Material_Locations
            Set Comment = @comment
            Where ID = @locationId
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0
            Begin
                Set @errorMessage = 'Error updating the comment for material location ' + @locationTag
                RAISERROR (@errorMessage, 11, 91)
            End

            If @oldComment <> ''
            Begin
                If @comment = ''
                Begin
                    Set @logMessage = 'Material location comment "' + @oldComment + '" removed by ' +
                                      @callingUser + ' for material location ' + @locationTag

                End
                Else
                Begin
                    Set @logMessage = 'Material location comment changed from "' +
                                      @oldComment + '" to "' + @comment + '" by ' +
                                      @callingUser + ' for material location ' + @locationTag
                End

                Exec post_log_entry 'Normal', @logMessage, 'update_material_location'
            End

        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message OUTPUT, @myError OUTPUT

        If @logErrors > 0
        Begin
            Set @logMessage = @message + '; Location tag ' + @locationTag
            exec post_log_entry 'Error', @logMessage, 'update_material_location'
        End

    END CATCH
    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_material_location] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_material_location] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_material_location] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_material_location] TO [Limited_Table_Write] AS [dbo]
GO
