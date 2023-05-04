/****** Object:  StoredProcedure [dbo].[add_legacy_file_upload_request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_legacy_file_upload_request]
/****************************************************
**
**  Desc: Adds or changes the legacy fasta details in T_Legacy_File_Upload_Requests
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   01/11/2006
**          02/11/2009 mem - Added parameter @AuthenticationHash
**          09/03/2010 mem - Now updating the stored Authentication_Hash value if @AuthenticationHash differs from the stored value
**          01/06/2023 mem - Use new column name in view
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**          05/03/2023 mem - Return 0 if no errors (previously returned the ID of the newly added row, but the calling application does not use that value)
**
*****************************************************/
(
    @legacyFileName varchar(128),
    @message varchar(256) = '' output,
    @authenticationHash varchar(8) = ''         -- Sha1 hash for the file
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(256)
    Declare @memberID int

    Declare @legacyFileID int
    Declare @AuthenticationHashStored varchar(8)
    Declare @requestID int

    set @message = ''

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT  @legacyFileID = Legacy_File_ID,
            @AuthenticationHashStored = Authentication_Hash
    FROM T_Legacy_File_Upload_Requests
    WHERE Legacy_Filename = @legacyFileName

    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        -- Entry already exists; update the hash if different
        If IsNull(@AuthenticationHashStored, '') <> IsNull(@AuthenticationHash, '')
        Begin
            UPDATE T_Legacy_File_Upload_Requests
            SET Authentication_Hash = @AuthenticationHash
            WHERE Legacy_File_ID = @legacyFileID
        End

        Return 0
    End

    ---------------------------------------------------
    -- Get File ID from DMS
    ---------------------------------------------------

    SELECT @legacyFileID = ID
    FROM V_Legacy_Static_File_Locations
    WHERE File_Name = @legacyFileName

    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Return 0
    End

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    Declare @transName varchar(32) = 'add_legacy_file_upload_request'

    Begin Transaction @transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    INSERT INTO T_Legacy_File_Upload_Requests (
        Legacy_File_ID,
        Legacy_Filename,
        Date_Requested,
        Authentication_Hash)
    VALUES (
        @legacyFileID,
        @legacyFileName,
        GETDATE(),
        @AuthenticationHash)


    SELECT @requestID = @@Identity

    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        set @msg = 'Insert operation failed: "' + @legacyFileName + '"'
        RAISERROR (@msg, 10, 1)
        Return 51007
    End

    Commit Transaction @transName

    Return 0

GO
GRANT EXECUTE ON [dbo].[add_legacy_file_upload_request] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_legacy_file_upload_request] TO [proteinseqs\ftms] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_legacy_file_upload_request] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_legacy_file_upload_request] TO [svc-dms] AS [dbo]
GO
