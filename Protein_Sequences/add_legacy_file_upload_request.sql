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
**
*****************************************************/
(
    @legacy_file_Name varchar(128),
    @message varchar(256) = '' output,
    @authenticationHash varchar(8) = ''         -- Sha1 hash for the file
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    declare @msg varchar(256)
    declare @member_ID int

    declare @legacy_file_ID int
    declare @AuthenticationHashStored varchar(8)
    declare @request_ID int

    set @message = ''

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT  @legacy_file_ID = Legacy_File_ID,
            @AuthenticationHashStored = Authentication_Hash
    FROM T_Legacy_File_Upload_Requests
    WHERE Legacy_Filename = @legacy_file_Name

    SELECT @myError = @@error, @myRowCount = @@rowcount

    if @myRowCount > 0
    begin
        -- Entry already exists; update the hash if different
        if IsNull(@AuthenticationHashStored, '') <> IsNull(@AuthenticationHash, '')
            UPDATE T_Legacy_File_Upload_Requests
            SET Authentication_Hash = @AuthenticationHash
            WHERE Legacy_File_ID = @legacy_file_ID

        Return 0
    end

    ---------------------------------------------------
    -- Get File ID from DMS
    ---------------------------------------------------

    SELECT @legacy_File_ID = ID
    FROM V_Legacy_Static_File_Locations
    WHERE File_Name = @legacy_File_name

    SELECT @myError = @@error, @myRowCount = @@rowcount

    if @myRowCount = 0
    begin
        return 0
    end

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'add_legacy_file_upload_request'
    begin transaction @transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    INSERT INTO T_Legacy_File_Upload_Requests (
        Legacy_File_ID,
        Legacy_Filename,
        Date_Requested,
        Authentication_Hash)
    VALUES (
        @legacy_File_ID,
        @legacy_File_name,
        GETDATE(),
        @AuthenticationHash)


    SELECT @request_ID = @@Identity

    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @msg = 'Insert operation failed: "' + @legacy_File_name + '"'
        RAISERROR (@msg, 10, 1)
        return 51007
    end

    commit transaction @transName

    return @request_ID

GO
GRANT EXECUTE ON [dbo].[add_legacy_file_upload_request] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_legacy_file_upload_request] TO [proteinseqs\ftms] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_legacy_file_upload_request] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_legacy_file_upload_request] TO [svc-dms] AS [dbo]
GO