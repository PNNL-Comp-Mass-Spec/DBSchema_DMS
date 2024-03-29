/****** Object:  StoredProcedure [dbo].[do_dataset_completion_actions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[do_dataset_completion_actions]
/****************************************************
**
**  Desc: Sets state of dataset record given by @datasetName
**        according to given completion code and
**        adjusts related database entries accordingly.
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   11/04/2002
**          08/06/2003 grk - added handling for "Not Ready" state
**          07/01/2005 grk - changed to use "schedule_predefined_analysis_jobs"
**          11/18/2010 mem - Now checking dataset rating and not calling schedule_predefined_analysis_jobs if the rating is -10 (unreviewed)
**                         - Removed CD burn schedule code
**          02/09/2011 mem - Added back calling schedule_predefined_analysis_jobs regardless of dataset rating
**                         - Required since predefines with Trigger_Before_Disposition should create jobs even if a dataset is unreviewed
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/08/2018 mem - Add state 14 (Duplicate dataset files)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetName varchar(128),
    @completionState int = 0, -- 3 (complete), 5 (capture failed), 6 (received), 8 (prep. failed), 9 (not ready), 14 (Duplicate Dataset Files)
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    declare @datasetID int
    declare @datasetState int
    declare @datasetRating smallint

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'do_dataset_completion_actions', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- resolve dataset into ID and state
    ---------------------------------------------------
    --
    SELECT @datasetID = Dataset_ID,
           @datasetState = DS_state_ID,
           @datasetRating = DS_rating
    FROM T_Dataset
    WHERE (Dataset_Num = @datasetName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Could not get dataset ID for dataset ' + @datasetName
        goto done
    end

    ---------------------------------------------------
    -- verify that datset is in correct state
    ---------------------------------------------------
    --
    if not @completionState in (3, 5, 6, 8, 9, 14)
    begin
        set @message = 'Completion state argument incorrect for ' + @datasetName
        goto done
    end

    if not @datasetState in (2, 7)
    begin
        set @message = 'Dataset in incorrect state: ' + @datasetName
        goto done
    end

    if @datasetState = 2 and not @completionState in (3, 5, 6, 9, 14)
    begin
        set @message = 'Transition 1 not allowed: ' + @datasetName
        goto done
    end

    if @datasetState = 7 and not @completionState in (3, 6, 8)
    begin
        set @message = 'Transition 2 not allowed: ' + @datasetName
        goto done
    end


    ---------------------------------------------------
    -- Set up proper compression state
    -- Note: as of February 2010, datasets no longer go through "prep"
    -- Thus, @compressonState and @compressionDate will be null
    ---------------------------------------------------
    --
    declare @compressonState int
    declare @compressionDate datetime
    --
    -- if dataset is in preparation,
    -- compression fields must be marked with values
    -- appropriate to success or failure
    --
    if @datasetState = 7  -- dataset is in preparation
    begin
        if @completionState = 8 -- preparation failed
            begin
                set @compressonState = null
                set @compressionDate = null
            end
        else                    -- preparation succeeded
            begin
                set @compressonState = 1
                set @compressionDate = getdate()
            end
    end

    --
    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------
    --
    declare @transName varchar(32)
    set @transName = 'SetCaptureComplete'
    begin transaction @transName

    ---------------------------------------------------
    -- Update state of dataset
    ---------------------------------------------------
    --
    UPDATE T_Dataset
    SET
        DS_state_ID = @completionState,
        DS_Comp_State = @compressonState,
        DS_Compress_Date = @compressionDate
    WHERE
        (Dataset_ID = @datasetID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0 or  @myRowCount <> 1
    begin
        rollback transaction @transName
        set @myError = 51252
        set @message = 'Update was unsuccessful for dataset ' + @datasetName
        goto done
    end

    ---------------------------------------------------
    -- Skip further changes if completion was anything
    -- other than normal completion
    ---------------------------------------------------

    if @completionState <> 3
    begin
        commit transaction @transName
        goto done
    end

    ---------------------------------------------------
    -- Create a new dataset archive task 
    -- However, if 'ArchiveDisabled" has a value of 1 in T_MiscOptions, the archive task will not be created
    ---------------------------------------------------
    --
    declare @result int
    execute @result = add_archive_dataset @datasetID
    --
    if @result <> 0
    begin
        rollback transaction @transName
        set @myError = 51254
        set @message = 'Update was unsuccessful for archive table ' + @datasetName
        goto done
    end

    commit transaction @transName

    ---------------------------------------------------
    -- Schedule default analyses for this dataset
    -- Call schedule_predefined_analysis_jobs even if the rating is -10 = Unreviewed
    ---------------------------------------------------
    --
    execute @result = schedule_predefined_analysis_jobs @datasetName

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    if @message <> ''
    begin
        RAISERROR (@message, 10, 1)
    end
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[do_dataset_completion_actions] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[do_dataset_completion_actions] TO [Limited_Table_Write] AS [dbo]
GO
