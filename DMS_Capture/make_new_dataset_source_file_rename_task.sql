/****** Object:  StoredProcedure [dbo].[make_new_dataset_source_file_rename_task] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_new_dataset_source_file_rename_task]
/****************************************************
**
**  Desc:
**      Creates a new dataset source file rename job for the specified dataset
**
**  Auth:   mem
**  Date:   03/06/2012 mem - Initial version
**          09/09/2022 mem - Fix typo in message
**          02/03/2023 bcg - Use synonym S_DMS_V_DatasetFullDetails instead of view wrapping it
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @datasetName varchar(128),
    @infoOnly tinyint = 0,                            -- 0 To perform the update, 1 preview job that would be created
    @message varchar(512)='' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

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
    -- Make sure a pending source file rename job doesn't already exist
    ---------------------------------------------------
    --
    Set @JobID = 0

    SELECT @JobID = Job
    FROM T_Tasks
    WHERE (Script = 'SourceFileRename') AND
          (T_Tasks.Dataset_ID = @DatasetID) AND
          (State < 3)

    If @JobID > 0
    Begin
        Set @message = 'Existing pending job already exists for ' + @DatasetName + '; job ' + Convert(varchar(12), @JobID)
        Set @myError = 0
        Goto Done
    End


    ---------------------------------------------------
    -- create new SourceFileRename job for specified dataset
    ---------------------------------------------------
    --
    If @infoOnly <> 0
    Begin
        SELECT
            'SourceFileRename' AS Script,
            @DatasetName AS Dataset,
            @DatasetID AS Dataset_ID,
            'Manually created using make_new_dataset_source_file_rename_task' AS Comment
    End
    Else
    Begin

        INSERT INTO T_Tasks (Script, Dataset, Dataset_ID, Results_Folder_Name, Comment)
        SELECT
            'SourceFileRename' AS Script,
            @DatasetName AS Dataset,
            @DatasetID AS Dataset_ID,
            NULL AS Results_Folder_Name,
            'Created manually using make_new_dataset_source_file_rename_task' AS Comment
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error trying to add new Source File Rename step'
            goto Done
        end

        Set @JobID = SCOPE_IDENTITY()

        Set @message = 'Created Job ' + Convert(varchar(12), @JobID) + ' for dataset ' + @DatasetName

    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    If @message <> ''
        Print @message

GO
GRANT VIEW DEFINITION ON [dbo].[make_new_dataset_source_file_rename_task] TO [DDL_Viewer] AS [dbo]
GO
