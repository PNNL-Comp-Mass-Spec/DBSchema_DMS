/****** Object:  StoredProcedure [dbo].[AddUpdateStorage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateStorage]
/****************************************************
**
**  Desc: 
**      Adds new or updates existing storage path
**      (saves current state of storage and instrument
**      tables in backup tables)
**
**       Mode    Function:                Action
**               (cur.)    (new)    
**       ----    ------    -----         --------------------
**    
**       Add     (any)     raw-storage   Change any existing raw-storage
**                                       for instrument to old-storage,
**                                       then set assigned storage of
**                                       instrument to new path
**    
**       Update  old       raw-storage   Change any existing raw-storage
**                                       for instrument to old-storage,
**                                       then set assigned storage of
**                                       instrument to new path
**    
**       Update  raw       old-storage   Not allowed
**    
**       Add     (any)     inbox         Not allowed if there is
**                                       an existing inbox path
**                                       for the instrument
**    
**       Update  inbox     (any)         Not allowed
**    
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   04/15/2002
**          05/01/2009 mem - Updated description field in T_Storage_Path to be named SP_description
**          05/09/2011 mem - Now validating @instrumentName
**          07/15/2015 mem - Now checking for an existing entry to prevent adding a duplicate
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/27/2020 mem - Add parameter @urlDomain and update SP_URL_Domain
**          06/24/2021 mem - Add support for re-using an existing storage path when @mode is 'add'
**
*****************************************************/
(
    @path varchar(255), 
    @volNameClient varchar(128),
    @volNameServer varchar(128),
    @storFunction varchar(50),                -- 'inbox', 'old-storage', or 'raw-storage'
    @instrumentName varchar(50),
    @description varchar(255) = '(na)',
    @urlDomain varchar(64) = 'pnl.gov',
    @ID varchar(32) output,
    @mode varchar(12) = 'add',                -- 'add' or 'update'
    @message varchar(512) output
)
As
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Set @message = ''

    Declare @result int
    
    Declare @msg varchar(256)    
    Declare @machineName varchar(64)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'AddUpdateStorage', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If LEN(@path) < 1
    Begin
        Set @msg = 'path was blank'
        RAISERROR (@msg, 10, 1)
        return 51036
    End

    If LEN(@instrumentName) < 1
    Begin
        Set @msg = 'instrumentName was blank'
        RAISERROR (@msg, 10, 1)
        return 51036
    End

    If @storFunction not in ('inbox', 'old-storage', 'raw-storage')
    Begin
        Set @msg = 'Function "' + @storFunction + '" is not recognized'
        RAISERROR (@msg, 10, 1)
        return 51036
    End

    If @mode not in ('add', 'update')
    Begin
        Set @msg = 'Function "' + @mode + '" is not recognized'
        RAISERROR (@msg, 10, 1)
        return 51036
    End
    
    Set @urlDomain = ISNULL(@urlDomain, '')

    ---------------------------------------------------
    -- Resolve machine name
    ---------------------------------------------------
    
    If @storFunction = 'inbox'
        Set @machineName = replace(@volNameServer, '\', '')
    Else
        Set @machineName = replace(@volNameClient, '\', '')
    
    ---------------------------------------------------
    -- Verify instrument name
    ---------------------------------------------------
    
    IF NOT Exists (SELECT * FROM T_Instrument_Name WHERE IN_name = @instrumentName)
    Begin
        Set @msg = 'Unknown instrument "' + @instrumentName + '"'
        RAISERROR (@msg, 10, 1)
        return 51038
    End
    
    ---------------------------------------------------
    -- Only one input path allowed for given instrument
    ---------------------------------------------------

    Declare @num int = 0

    SELECT @num = count(SP_path_ID)
    FROM T_Storage_Path
    WHERE 
        (SP_instrument_name = @instrumentName) AND 
        (SP_function = @storFunction)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Could not check existing storage record'
        RAISERROR (@msg, 10, 1)
        return 51012
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    Declare @tmpID int = 0
    --
    Declare @oldFunction varchar(50)
    Set @oldFunction = ''
    --
    Declare @spID int
    Set @spID = cast(@ID as int)

    -- Cannot update a non-existent entry
    --
    If @mode = 'update'
    Begin
        SELECT 
            @tmpID = SP_path_ID,
            @oldFunction = SP_function
        FROM T_Storage_Path
        WHERE (SP_path_ID = @spID)
        --
        If @tmpID = 0
        Begin    
            Set @msg = 'Cannot update:  Storage path "' + @ID + '" is not in database '
            RAISERROR (@msg, 10, 1)
            return 51004
        End
    End

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    
    If @mode = 'add'
    Begin
    
        -- Check for an existing row to avoid adding a duplicate
        Declare @existingID int = -1
        
        SELECT @existingID = SP_path_ID
        FROM T_Storage_Path
        WHERE SP_path = @path AND
              SP_vol_name_client = @volNameClient AND
              SP_vol_name_server = @volNameServer AND
              SP_function = @storFunction AND
              SP_machine_name = @machineName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        
        Declare @storagePathID Int

        If @myRowCount > 0
        Begin
            -- Do not add a duplicate row
            Set @storagePathID = @existingID
            Set @message = 'Storage path already exists; ID ' + cast(@existingID as varchar(12))
        End
        Else
        Begin
            ---------------------------------------------------
            -- Begin transaction
            ---------------------------------------------------
            --
            Declare @transName varchar(32) = 'AddUpdateStoragePath'
            Begin transaction @transName

            ---------------------------------------------------
            -- Save existing state of instrument and storage tables
            ---------------------------------------------------
            --
            exec @result = BackUpStorageState @msg output
            --
            If @result <> 0
            Begin
                rollback transaction @transName
                Set @msg = 'Backup failed: ' + @msg
                RAISERROR (@msg, 10, 1)
                return 51028
            End

            ---------------------------------------------------
            -- Clean up any existing raw-storage assignments 
            -- for instrument
            ---------------------------------------------------
            --
            If @storFunction = 'raw-storage'
            Begin

                -- Build list of paths that will be changed
                --
                Set @message = ''
                --
                SELECT @message = @message + cast(SP_path_ID as varchar(12)) + ', '
                FROM T_Storage_Path
                WHERE (SP_function = 'raw-storage') AND 
                   (SP_instrument_name = @instrumentName)            

                -- Set any existing raw-storage paths for instrument 
                -- already in storage table to old-storage
                --
                UPDATE T_Storage_Path
                SET SP_function = 'old-storage'
                WHERE 
                    (SP_function = 'raw-storage') AND 
                    (SP_instrument_name = @instrumentName)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myError <> 0
                Begin
                    rollback transaction @transName
                    Set @msg = 'Changing existing raw-storage failed'
                    RAISERROR (@msg, 10, 1)
                    return 51042
                End

                Set @message = cast(@myRowCount as varchar(12)) + ' path(s) (' + @message + ') were changed from raw-storage to old-storage' 
            End

            ---------------------------------------------------
            -- Validate against any existing inbox assignments
            ---------------------------------------------------

            If @storFunction = 'inbox'
            Begin
                Set @tmpID = 0
                --
                SELECT @tmpID = SP_path_ID
                FROM T_Storage_Path
                WHERE 
                    (SP_function = 'inbox') AND 
                    (SP_instrument_name = @instrumentName)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                -- Future: error check
                --
                If @tmpID <> 0
                Begin
                    rollback transaction @transName
                    Set @msg = 'Cannot add new inbox path if one (' + cast(@tmpID as varchar(12))+ ') already exists for instrument'
                    RAISERROR (@msg, 10, 1)
                    return 51036
                End
            End

            ---------------------------------------------------
            -- Add the new entry
            ---------------------------------------------------
            Declare @newID int
            --
            INSERT INTO T_Storage_Path (
                SP_path, 
                SP_vol_name_client, 
                SP_vol_name_server, 
                SP_function, 
                SP_instrument_name, 
                SP_description,
                SP_machine_name,
                SP_URL_Domain
            ) VALUES (
                @path,
                @volNameClient,
                @volNameServer,
                @storFunction,
                @instrumentName,
                @description,
                @machineName,
                @urlDomain
            )
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount, @newID = @@identity
            --
            If @myError <> 0
            Begin
                rollback transaction @transName
                Set @msg = 'Insert new operation failed'
                RAISERROR (@msg, 10, 1)
                return 51007
            End
        
            commit transaction @transName

            Set @storagePathID = @newID
        End

        ---------------------------------------------------
        -- Update the assigned storage for the instrument
        ---------------------------------------------------
        --
        If @storFunction = 'raw-storage'
        Begin
            UPDATE T_Instrument_Name
            SET IN_storage_path_ID = @storagePathID
            WHERE (IN_name = @instrumentName)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @msg = 'Update of instrument assigned storage failed'
                RAISERROR (@msg, 10, 1)
                return 51043
            End
        End

        If @storFunction = 'inbox'
        Begin
            UPDATE T_Instrument_Name
            SET IN_source_path_ID = @storagePathID
            WHERE (IN_name = @instrumentName)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @msg = 'Update of instrument assigned source failed'
                RAISERROR (@msg, 10, 1)
                return 51043
            End
        End

        -- Return storage path ID as text
        --
        Set @ID = cast(@storagePathID as varchar(32))

    End -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update' 
    Begin
        Set @myError = 0

        ---------------------------------------------------
        -- Begin transaction
        ---------------------------------------------------
        --
        Set @transName = 'AddUpdateStoragePath'
        Begin transaction @transName

        ---------------------------------------------------
        -- Save existing state of instrument and storage tables
        ---------------------------------------------------
        --
        exec @result = BackUpStorageState @msg output
        --
        If @result <> 0
        Begin
            rollback transaction @transName
            Set @msg = 'Backup failed: ' + @msg
            RAISERROR (@msg, 10, 1)
            return 51028
        End

        ---------------------------------------------------
        -- Clean up any existing raw-storage assignments 
        -- for instrument when changing to new raw-storage path
        ---------------------------------------------------
        --
        If @storFunction = 'raw-storage' and @oldFunction <> 'raw-storage'
        Begin

            -- Build list of paths that will be changed
            --
            Set @message = ''
            --
            SELECT @message = @message + cast(SP_path_ID as varchar(12)) + ', '
            FROM T_Storage_Path
            WHERE (SP_function = 'raw-storage') AND 
               (SP_instrument_name = @instrumentName)            

            -- Set any existing raw-storage paths for instrument 
            -- already in storage table to old-storage
            --
            UPDATE T_Storage_Path
            SET SP_function = 'old-storage'
            WHERE 
                (SP_function = 'raw-storage') AND 
                (SP_instrument_name = @instrumentName)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                rollback transaction @transName
                Set @msg = 'Changing existing raw-storage failed'
                RAISERROR (@msg, 10, 1)
                return 51042
            End

            ---------------------------------------------------
            -- Update the assigned storage for the instrument
            ---------------------------------------------------
            --
            UPDATE T_Instrument_Name
            SET IN_storage_path_ID = @tmpID
            WHERE (IN_name = @instrumentName)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                rollback transaction @transName
                Set @msg = 'Update of instrument assigned storage failed'
                RAISERROR (@msg, 10, 1)
                return 51043
            End

            Set @message = cast(@myRowCount as varchar(12)) + ' path(s) (' + @message + ') were changed from raw-storage to old-storage' 
        End

        ---------------------------------------------------
        -- Validate against changing current raw-storage path
        -- to old-storage
        ---------------------------------------------------
        --
        If @storFunction <> 'raw-storage' and @oldFunction = 'raw-storage'
        Begin
            rollback transaction @transName
            Set @msg = 'Cannot change existing raw-storage path to old-storage'
            RAISERROR (@msg, 10, 1)
            return 51037
        End

        ---------------------------------------------------
        -- Validate against any existing inbox assignments
        ---------------------------------------------------

        If @storFunction <> 'inbox' and @oldFunction = 'inbox'
        Begin
            rollback transaction @transName
            Set @msg = 'Cannot change existing inbox path to another function'
            RAISERROR (@msg, 10, 1)
            return 51037
        End

        ---------------------------------------------------
        -- 
        ---------------------------------------------------
        --
        UPDATE T_Storage_Path
        SET 
            SP_path =@path, 
            SP_vol_name_client =@volNameClient, 
            SP_vol_name_server =@volNameServer, 
            SP_function =@storFunction, 
            SP_instrument_name =@instrumentName, 
            SP_description =@description,
            SP_machine_name = @machineName
        WHERE (SP_path_ID = @spID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @msg = 'Update operation failed: "' + @ID + '"'
            RAISERROR (@msg, 10, 1)
            return 51004
        End
        
        commit transaction @transName

    End -- update mode

Done:

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateStorage] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateStorage] TO [DMS_Storage_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateStorage] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateStorage] TO [Limited_Table_Write] AS [dbo]
GO
