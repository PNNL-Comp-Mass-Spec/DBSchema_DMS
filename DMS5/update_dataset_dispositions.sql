/****** Object:  StoredProcedure [dbo].[update_dataset_dispositions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_dataset_dispositions]
/****************************************************
**
**  Desc:
**      Updates datasets in list according to disposition parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   04/25/2007
**          06/26/2007 grk - Fix problem with multiple datasets (Ticket #495)
**          08/22/2007 mem - Disallow setting datasets to rating 5 (Released) when their state is 5 (Capture Failed); Ticket #524
**          03/25/2008 mem - Added optional parameter @callingUser; if provided, then will call alter_event_log_entry_user (Ticket #644)
**          08/15/2008 mem - Added call to alter_event_log_entry_user to handle dataset rating entries (event log target type 8)
**          08/19/2010 grk - try-catch for error handling
**          11/18/2010 mem - Updated logic for calling schedule_predefined_analysis_jobs to include dataset state 4 (Inactive)
**          09/02/2011 mem - Now calling post_usage_log_entry
**          12/13/2011 mem - Now passing @callingUser to unconsume_scheduled_run
**          02/20/2013 mem - Expanded @message to varchar(1024)
**          02/21/2013 mem - More informative error messages
**          05/08/2013 mem - No longer passing @wellplateNum and @wellNum to unconsume_scheduled_run
**          03/30/2015 mem - Tweak warning message grammar
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/23/2021 mem - Use a semicolon when appending to an existing dataset comment
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/02/2023 mem - Use renamed table names
**
*****************************************************/
(
    @datasetIDList varchar(6000),
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

    set @message = ''

    Declare @msg varchar(512)
    Declare @list varchar(1024)

    Declare @datasetCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_dataset_dispositions', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    if @datasetIDList = ''
    begin
        set @msg = 'Dataset list is empty'
        RAISERROR (@msg, 11, 1)
    end

    ---------------------------------------------------
    -- Resolve rating name
    ---------------------------------------------------
    Declare @ratingID int
    set @ratingID = 0
    --
    SELECT @ratingID = DRN_state_ID
    FROM  T_Dataset_Rating_Name
    WHERE (DRN_name = @rating)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @msg = 'Error looking up rating name'
        RAISERROR (@msg, 11, 2)
    end
    --
    if @ratingID = 0
    begin
        set @msg = 'Invalid rating: ' + @rating
        RAISERROR (@msg, 11, 3)
    end

    ---------------------------------------------------
    --  Create temporary table to hold list of datasets
    ---------------------------------------------------

    CREATE TABLE #TDS (
        DatasetID int,
        DatasetName varchar(128) NULL,
        RatingID int NULL,
        State int NULL,
        Comment varchar(512) NULL
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @msg = 'Failed to create temporary dataset table'
        RAISERROR (@msg, 11, 4)
    end

    ---------------------------------------------------
    -- Populate table from dataset list
    ---------------------------------------------------

    INSERT INTO #TDS (DatasetID)
    SELECT CAST(Item as int)
    FROM make_table_from_list(@datasetIDList)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @msg = 'Error populating temporary dataset table'
        RAISERROR (@msg, 11, 5)
    end


    ---------------------------------------------------
    -- Verify that all datasets exist
    ---------------------------------------------------
    --
    set @list = ''
    --
    SELECT
        @list = @list + CASE
        WHEN @list = '' THEN cast(DatasetID as varchar(12))
        ELSE ', ' + cast(DatasetID as varchar(12))
        END
    FROM
        #TDS
    WHERE
        NOT DatasetID IN (SELECT Dataset_ID FROM T_Dataset)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error checking dataset existence'
        return 51007
    end
    --
    if @list <> ''
    begin
        if @myRowCount = 1
            set @message = 'Dataset "' + @list + '" was not found in the database'
        else
            set @message = 'The following datasets were not in the database: "' + @list + '"'

        return 51007
    end

    SELECT @datasetCount = count(*) FROM #TDS
    set @message = 'Number of affected datasets:' + cast(@datasetCount as varchar(12))

    ---------------------------------------------------
    -- Get information for datasets in list
    ---------------------------------------------------

    UPDATE M
    SET
        M.RatingID = T.DS_rating,
        M.DatasetName = T.Dataset_Num,
        M.State =  DS_state_ID,
        M.Comment = DS_comment
    FROM #TDS M INNER JOIN
    T_Dataset T ON T.Dataset_ID = M.DatasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error updating dataset rating'
        return 51022
    end

    ---------------------------------------------------
    -- Update datasets from temporary table
    ---------------------------------------------------
    --
    if @Mode = 'update'
    begin
        set @myError = 0

        Declare @prevDatasetID int = 0
        Declare @curDatasetID int = 0
        Declare @curDatasetName varchar(128) = ''
        Declare @curRatingID int = 0
        Declare @curDatasetState int = 0
        Declare @curDatasetStateName varchar(64) = ''
        Declare @curComment varchar(512) = ''
        Declare @done int = 0
        Declare @transName varchar(32) = 'update_dataset_dispositions'

        ---------------------------------------------------
        while @done = 0
        begin

            -----------------------------------------------
            -- get next dataset ID from temp table
            --
            set @curDatasetID = 0
            SELECT TOP 1
                @curDatasetID = D.DatasetID,
                @curDatasetName = D.DatasetName,
                @curRatingID = D.RatingID,
                @curDatasetState = D.State,
                @curComment = D.Comment,
                @curDatasetStateName = DSN.DSS_name
            FROM #TDS AS D INNER JOIN
                 dbo.T_Dataset_State_Name DSN ON D.State = DSN.Dataset_state_ID
            WHERE D.DatasetID > @prevDatasetID
            ORDER BY D.DatasetID
            --
            if @curDatasetID = 0
                begin
                    set @done = 1
                end
            else
                begin
                    If @curDatasetState = 5
                    Begin
                        -- Do not allow update to rating of 2 or higher when the dataset state is 5 (Capture Failed)
                        If @ratingID >= 2
                        Begin
                            set @msg = 'Cannot set dataset rating to ' + @rating + ' for dataset "' + @curDatasetName + '" since its state is ' + @curDatasetStateName
                            RAISERROR (@msg, 11, 6)
                        End
                    End

                    begin transaction @transName

                    -----------------------------------------------
                    -- update dataset
                    --
                    if @curComment <> '' AND @comment <> ''
                    Begin
                        -- Append the new comment only if it is not already present
                        If CharIndex(@comment, @curComment) <= 0
                            set @curComment = @curComment + '; ' + @comment
                    End
                    else
                    Begin
                        if @curComment = '' AND @comment <> ''
                            set @curComment = @comment
                    End
                    --
                    UPDATE T_Dataset
                    SET
                        DS_comment = @curComment,
                        DS_rating = @ratingID
                    WHERE (Dataset_ID = @curDatasetID)
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount
                    --
                    if @myError <> 0
                    begin
                        set @msg = 'Update operation failed for dataset ' + @curDatasetName
                        RAISERROR (@msg, 11, 7)
                    end

                    -----------------------------------------------
                    -- recycle request?
                    --
                    if @recycleRequest = 'Yes'
                    begin
                        exec @myError = unconsume_scheduled_run @curDatasetName, @retainHistory=1, @message=@message output, @callingUser=@callingUser
                        --
                        if @myError <> 0
                        begin
                            RAISERROR (@message, 11, 8)
                        end
                    end

                    -----------------------------------------------
                    -- evaluate predefined analyses
                    --
                    -- if rating changes from unreviewed to released
                    -- and dataset capture is complete
                    --
                    if @curRatingID = -10 and @ratingID = 5 AND @curDatasetState IN (3, 4)
                    begin
                        -- schedule default analyses for this dataset
                        --
                        execute @myError = schedule_predefined_analysis_jobs @curDatasetName, @callingUser
                        --
                        if @myError <> 0
                        begin
                            rollback transaction @transName
                            return @myError
                        end

                    end

                    -----------------------------------------------
                    --
                    commit transaction @transName

                    -- If @callingUser is defined, then call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
                    If Len(@callingUser) > 0
                        Exec alter_event_log_entry_user 8, @curDatasetID, @ratingID, @callingUser

                    set @prevDatasetID = @curDatasetID
                end

        end -- while
    end -- update mode

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'update_dataset_dispositions'
    END CATCH

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = Convert(varchar(12), @datasetCount) + ' datasets updated'
    Exec post_usage_log_entry 'update_dataset_dispositions', @UsageMessage

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_dataset_dispositions] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_dataset_dispositions] TO [DMS_RunScheduler] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_dataset_dispositions] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_dataset_dispositions] TO [Limited_Table_Write] AS [dbo]
GO
