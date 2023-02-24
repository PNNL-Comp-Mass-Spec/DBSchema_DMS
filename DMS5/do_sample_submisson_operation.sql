/****** Object:  StoredProcedure [dbo].[DoSampleSubmissonOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DoSampleSubmissonOperation]
/****************************************************
**
**  Desc: 
**      Performs operation given by @mode on entity given by @ID
**
**      Note: this procedure has not been used since 2012
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   05/07/2010 grk - initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**                         - Add call to PostUsageLogEntry
**          08/01/2017 mem - Use THROW if not authorized
**          01/12/2023 mem - Remove call to CallSendMessage since it was deprecated in 2016
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2010, Battelle Memorial Institute
*****************************************************/
(
    @ID int,
    @mode varchar(12),                    -- 'make_folder'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
As
    Set XACT_ABORT, nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''
    
    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'DoSampleSubmissonOperation', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

        ---------------------------------------------------
        -- Make the folder for the sample submission
        ---------------------------------------------------
        --
        if @mode = 'make_folder'
        begin
            ---------------------------------------------------
            -- get storage path from sample submission
            --
            DECLARE @storagePath INT = 0
            --
            SELECT @storagePath = ISNULL(Storage_Path, 0)
            FROM T_Sample_Submission
            WHERE ID = @ID

            ---------------------------------------------------
            -- if storage path not defined, get valid path ID and update sample submission
            --
            IF @storagePath = 0
            BEGIN 
                --
                SELECT @storagePath = ID
                FROM T_Prep_File_Storage
                WHERE State = 'Active' AND
                      Purpose = 'Sample_Prep'
                --
                IF @storagePath = 0
                    RAISERROR('Storage path for files could not be found', 11, 24)
                --
                UPDATE T_Sample_Submission
                SET Storage_Path = @storagePath
                WHERE ID = @ID
            END

            -- CallSendMessage was deprecated in 2016
            --
            -- EXEC @myError = CallSendMessage @ID,'sample_submission', @message output
            -- if @myError <> 0
            --    RAISERROR ('CallSendMessage:%s', 11, 27, @message)
        end

    END TRY
    BEGIN CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        Exec PostLogEntry 'Error', @message, 'DoSampleSubmissonOperation'
    END CATCH
        
    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    If IsNull(@ID, 0) > 0
    Begin
        Declare @UsageMessage varchar(512)
        Set @UsageMessage = 'Performed submission operation for submission ID ' + Cast(@ID as varchar(12)) + '; mode ' + @mode
        
        Set @UsageMessage = @UsageMessage + '; user ' + IsNull(@callingUser, '??')
        
        Exec PostUsageLogEntry 'DoSampleSubmissonOperation', @UsageMessage, @MinimumUpdateInterval=2
    End
    
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DoSampleSubmissonOperation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoSampleSubmissonOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoSampleSubmissonOperation] TO [Limited_Table_Write] AS [dbo]
GO
