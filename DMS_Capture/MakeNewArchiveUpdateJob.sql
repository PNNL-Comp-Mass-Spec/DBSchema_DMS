/****** Object:  StoredProcedure [dbo].[MakeNewArchiveUpdateJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MakeNewArchiveUpdateJob]
/****************************************************
**
**  Desc: 
**  Creates a new archive update job for the specified dataset and results folder
**    
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/07/2010 mem - Initial version
**          09/08/2010 mem - Added parameter @AllowBlankResultsFolder
**          05/31/2013 mem - Added parameter @PushDatasetToMyEMSL
**          07/11/2013 mem - Added parameter @PushDatasetRecursive
**          10/24/2014 mem - Changed priority to 2 when @ResultsFolderName = ''
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/28/2017 mem - Update status messages
**          03/06/2018 mem - Also look for archiveupdate jobs on hold when checking for an existing archive update task
**    
*****************************************************/
(
    @DatasetName varchar(128),
    @ResultsFolderName varchar(128) = '',
    @AllowBlankResultsFolder tinyint = 0,       -- Set to 1 if you need to update the dataset file; the downside is that the archive update will involve a byte-to-byte comparison of all data in both the dataset folder and all subfolders
    @PushDatasetToMyEMSL tinyint = 0,           -- Set to 1 to push the dataset to MyEMSL instead of updating the data at \\aurora.emsl.pnl.gov\archive\dmsarch
    @PushDatasetRecursive tinyint = 0,          -- Set to 1 to recursively push a folder and all subfolders into MyEMSL
    @infoOnly tinyint = 0,                      -- 0 To perform the update, 1 preview job that would be created
    @message varchar(512)='' output
)
As
    Set nocount on
    
    declare @myError int = 0
    declare @myRowCount int = 0

    Declare @DatasetID int
    Declare @JobID int
    Declare @Script varchar(64)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'MakeNewArchiveUpdateJob', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @ResultsFolderName = IsNull(@ResultsFolderName, '') 
    Set @AllowBlankResultsFolder = IsNull(@AllowBlankResultsFolder, 0)
    Set @PushDatasetToMyEMSL = IsNull(@PushDatasetToMyEMSL, 0)
    Set @PushDatasetRecursive = IsNull(@PushDatasetRecursive, 0)
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''
        
    If @DatasetName Is Null
    Begin
        Set @message = 'Dataset name not defined'
        Set @myError = 50000
        Goto Done
    End
        
    If @ResultsFolderName = '' And @AllowBlankResultsFolder = 0
    Begin
        Set @message = 'Results folder name is blank; to update the Dataset file and all subfolders, set @AllowBlankResultsFolder to 1'
        Set @myError = 50001
        Goto Done
    End

    ---------------------------------------------------
    -- Validate this dataset and determine its Dataset_ID
    ---------------------------------------------------
    
    Set @DatasetID = 0
    
    SELECT @DatasetID = Dataset_ID
    FROM V_DMS_Get_Dataset_Info
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
    -- Make sure a pending archive update job doesn't already exist
    ---------------------------------------------------
    --
    Set @JobID = 0
    
    SELECT @JobID = Job
    FROM T_Jobs
    WHERE (Script = 'ArchiveUpdate') AND
          (Dataset_ID = @DatasetID) AND
          (ISNULL(Results_Folder_Name, '') = @ResultsFolderName) AND
          (State In (1,2,4,7))

    If @JobID > 0 
    Begin
        if @ResultsFolderName = ''
            Set @message = 'Existing pending job already exists for ' + @DatasetName + ' and subfolder ' + @ResultsFolderName + '; job ' + Convert(varchar(12), @JobID)
        else
            Set @message = 'Existing pending job already exists for ' + @DatasetName + '; job ' + Convert(varchar(12), @JobID)
        Set @myError = 0
        Goto Done
    End

    If @PushDatasetToMyEMSL <> 0
    Begin
        If @PushDatasetRecursive <> 0
            Set @Script = 'MyEMSLDatasetPushRecursive'
        Else
            Set @Script = 'MyEMSLDatasetPush'
    End
    Else
        Set @Script = 'ArchiveUpdate'
    
    ---------------------------------------------------
    -- create new Archive Update job for specified dataset
    ---------------------------------------------------
    --
    If @infoOnly <> 0
    Begin
        SELECT
            @Script AS Script,
            @DatasetName AS Dataset,
            @DatasetID AS Dataset_ID,
            @ResultsFolderName AS Results_Folder_Name,
            'Manually created using MakeNewArchiveUpdateJob' AS Comment
    End
    Else
    Begin
        
        INSERT INTO T_Jobs( Script,
                            Dataset,
                            Dataset_ID,
                            Results_Folder_Name,
                            [Comment],
                            Priority )
        SELECT @Script AS Script,
               @DatasetName AS Dataset,
               @DatasetID AS Dataset_ID,
               @ResultsFolderName AS Results_Folder_Name,
               'Created manually using MakeNewArchiveUpdateJob' AS [Comment],
               CASE
                   WHEN @ResultsFolderName = '' THEN 2
                   ELSE 3
               END AS Priority
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error trying to add new Archive Update job'
            goto Done
        end    
        
        Set @JobID = SCOPE_IDENTITY()
        
        Set @message = 'Created Job ' + Convert(varchar(12), @JobID) + ' for dataset ' + @DatasetName
        
        if @ResultsFolderName = ''
            Set @message = @message + ' and all subfolders'
        else
            Set @message = @message + ' and results folder ' + @ResultsFolderName

    End
    
    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    
    If @message <> ''
        Print @message

GO
GRANT VIEW DEFINITION ON [dbo].[MakeNewArchiveUpdateJob] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[MakeNewArchiveUpdateJob] TO [DMS_SP_User] AS [dbo]
GO
