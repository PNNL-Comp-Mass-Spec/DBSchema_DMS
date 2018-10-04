/****** Object:  StoredProcedure [dbo].[AddUpdateBionetHost] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateBionetHost]
/****************************************************
**
**  Desc:   Adds new or edits existing item in T_Bionet_Hosts 
**
**  Return values: 0: success, otherwise, error code
**
**  Date:   09/08/2016 mem - Initial version
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/03/2018 mem - Add @comment
**                         - Use @logErrors to toggle logging errors caught by the try/catch block
**    
*****************************************************/
(
    @host varchar(64),
    @ip varchar(15),
    @alias varchar(64),
    @tag varchar(24),
    @instruments varchar(1024),
    @active tinyint,
    @comment varchar(1024),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Set @message = ''

    Declare @msg varchar(256)

    Declare @logErrors tinyint = 0
        
    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'AddUpdateBionetHost', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin Try     

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------
    
        If @mode IS NULL OR Len(@mode) < 1
        Begin
            Set @myError = 51002
            RAISERROR ('@mode cannot be blank',
                11, 1)
        End

        If @host IS NULL OR Len(@host) < 1
        Begin
            Set @myError = 51002
            RAISERROR ('@host cannot be blank',
                11, 1)
        End

        Set @ip = IsNull(@ip, '')
        
        If Len(Ltrim(Rtrim(IsNull(@alias, '')))) = 0 Set @alias = Null
        If Len(Ltrim(Rtrim(IsNull(@tag, '')))) = 0 Set @tag = Null
        If Len(Ltrim(Rtrim(IsNull(@instruments, '')))) = 0 Set @instruments = Null
        If Len(Ltrim(Rtrim(IsNull(@comment, '')))) = 0 Set @comment = Null

        Set @active = IsNull(@active, 1)
    
        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------
    
        If @mode = 'add' And Exists (SELECT * FROM T_Bionet_Hosts WHERE Host = @host)
        Begin
            -- Cannot create an entry that already exists
            --
            Set @msg = 'Cannot add: item "' + @host + '" is already in the database'
            RAISERROR (@msg, 11, 1)
            return 51004
        End
        
        
        If @mode = 'update' And Not Exists (SELECT * FROM T_Bionet_Hosts WHERE Host = @host)
        Begin
            -- Cannot update a non-existent entry
            Set @msg = 'Cannot update: item "' + @host + '" is not in the database'
            RAISERROR (@msg, 11, 16)
            return 51005
        End
    
        Set @logErrors = 1

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------
        --
        If @Mode = 'add'
        Begin
        
            INSERT INTO T_Bionet_Hosts( 
                Host,
                IP,
                Alias,
                Entered,
                Instruments,
                Active,
                Tag,
                Comment
            )
            VALUES(
                @host, 
                @ip, 
                @alias, 
                GetDate(), 
                @instruments, 
                @active, 
                @tag,
                @comment
            )
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
                RAISERROR ('Insert operation failed: "%s"', 11, 7, @host)
    
        End -- add mode
    
        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------
        --
        If @Mode = 'update' 
        Begin

            UPDATE T_Bionet_Hosts
            SET IP = @ip,
                Alias = @alias,
                Instruments = @instruments,
                Active = @active,
                Tag = @tag,
                Comment = @comment
            WHERE Host = @host
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
                RAISERROR ('Update operation failed: "%s"', 11, 4, @host)
    
        End -- update mode
    
    End Try
    Begin Catch 
        EXEC FormatErrorMessage @message output, @myError output
        
        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec PostLogEntry 'Error', @message, 'AddUpdateBionetHost'
        End
        
    End Catch

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateBionetHost] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateBionetHost] TO [DMS2_SP_User] AS [dbo]
GO
