/****** Object:  StoredProcedure [dbo].[SetCaptureTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetCaptureTaskComplete]
/****************************************************
**
**  Desc:   Sets state of dataset record given by @datasetNum
**          according to given completion code and 
**          adjusts related database entries accordingly.
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   11/04/2002 grk - Initial release
**          08/06/2003 grk - added handling for "Not Ready" state
**          11/13/2003 dac - changed "FTICR" instrument class to "Finnigan_FTICR" following instrument class renaming
**          06/21/2005 grk - added handling "requires_preparation" 
**          09/25/2007 grk - return result from DoDatasetCompletionActions (http://prismtrac.pnl.gov/trac/ticket/537)
**          10/09/2007 grk - limit number of retries (ticket 537)
**          12/16/2007 grk - add completion code '100' for use by capture broker
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          04/04/2012 mem - Added parameter @failureMessage
**          08/19/2015 mem - If @completionCode is 0, now looking for and removing messages of the form "Error while copying \\15TFTICR64\data\"
**          12/16/2017 mem - If @completionCode is 0, now calling CleanupDatasetComments to remove error messages in the comment field
**          06/12/2018 mem - Send @maxLength to AppendToText
**          06/13/2018 mem - Add support for @completionCode 101
**          08/08/2018 mem - Add @completionState 14 (Duplicate Dataset Files)
**    
*****************************************************/
(
    @datasetNum varchar(128),
    @completionCode int = 0,    -- 0=success, 1=failed, 2=not ready, 100=success (capture broker), 101=Duplicate dataset files (capture broker)
    @message varchar(512) output,
    @failureMessage varchar(512) = ''
)
As
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Set @message = ''
    Set @failureMessage = IsNull(@failureMessage, '')
    
    Declare @maxRetries int
    Set @maxRetries = 20
    
    Declare @datasetID int
    Declare @datasetState int
    Declare @completionState int
    Declare @result int
    Declare @instrumentClass varchar(32)
    Declare @doPrep tinyint
    Declare @Comment varchar(512)
    
       ---------------------------------------------------
    -- resolve dataset into instrument class
    ---------------------------------------------------
    --
    SELECT @datasetID = T_Dataset.Dataset_ID,
           @instrumentClass = T_Instrument_Name.IN_class,
           @doPrep = T_Instrument_Class.requires_preparation,
           @Comment = T_Dataset.DS_Comment
    FROM T_Dataset
         INNER JOIN T_Instrument_Name
           ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
         INNER JOIN T_Instrument_Class
           ON T_Instrument_Name.IN_class = T_Instrument_Class.IN_class
    WHERE (Dataset_Num = @datasetNum)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Could not get dataset ID for dataset ' + @datasetNum
        goto done
    End
    
    ---------------------------------------------------
    -- Define @completionState based on @completionCode
    ---------------------------------------------------
    
    If @completionCode = 0
    Begin
        If @doPrep > 0
            Set @completionState = 6 -- received
        Else
            Set @completionState = 3 -- normal completion
    End    
    Else If @completionCode = 1
    Begin
        Set @completionState = 5 -- capture failed
    End
    Else If @completionCode = 2
    Begin
        Set @completionState = 9 -- dataset not ready
    End
    Else If @completionCode = 100
    Begin
        Set @completionState = 3 -- normal completion
    End
    Else If @completionCode = 101
    Begin
        Set @completionState = 14 -- Duplicate Dataset Files
    End

    ---------------------------------------------------
    -- Limit number of retries
    ---------------------------------------------------

    If @completionState = 9
    Begin
        SELECT @result = COUNT(*)
        FROM T_Event_Log
        WHERE (Target_Type = 4) AND
              (Target_State = 1) AND
              (Prev_Target_State = 2 OR
               Prev_Target_State = 5) AND
              (Target_ID = @datasetID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error checking for retry count ' + @datasetNum
            goto done
        End
        --
        If @result > @maxRetries
        Begin
            Set @completionState = 5 -- capture failed
            Set @message = 'Number of capture retries exceeded limit of ' + cast(@maxRetries as varchar(12)) + ' for dataset "' + @datasetNum + '"'
            exec PostLogEntry
                    'Error', 
                    @message, 
                    'SetCaptureTaskComplete'
            Set @message = ''
        End
    End

    ---------------------------------------------------
    -- perform the actions necessary when dataset is complete
    ---------------------------------------------------
    --
    execute @myError = DoDatasetCompletionActions @datasetNum, @completionState, @message output

    ---------------------------------------------------
    -- Update the comment as needed
    ---------------------------------------------------
    --
    Set @Comment = IsNull(@Comment, '')
    
    If @completionState = 3
    Begin
        -- Dataset successfully captured
        -- Remove error messages of the form Error while copying \\15TFTICR64\data\ ...
        
        exec CleanupDatasetComments @DatasetID, @infoonly=0
        
    End
    
    If @completionState = 5 And @failureMessage <> ''
    Begin
        -- Add @failureMessage to the dataset comment (If not yet present)
        Set @Comment = dbo.AppendToText(@Comment, @failureMessage, 0, '; ', 512)    
        
        UPDATE T_Dataset
        SET DS_Comment = @Comment
        WHERE Dataset_ID = @DatasetID
            
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = 'Dataset: ' + @datasetNum
    Exec PostUsageLogEntry 'SetCaptureTaskComplete', @UsageMessage

    If @message <> '' 
    Begin
        RAISERROR (@message, 10, 1)
    End
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[SetCaptureTaskComplete] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetCaptureTaskComplete] TO [Limited_Table_Write] AS [dbo]
GO
