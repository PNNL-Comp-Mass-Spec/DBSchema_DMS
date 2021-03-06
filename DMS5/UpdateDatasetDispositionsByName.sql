/****** Object:  StoredProcedure [dbo].[UpdateDatasetDispositionsByName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateDatasetDispositionsByName]
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
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          02/20/2013 mem - Expanded @message to varchar(1024)
**          02/21/2013 mem - Now requiring @recycleRequest to be yes or no
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/03/2018 mem - Use @logErrors to toggle logging errors caught by the try/catch block
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
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @datasetCount int = 0
    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
   
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'UpdateDatasetDispositionsByName', @raiseError = 1
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
    FROM MakeTableFromList ( @datasetList )
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

    exec @myError = UpdateDatasetDispositions
                        @datasetIDList,
                        @rating,
                        @comment,
                        @recycleRequest,
                        @mode,
                        @message output,
                        @callingUser
    
    END TRY
    BEGIN CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
            
        If @logErrors > 0
        Begin
            Exec PostLogEntry 'Error', @message, 'UpdateDatasetDispositionsByName'
        End
    END CATCH

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = Convert(varchar(12), @datasetCount) + ' datasets updated'
    Exec PostUsageLogEntry 'UpdateDatasetDispositionsByName', @UsageMessage

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetDispositionsByName] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateDatasetDispositionsByName] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetDispositionsByName] TO [Limited_Table_Write] AS [dbo]
GO
