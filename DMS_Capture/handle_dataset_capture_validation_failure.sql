/****** Object:  StoredProcedure [dbo].[handle_dataset_capture_validation_failure] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[handle_dataset_capture_validation_failure]
/****************************************************
**
**  Desc:
**      This procedure can be used with datasets that
**      are successfully captured but fail the dataset integrity check
**      (.Raw file too small, expected files missing, etc).
**
**      The procedure changes the capture job state to 101
**      then calls handle_dataset_capture_validation_failure in DMS5
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   04/28/2011
**          09/13/2011 mem - Updated to support script 'IMSDatasetCapture' in addition to 'DatasetCapture'
**          11/05/2012 mem - Added additional Print statement
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          08/10/2018 mem - Call update_dms_file_info_xml to push the dataset info into DMS5.T_Dataset_Info
**          11/02/2020 mem - Fix bug validating the dataset name
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
(
    @datasetNameOrID varchar(255),
    @comment varchar(255) = 'Bad .raw file',
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @datasetID int
    Declare @datasetName varchar(255)
    Declare @captureJob int

    Set @datasetName = ''
    Set @datasetID = 0
    Set @captureJob = 0

    ----------------------------------------
    -- Validate the inputs
    ----------------------------------------

    Set @datasetNameOrID = IsNull(@datasetNameOrID, '')
    Set @comment = IsNull(@comment, '')
    Set @message = ''

    If @comment = ''
        Set @comment = 'Bad dataset'

    Set @datasetID = IsNull(Try_Parse(@datasetNameOrID as int), 0)
    If @datasetID <> 0
    Begin
        ----------------------------------------
        -- Lookup the Dataset Name
        ----------------------------------------

        Set @datasetID = Convert(int, @datasetNameOrID)

        SELECT @datasetName = Dataset
        FROM T_Tasks
        WHERE Dataset_ID = @datasetID AND
              Script IN ('DatasetCapture', 'IMSDatasetCapture')

        If @datasetName = ''
        Begin
            set @message = 'Dataset ID not found: ' + @datasetNameOrID
            Set @myError = 50000
            Print @message
        End

    End
    Else
    Begin
        ----------------------------------------
        -- Lookup the dataset ID
        ----------------------------------------

        Set @datasetName = @datasetNameOrID

        SELECT @datasetID = Dataset_ID
        FROM T_Tasks
        WHERE Dataset = @datasetName AND
              Script IN ('DatasetCapture', 'IMSDatasetCapture')

        If @datasetID = 0
        Begin
            set @message = 'Dataset not found: ' + @datasetName
            Set @myError = 50001
            Print @message
        End
    End

    If @myError = 0
    Begin
        -- Make sure the DatasetCapture job has failed
        SELECT @captureJob = Job
        FROM T_Tasks
        WHERE Dataset_ID = @datasetID AND
              Script IN ('DatasetCapture', 'IMSDatasetCapture') AND
              State = 5
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        IF @myRowCount = 0 Or @captureJob = 0
        Begin
            Set @message = 'DatasetCapture job for dataset ' + @datasetName + ' is not in State 5; unable to continue'
            Set @myError = 50002
            Print @message
        End
    End

    If @myError = 0
    Begin -- <a>
        If @infoOnly <> 0
        Begin
            SELECT 'Mark dataset as bad: ' + @comment as Message, *
            FROM T_Tasks
            WHERE Dataset_ID = @datasetID AND
                  Script IN ('DatasetCapture', 'IMSDatasetCapture') AND
                  State = 5

        End
        Else
        Begin -- <b>

            -- Call update_dms_file_info_xml to push the dataset info into DMS5.T_Dataset_Info
            -- If a duplicate dataset is found, @myError will be 53600
            EXEC @myError = update_dms_file_info_xml @datasetID, @DeleteFromTableOnSuccess=1, @message=@message Output

            If @myError = 53600
            Begin
                -- Use special completion code of 101
                EXEC @myError = s_set_capture_task_complete @datasetName, 101, @message OUTPUT, @failureMessage = @message

                -- Fail out the job with state 14 (Failed, Ignore Job Step States)
                UPDATE T_Tasks
                SET State = 14
                WHERE Job = @captureJob
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                Goto Done
            End

            UPDATE T_Tasks
            SET State = 101
            WHERE Job = @captureJob
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @message = 'Unable to update job ' + Cast(@captureJob As varchar(12)) + 'in T_Tasks for dataset ' + @datasetName
                Set @myError = 50003
                Print @message
            End
            Else
            Begin
                -- Mark the dataset as bad in DMS5
                Exec DMS5.dbo.handle_dataset_capture_validation_failure @datasetID, @comment, @infoOnly, ''

                Set @message = 'Marked dataset as bad: ' + @datasetName
                Print @message

            End
        End -- </b>

    End -- </a>

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[handle_dataset_capture_validation_failure] TO [DDL_Viewer] AS [dbo]
GO
