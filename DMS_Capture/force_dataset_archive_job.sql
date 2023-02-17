/****** Object:  StoredProcedure [dbo].[force_dataset_archive_job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[force_dataset_archive_job]
/****************************************************
**
**  Desc:
**      Creates DatasetArchive job in broker for given
**  broker DatasetCapture job
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   01/22/2010
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job INT,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- find job
    ---------------------------------------------------
    --
    DECLARE @script varchar(64)
    DECLARE @state int
    DECLARE @dataset varchar(128)
    DECLARE @datasetID int
    --
    SELECT
        @script = Script,
        @state = State,
        @dataset = Dataset,
        @datasetID = Dataset_ID
    FROM
        T_Jobs
    WHERE
        Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error querying target job'
        goto Done
    end
    if @myRowCount <> 1
    begin
        set @message = 'Target job not found in job table'
        SET @myError = 2
        goto Done
    end

    ---------------------------------------------------
    -- is there another DatasetArchive job
    -- for this dataset already in broker?
    ---------------------------------------------------
    --
    DECLARE @hit int
    --
    SELECT
      @hit = Job
    FROM
      T_Jobs
    WHERE
      Dataset_ID = @datasetID
      AND Script = 'DatasetArchive'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error looking for existing DatasetArchive job'
        goto Done
    end
    if @myRowCount > 0
    begin
        set @message = 'A DatasetArchive job for dataset "' + @dataset + '" already exists'
        SET @myError = 2
        goto Done
    end

    ---------------------------------------------------
    -- create dataset archive entry in DMS
    ---------------------------------------------------
    --
    EXEC @myError = s_add_archive_dataset @datasetID
    --
    if @myError <> 0
    begin
        set @message = 'Error updating Resume job step depencies'
        goto Done
    end

    ---------------------------------------------------
    -- create DatasetArchive job
    ---------------------------------------------------
    --
    INSERT  INTO T_Jobs (
        Script,
        Dataset,
        Dataset_ID,
        Comment
    ) VALUES (
        'DatasetArchive',
        @dataset,
        @datasetID,
        'Created by force_dataset_archive_job'
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error creating DatasetArchive job'
        goto Done
    end

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[force_dataset_archive_job] TO [DDL_Viewer] AS [dbo]
GO
