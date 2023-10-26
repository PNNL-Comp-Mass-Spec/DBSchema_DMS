/****** Object:  StoredProcedure [dbo].[request_dataset_create_task] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[request_dataset_create_task]
/****************************************************
**
**  Desc:
**      Returns first available dataset creation task in T_Dataset_Create_Queue
**
**  Arguments:
**    @processorName        Name of the processor requesting a dataset creation task
**    @infoOnly             When 1, preview the dataset creation task that would be returned
**    @taskCountToPreview   The number of dataset creation tasks to preview when @infoOnly >= 1
**    @entryID              Output: Entry_ID assigned; 0 if no creation tasks are available
**    @parameters           Output: Dataset metadata (as XML)
**    @message              Output message
**
**  Return values:
**      0 for success, non-zero if an error
**
**  Example XML parameters returned in @parameters:
**      <root>
**        <dataset>SW_Test_Dataset_2023-10-24</dataset>
**        <experiment>QC_Mam_23_01</experiment>
**        <instrument>Exploris03</instrument>
**        <separation_type>LC-Dionex-Formic_100min</separation_type>
**        <lc_cart>Birch</lc_cart>
**        <lc_cart_config>Birch_BEH-1pt7</lc_cart_config>
**        <lc_column>WBEH-CoAnn-23-09-02</lc_column>
**        <wellplate></wellplate>
**        <well></well>
**        <dataset_type>HMS-HCD-HMSn</dataset_type>
**        <operator_username>D3L243</operator_username>
**        <ds_creator_username>D3L243</ds_creator_username>
**        <comment>Test comment</comment>
**        <interest_rating>Released</interest_rating>
**        <request>0</request>
**        <work_package>none</work_package>
**        <eus_usage_type>USER_ONSITE</eus_usage_type>
**        <eus_proposal_id>60328</eus_proposal_id>
**        <eus_users>35357</eus_users>
**        <capture_share_name></capture_share_name>
**        <capture_subdirectory></capture_subdirectory>
**        <command>add</command>
**      </root>
**
**  Auth:   mem
**          10/25/2023 mem - Initial version
**
*****************************************************/
(
    @processorName varchar(128),
    @infoOnly tinyint = 0,
    @taskCountToPreview int = 10,
    @entryID int = 0 output,
    @parameters varchar(4000) = '' output,
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @taskAssigned tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0

    Exec @authorized = verify_sp_authorized 'request_dataset_create_task', @raiseError = 1

    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs; clear the outputs
    ---------------------------------------------------

    Set @processorName = IsNull(@processorName, '')
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @taskCountToPreview = IsNull(@taskCountToPreview, 10)
    Set @entryID = 0
    Set @parameters = ''
    Set @message = ''

    ---------------------------------------------------
    -- Start a new transaction
    ---------------------------------------------------

    Declare @transName varchar(32) = 'RequestNewDatasetCreationTask'
    Begin transaction @transName

    ---------------------------------------------------
    -- Get first available dataset creation task from T_Dataset_Create_Queue
    ---------------------------------------------------

    SELECT TOP 1 @entryID = Entry_ID
    FROM T_Dataset_Create_Queue
    WHERE State_ID = 1
    ORDER BY Entry_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        rollback transaction @transName
        Set @message = 'Error searching for new dataset creation task'
        Return @myError
    End

    If @myRowCount > 0
    Begin
        Set @taskAssigned = 1
    End

    ---------------------------------------------------
    -- If a new dataset creation task was found (@entryID <> 0) and if @infoOnly = 0,
    -- update the state to 2=In Progress
    ---------------------------------------------------

    If @taskAssigned = 1 AND @infoOnly = 0
    Begin
        UPDATE T_Dataset_Create_Queue
        SET State_ID = 2,
            Processor = @ProcessorName,
            Start = GetDate(),
            Finish = Null
        WHERE Entry_ID = @entryID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            rollback transaction @transName
            set @message = 'Error setting state to 2 in T_Dataset_Create_Queue'
            Return @myError
        End
    End

    -- Update was successful
    Commit transaction @transName

    If @taskAssigned = 1
    Begin

        ---------------------------------------------------
        -- A new dataset creation task was assigned; return parameters in XML format
        ---------------------------------------------------
        --
        Set @parameters = (
                SELECT dataset,
                       experiment,
                       instrument,
                       separation_type,
                       lc_cart,
                       lc_cart_config,
                       lc_column,
                       wellplate,
                       well,
                       dataset_type,
                       operator_username,
                       ds_creator_username,
                       comment,
                       interest_rating,
                       request,
                       work_package,
                       eus_usage_type,
                       eus_proposal_id,
                       eus_users,
                       capture_share_name,
                       capture_subdirectory,
                       command
                FROM T_Dataset_Create_Queue AS [root]
                WHERE Entry_ID = @entryID
                FOR XML AUTO, ELEMENTS
            )

        If @infoOnly <> 0 And Len(@message) = 0
        Begin
            Set @message = 'Dataset creation task ' + Convert(varchar(12), @entryID) + ' would be assigned to ' + @processorName
        End
    End
    Else
    Begin
        ---------------------------------------------------
        -- A new creation task was not found; update @message
        ---------------------------------------------------
        --
        Set @message = 'No available dataset creation tasks'
    End

    ---------------------------------------------------
    -- Dump candidate tasks if in infoOnly mode
    ---------------------------------------------------
    --
    If @infoOnly <> 0
    Begin
        -- Preview the next @taskCountToPreview available dataset creation tasks

        SELECT TOP ( @taskCountToPreview )
               Entry_ID,
               State_ID,
               Dataset,
               Experiment,
               Instrument,
               Separation_Type,
               LC_Cart,
               LC_Cart_Config,
               LC_Column,
               Wellplate,
               Well,
               Dataset_Type,
               Operator_Username,
               DS_Creator_Username,
               Comment,
               Interest_Rating,
               Request,
               Work_Package,
               EUS_Usage_Type,
               EUS_Proposal_ID,
               EUS_Users,
               Capture_Share_Name,
               Capture_Subdirectory
        FROM T_Dataset_Create_Queue
        WHERE State_ID = 1
        ORDER BY Entry_ID
    End

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[request_dataset_create_task] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[request_dataset_create_task] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[request_dataset_create_task] TO [svc-dms] AS [dbo]
GO
