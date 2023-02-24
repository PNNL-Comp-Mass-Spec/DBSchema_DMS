/****** Object:  StoredProcedure [dbo].[update_dataset_dispositions_by_name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_dataset_dispositions_by_name]
/****************************************************
**
**  Desc:
**      Updates datasets in list according to disposition parameters
**      Accepts list of dataset names
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   10/15/2008 grk - Initial release (Ticket #582)
**          08/19/2010 grk - Try-catch for error handling
**          09/02/2011 mem - Now calling post_usage_log_entry
**          02/20/2013 mem - Expanded @message to varchar(1024)
**          02/21/2013 mem - Now requiring @recycleRequest to be yes or no
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/03/2018 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetList varchar(6000),
    @rating varchar(64) = '',
    @comment varchar(512) = '',
    @recycleRequest varchar(32) = '', -- yes/no
    @mode varchar(12) = 'update',
    @message varchar(1024) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @datasetCount int = 0
    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_dataset_dispositions_by_name', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input parameters
    ---------------------------------------------------

    Set @rating = IsNull(@rating, '')
    Set @recycleRequest = IsNull(@recycleRequest, '')
    Set @comment = IsNull(@comment, '')

    If Not @recycleRequest IN ('yes', 'no')
    Begin
        set @message = 'RecycleRequest must be Yes or No (currently "' + @recycleRequest + '")'
        RAISERROR (@message, 11, 11)
    End

    ---------------------------------------------------
    -- Create a table variable for holding dataset names and IDs
    ---------------------------------------------------
    --
    --
    Declare @tbl table (
        DatasetID varchar(12),
        DatasetName varchar(128)
    )

    --------------------------------------------------
    -- add datasets from input list to table
    ---------------------------------------------------
    --
    INSERT INTO @tbl( DatasetName )
    SELECT Item
    FROM make_table_from_list ( @datasetList )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error populating temporary dataset table'
        RAISERROR (@message, 11, 7)
    end

    ---------------------------------------------------
    -- Look up dataset IDs for datasets
    ---------------------------------------------------
    --
    UPDATE @tbl
    SET DatasetID = convert(varchar(12), D.Dataset_ID)
    FROM @tbl T
         INNER JOIN T_Dataset D
           ON D.Dataset_Num = T.DatasetName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error finding dataset IDs'
        RAISERROR (@message, 11, 8)
    end

    ---------------------------------------------------
    -- Any datasets not found?
    ---------------------------------------------------
    --
    Declare @datasetIDList varchar(6000) = ''

    SELECT @datasetIDList = @datasetIDList + CASE
                                                 WHEN @datasetIDList = '' THEN ''
                                                 ELSE ', '
                                             END + DatasetName
    FROM @tbl
    WHERE DatasetID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error looking for missing datasets'
        RAISERROR (@message, 11, 10)
    end
    --
    if @myRowCount > 0
    begin
        set @message = 'Datasets not found: ' + @datasetIDList
        RAISERROR (@message, 11, 11)
    end

    ---------------------------------------------------
    -- Make list of dataset IDs
    ---------------------------------------------------

    set @datasetIDList = ''

    select @datasetIDList =  @datasetIDList + case when @datasetIDList = '' then '' else ', ' end + DatasetID
    from @tbl
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error making dataset ID list'
        RAISERROR (@message, 11, 12)
    end

    Set @datasetCount = @myRowCount

    Set @logErrors = 1

    ---------------------------------------------------
    -- Call sproc to update dataset disposition
    ---------------------------------------------------

    exec @myError = update_dataset_dispositions
                        @datasetIDList,
                        @rating,
                        @comment,
                        @recycleRequest,
                        @mode,
                        @message output,
                        @callingUser

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec post_log_entry 'Error', @message, 'update_dataset_dispositions_by_name'
        End
    END CATCH

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = Convert(varchar(12), @datasetCount) + ' datasets updated'
    Exec post_usage_log_entry 'update_dataset_dispositions_by_name', @UsageMessage

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_dataset_dispositions_by_name] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_dataset_dispositions_by_name] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_dataset_dispositions_by_name] TO [Limited_Table_Write] AS [dbo]
GO
