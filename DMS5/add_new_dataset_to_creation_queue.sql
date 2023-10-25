/****** Object:  StoredProcedure [dbo].[add_new_dataset_to_creation_queue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_new_dataset_to_creation_queue]
/****************************************************
**
**  Desc:
**      Adds a new dataset to T_Dataset_Create_Queue
**
**      The Data Import Manager looks for entries with state 1 in T_Dataset_Create_Queue
**      For each one, it validates that the dataset file(s) are available, then creates the dataset in DMS
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   10/24/2023 mem - Initial version
**
*****************************************************/
(
    @datasetName        varchar(128),
    @experimentName     varchar(64),
    @instrumentName     varchar(64),
    @separationType     varchar(64),
    @lcCartName         varchar(128),
    @lcCartConfig       varchar(128) = '',
    @lcColumnName       varchar(64),
    @wellplateName      varchar(64),
    @wellNumber         varchar(64),
    @datasetType        varchar(20),        -- Corresponds to @msType in add_update_dataset
    @operatorUsername   varchar(64),
    @dsCreatorUsername  varchar(64),
    @comment            varchar(512),
    @interestRating     varchar(32),        -- Corresponds to @rating in add_update_dataset
    @requestID          int,
    @workPackage        varchar(50) = '',
    @eusUsageType       varchar(50) = '',
    @eusProposalID      varchar(10) = '',
    @eusUsersList       varchar(1024) = '',
    @captureSubfolder   varchar(255) = '',
    @message            varchar(512) output
)
AS
    Set XACT_ABORT, nocount on

    Declare @captureShareName varchar(255)
    Declare @captureSubdirectory varchar(255)
    Declare @charPos int

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @datasetName      = LTrim(RTrim(Coalesce(@datasetName, '')))
    Set @experimentName   = LTrim(RTrim(Coalesce(@experimentName, '')))
    Set @instrumentName   = LTrim(RTrim(Coalesce(@instrumentName, '')))
    Set @captureSubfolder = LTrim(RTrim(Coalesce(@captureSubfolder, '')))
    Set @lcCartConfig     = LTrim(RTrim(Coalesce(@lcCartConfig, '')))
    Set @requestID        = Coalesce(@requestID, 0)

    If @datasetName = ''
    Begin
        Set @myError = 70
        Set @message = 'Dataset name is not defined, cannot add to dataset creation queue'
        Return @myError
    End

    If @experimentName = ''
    Begin
        Set @myError = 71
        Set @message = 'Experiment name is not defined, cannot add to dataset creation queue'
        Return @myError
    End

    If @instrumentName = ''
    Begin
        Set @myError = 72
        Set @message = 'Instrument name is not defined, cannot add to dataset creation queue'
        Return @myError
    End

    ---------------------------------------------------
    -- Determine the capture share name and subdirectory
    ---------------------------------------------------

    If @captureSubfolder Like '..\%\%'
    Begin
        -- Capture subfolder is of the form '..\ProteomicsData2\DatasetName'
        -- Change _captureShareName to 'ProteomicsData2' and _captureSubdirectory to 'DatasetName'
        -- Example dataset: https://dms2.pnl.gov/datasetid/show/1129444

        -- Find the second backslash
        Set @charPos = CharIndex('\', @captureSubfolder, 4)

        If @charPos > 4
        Begin
            Set @captureShareName    = Substring(@captureSubfolder, 4, @charPos - 4)
            Set @captureSubdirectory = Substring(@captureSubfolder, @charPos + 1, 250)
        End
        Else
        Begin
            Set @captureShareName    = ''
            Set @captureSubdirectory = @captureSubfolder
        End
    End
    Else
    Begin
        Set @captureShareName    = ''
        Set @captureSubdirectory = @captureSubfolder
    End

    ---------------------------------------------------
    -- If the new dataset already exists in the queue table with state 1, change the state to 5 (Inactive)
    ---------------------------------------------------

    UPDATE T_Dataset_Create_Queue
    SET State_ID = 5
    WHERE Dataset = @datasetName AND State_ID = 1

    INSERT INTO T_Dataset_Create_Queue (
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
        Capture_Subdirectory,
        Command
    )
    VALUES (1,           -- State=New
            @datasetName,
            @experimentName,
            @instrumentName,
            @separationType,
            @lcCartName,
            @lcCartConfig,
            @lcColumnName,
            @wellplateName,
            @wellNumber,
            @datasetType,
            @operatorUsername,
            @dsCreatorUsername,
            @comment,
            @interestRating,
            @requestID,
            @workPackage,
            @eusUsageType,
            @eusProposalID,
            @eusUsersList,
            @captureShareName,
            @captureSubdirectory,
            'add')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @myError = 76
        Set @message = 'Error adding dataset ' + @datasetName + '; @myError = ' + Cast(@myError AS varchar(12))

        Exec post_log_entry 'Error', @message, 'add_new_dataset_to_creation_queue'
        Return @myError
    End

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[add_new_dataset_to_creation_queue] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_new_dataset_to_creation_queue] TO [Limited_Table_Write] AS [dbo]
GO
