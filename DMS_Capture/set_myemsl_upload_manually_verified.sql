/****** Object:  StoredProcedure [dbo].[set_myemsl_upload_manually_verified] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_myemsl_upload_manually_verified]
/****************************************************
**
**  Desc:
**      Use this stored procedure to mark an ArchiveVerify job step or ArchiveStatusCheck as complete
**
**      This is required when the automated processing fails, but you have
**      manually verified that the files are downloadable from MyEMSL
**
**      In particular, use this procedure if the MyEMSL status page shows an error in step 5 or 6,
**      yet the files were manually confirmed to have been successfully uploaded
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   10/03/2013 mem - Initial version
**          07/13/2017 mem - Pass both StatusNumList and StatusURIList to set_myemsl_upload_verified
**          01/07/2023 mem - Use new column names in view
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
(
    @job int,
    @statusNumList varchar(64) = '',        -- Required only if the step tool is ArchiveStatusCheck
    @infoOnly tinyint = 1,
    @message varchar(512)='' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @Job = IsNull(@Job, 0)
    Set @StatusNumList = IsNull(@StatusNumList, '')
    Set @infoOnly = IsNull(@infoOnly, 1)

    Set @message = ''

    If @Job <= 0
    Begin
        Set @message = '@Job must be positive; unable to continue'
        Set @myError = 60000
        Goto Done
    End

    ---------------------------------------------------
    -- Make sure the Job exists and has a failed ArchiveVerify step
    -- or failed ArchiveStatusCheck step
    ---------------------------------------------------

    Declare @DatasetID int = 0
    Declare @Step int = 0
    Declare @Tool varchar(128)
    Declare @State int = 0
    Declare @outputFolderName varchar(128) = ''

    SELECT TOP 1
           @DatasetID = J.Dataset_ID,
           @Step = JS.Step,
           @Tool = JS.Tool,
           @State = JS.State,
           @outputFolderName = JS.Output_Folder_Name
    FROM T_Tasks J
         INNER JOIN T_Task_Steps JS
           ON JS.Job = J.Job
    WHERE J.Job = @Job AND
          JS.Tool IN ('ArchiveVerify', 'ArchiveStatusCheck') AND
          JS.State <> 5
    ORDER BY JS.Step

    If IsNull(@Step, 0) = 0
    Begin
        Set @message = 'Job ' + Convert(varchar(12), @Job) + ' does not have an ArchiveVerify step or ArchiveStatusCheck step'
        Set @myError = 60001
        Goto Done
    End

    If NOT @State IN (2, 6)
    Begin
        Set @message = 'The ' + @Tool + ' step for Job ' + Convert(varchar(12), @Job) + ' is in state ' + Convert(varchar(12), @State) + '; to use this procedure the state must be 2 or 6'
        Set @myError = 60002
        Goto Done
    End

    If @Tool = 'ArchiveStatusCheck' And LTrim(RTrim(@StatusNumList)) = ''
    Begin
        Set @message = '@StatusNumList cannot be empty when the tool is ArchiveStatusCheck'
        Set @myError = 60003
        Goto Done
    End

    ---------------------------------------------------
    -- Perform the update
    ---------------------------------------------------

    If @infoOnly = 1
    Begin
        SELECT Job,
               Step,
               Tool,
               State,
               5 AS NewState,
               'Manually verified that files were successfully uploaded' AS Evaluation_Message
        FROM T_Task_Steps
        WHERE (Job = @job) AND
              (Step = @Step)

    End
    Else
    Begin

        UPDATE T_Task_Steps
        SET State = 5,
            Completion_Code = 0,
            Completion_Message = '',
            Evaluation_Code = 0,
            Evaluation_Message = 'Manually verified that files were successfully uploaded'
        WHERE (Job = @job) AND
              (Step = @Step) AND
              State IN (2, 6)

        Set @myRowCount = @@RowCount

        If @myRowCount = 0
        Begin
            Set @message = 'Update failed; the job step was not in the correct state (or was not found)'
            Set @myError = 60004
            Goto Done
        End
    End

    If @Tool = 'ArchiveVerify'
    Begin
        Declare @MyEMSLStateNew tinyint = 2

        If @infoOnly= 1
            Select 'exec s_update_myemsl_state @datasetID=' + Convert(varchar(12), @datasetID) + ', @outputFolderName=''' + @outputFolderName + ''', @MyEMSLStateNew=' + Convert(varchar(12), @MyEMSLStateNew) AS Command
        Else
            exec s_update_myemsl_state @datasetID, @outputFolderName, @MyEMSLStateNew
    End

    If @Tool = 'ArchiveStatusCheck'
    Begin
        Declare @VerifiedStatusNumTable AS Table(Status_Num int NOT NULL)

        ---------------------------------------------------
        -- Find the Status URIs that correspond to the values in @StatusNumList
        ---------------------------------------------------

        INSERT INTO @VerifiedStatusNumTable (Status_Num)
        SELECT DISTINCT Value
        FROM dbo.parse_delimited_integer_list(@StatusNumList, ',')
        ORDER BY Value

        Declare @StatusURIList varchar(4000)

        SELECT @StatusURIList = Coalesce(@StatusURIList + ', ' + MU.Status_URI, MU.Status_URI)
        FROM V_MyEMSL_Uploads MU
             INNER JOIN @VerifiedStatusNumTable SL
               ON MU.Status_Num = SL.Status_Num

        If @infoOnly = 1
            Select 'exec set_myemsl_upload_verified @datasetID=' +
                   Convert(varchar(12), @datasetID) +
                   ', @StatusNumList=''' + @StatusNumList + '''' +
                   ', @StatusURIList=''' + @StatusURIList + '''' AS Command
        Else
            exec set_myemsl_upload_verified @DatasetID, @StatusNumList, @statusURIList, @ingestStepsCompleted = 0

    End

Done:

    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in SetArchiveVerifyManuallyChecked'

        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)

        Exec post_log_entry 'Error', @message, 'SetArchiveVerifyManuallyChecked'
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[set_myemsl_upload_manually_verified] TO [DDL_Viewer] AS [dbo]
GO
