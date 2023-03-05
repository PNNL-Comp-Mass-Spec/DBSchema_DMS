/****** Object:  StoredProcedure [dbo].[make_new_ims_demux_job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_new_ims_demux_job]
/****************************************************
**
**  Desc:
**      Creates a new IMSDemultiplex job for the specified dataset
**      This would typically be used to repeat the demultiplexing of a dataset
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   08/29/2012 mem - Initial version
**          02/03/2023 bcg - Use synonym S_DMS_V_DatasetFullDetails instead of view wrapping it
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
(
    @datasetName varchar(128),
    @infoOnly tinyint = 0,                          -- 0 To perform the update, 1 preview job that would be created
    @message varchar(512)='' output
)
AS
    Set nocount on

    declare @myError int
    declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    Declare @DatasetID int
    Declare @JobID int

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''


    If @DatasetName Is Null
    Begin
        Set @message = 'Dataset name not defined'
        Set @myError = 50000
        Goto Done
    End

    ---------------------------------------------------
    -- Validate this dataset and determine its Dataset_ID
    ---------------------------------------------------

    Set @DatasetID = 0

    SELECT @DatasetID = Dataset_ID
    FROM S_DMS_V_DatasetFullDetails
    WHERE Dataset_num = @DatasetName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Dataset not found: ' + @DatasetName + '; unable to continue'
        Set @myError = 50002
        Goto Done
    End

    ---------------------------------------------------
    -- Make sure a pending or running IMSDemultiplex job doesn't already exist
    ---------------------------------------------------
    --
    Set @JobID = 0

    SELECT @JobID = JS.Job
    FROM T_Task_Steps JS INNER JOIN T_Tasks J ON JS.Job = J.Job
    WHERE (J.Dataset_ID = @DatasetID) AND (JS.Tool = 'IMSDemultiplex') AND (JS.State IN (1, 2, 4))

    If @JobID > 0
    Begin
        Set @message = 'Existing pending/running job already exists for ' + @DatasetName + '; job ' + Convert(varchar(12), @JobID)
        Set @myError = 0
        Goto Done
    End


    ---------------------------------------------------
    -- create new IMSDemultiplex job for the specified dataset
    ---------------------------------------------------
    --
    If @infoOnly = 1
    Begin
        SELECT
            'IMSDemultiplex' AS Script,
            @DatasetName AS Dataset,
            @DatasetID AS Dataset_ID,
            'Created manually using make_new_ims_demux_job' AS Comment
    End
    Else
    Begin

        INSERT INTO T_Tasks (Script, Dataset, Dataset_ID, Results_Folder_Name, Comment)
        SELECT
            'IMSDemultiplex' AS Script,
            @DatasetName AS Dataset,
            @DatasetID AS Dataset_ID,
            '' AS Results_Folder_Name,
            'Created manually using make_new_ims_demux_job' AS Comment
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error trying to add new IMSDemultiplex job'
            goto Done
        end

        Set @JobID = SCOPE_IDENTITY()

        Set @message = 'Created IMSDemultiplex Job ' + Convert(varchar(12), @JobID) + ' for dataset ' + @DatasetName

    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    If @message <> ''
        Print @message

GO
GRANT VIEW DEFINITION ON [dbo].[make_new_ims_demux_job] TO [DDL_Viewer] AS [dbo]
GO
