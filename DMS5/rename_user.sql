/****** Object:  StoredProcedure [dbo].[rename_user] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[rename_user]
/****************************************************
**
**  Desc:   Renames a user in T_Users and other tracking tables
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   10/31/2014 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/19/2024 mem - Update the Updated_By column in T_LC_Cart_Configuration
**
*****************************************************/
(
    @oldUserName varchar(50) = '',
    @newUserName varchar(32) = '',
    @message varchar(512) = '' output,
    @infoOnly tinyint = 1
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'rename_user', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------
    --
    Set @OldUserName = ISNULL(@OldUserName, '')
    Set @NewUserName = ISNULL(@NewUserName, '')

    If @OldUserName = ''
    Begin
        Set @message = '@OldUserName is empty; unable to continue'
        Goto Done
    End

    If @NewUserName = ''
    Begin
        Set @message = '@NewUserName is empty; unable to continue'
        Goto Done
    End

    If @OldUserName = @NewUserName
    Begin
        Set @message = 'Usernames are identical; nothing to do'
        Goto Done
    End

    --------------------------------------------
    -- Examine T_Users
    --------------------------------------------
    --
    If Not Exists (Select * From T_Users Where U_PRN = @OldUserName)
    Begin
        Set @message = 'User ' + @OldUserName + ' does not exist in T_Users; nothing to do'
        Goto Done
    End

    If Exists (Select * From T_Users Where U_PRN = @NewUserName)
    Begin
        Set @message = 'Cannot rename ' + @OldUserName + ' to ' + @NewUserName + ' because the new username already exists in T_Users'

        If Substring(@OldUserName, 1, Len(@NewUserName)) = @NewUserName
        Begin
            Set @message = @message + '. Will check for required renames in other tables'
            Select @message as TheMessage
        End
        Else
        Begin
            Set @message = @message + '. The new username is too different than the old username; aborting'

            Select @message as TheMessage

            Goto Done
        End
    End
    Else
    Begin

        If @InfoOnly <> 0
        Begin
            SELECT 'Preview of rename from ' + @OldUserName + ' to ' + @NewUserName as TheMessage

            SELECT *
            FROM T_Users
            WHERE U_PRN IN (@OldUserName, @NewUserName)
        End
        Else
        Begin
            SELECT 'Renaming ' + @OldUserName + ' to ' + @NewUserName as TheMessage

            Update T_Users
            Set U_PRN = @NewUserName
            WHERE U_PRN = @OldUserName
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End
    End

        If @InfoOnly <> 0
        Begin
            SELECT *
            FROM T_Dataset
            WHERE DS_Oper_PRN IN (@OldUserName, @NewUserName)

            SELECT *
            FROM T_Experiments
            WHERE EX_researcher_PRN IN (@OldUserName, @NewUserName)

            SELECT *
            FROM T_Requested_Run
            WHERE RDS_Requestor_PRN IN (@OldUserName, @NewUserName)

            SELECT *
            FROM DMS_Data_Package.dbo.T_Data_Package
            WHERE Owner IN (@OldUserName, @NewUserName)

            SELECT *
            FROM DMS_Data_Package.dbo.T_Data_Package
            WHERE Requester IN (@OldUserName, @NewUserName)

        End
        Else
        Begin

            UPDATE T_Dataset
            SET DS_Oper_PRN = @NewUserName
            WHERE DS_Oper_PRN = @OldUserName

            UPDATE T_Experiments
            SET EX_researcher_PRN = @NewUserName
            WHERE EX_researcher_PRN = @OldUserName

            UPDATE T_Requested_Run
            SET RDS_Requestor_PRN = @NewUserName
            WHERE RDS_Requestor_PRN = @OldUserName

            -- Note that the Entered_By column in T_LC_Cart_Configuration will be auto-updated via a foreign key constraint that has ON UPDATE CASCADE

            -- In contrast, the Updated_By column does not have a foreign key constraint, 
            -- since SQL Server does support multiple foreign key constraints to a given table when one of the constraints has ON UPDATE CASCADE

            UPDATE T_LC_Cart_Configuration
            SET Updated_By = @NewUserName
            WHERE Updated_By = @OldUserName

            UPDATE DMS_Data_Package.dbo.T_Data_Package
            SET Owner = @NewUserName
            WHERE Owner = @OldUserName

            UPDATE DMS_Data_Package.dbo.T_Data_Package
            SET Requester = @NewUserName
            WHERE Requester = @OldUserName

        End

     ---------------------------------------------------
    -- Done
     ---------------------------------------------------
Done:

    If @message <> ''
        print @message

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[rename_user] TO [DDL_Viewer] AS [dbo]
GO
