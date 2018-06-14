/****** Object:  StoredProcedure [dbo].[HandleDatasetCaptureValidationFailure] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HandleDatasetCaptureValidationFailure]
/****************************************************
**
**  Desc:   This procedure can be used with datasets that
**          are successfully captured but fail the dataset integrity check
**          (.Raw file too small, expected files missing, etc).
**
**          The procedure marks the dataset state as Inactive, 
**          changes the rating to -1 = No Data (Blank/bad),
**          and makes sure a dataset archive entry exists
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   04/28/2011 mem - Initial version
**          10/29/2014 mem - Now allowing @comment to contain a single punctuation mark, which means the comment should not be updated
**          11/25/2014 mem - Now using dbo.AppendToText() to avoid appending duplicate text
**          02/27/2015 mem - Add space after semicolon when calling AppendToText
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          05/22/2017 mem - Change @comment to '' if 'Bad .raw file' yet the dataset comment contains 'Cannot convert .D to .UIMF'
**          06/12/2018 mem - Send @maxLength to AppendToText
**
*****************************************************/
(
    @datasetNameOrID varchar(255),
    @comment varchar(255) = 'Bad .raw file',        -- If space, period, semicolon, comma, exclamation mark or caret, will not change the dataset comment
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
As
    Set nocount on

    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0
    
    Declare @datasetID int
    Declare @datasetName varchar(255)
    Declare @existingComment varchar(512)
    
    Set @datasetName = ''
    Set @datasetID = 0
    Set @existingComment = ''
    
    ----------------------------------------
    -- Validate the inputs
    ----------------------------------------

    Set @datasetNameOrID = IsNull(@datasetNameOrID, '')
    Set @comment = IsNull(@comment, '')
    Set @message = ''
    
    If @comment = ''
        Set @comment = 'Bad dataset'
    
    -- Treat the following characters as meaning "do not update the comment"
    If @comment in (' ', '.', ';', ',', '!', '^')
        Set @comment = ''
    
    Set @datasetID = IsNull(Try_Convert(int, @datasetNameOrID), 0)
    If @datasetID <> 0
    Begin
        ----------------------------------------
        -- Lookup the Dataset Name
        ----------------------------------------
        
        Set @datasetID = Convert(int, @datasetNameOrID)
        
        SELECT @datasetName = Dataset_Num, 
               @existingComment = DS_Comment
        FROM T_Dataset
        WHERE (Dataset_ID = @datasetID)
        
        If @datasetName = ''
        Begin
            Set @message = 'Dataset ID not found: ' + @datasetNameOrID
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
                
        SELECT @datasetID = Dataset_ID,
               @existingComment = DS_Comment
        FROM T_Dataset
        WHERE (Dataset_Num = @datasetName)
        
        If @datasetName = ''
        Begin
            Set @message = 'Dataset not found: ' + @datasetName
            Set @myError = 50001
            Print @message
        End
    End
    
    If @myError = 0
    Begin
        If @comment = 'Bad .raw file' AND @existingComment LIKE '%Cannot convert .D to .UIMF%'
            Set @comment = ''
        
        If @infoOnly <> 0
        Begin
            SELECT 'Mark dataset as bad: ' + @comment as Message, *
            FROM T_Dataset
            WHERE Dataset_ID = @datasetID
        End
        Else
        Begin
                
            UPDATE T_Dataset
            SET DS_comment = dbo.AppendToText(DS_Comment, @comment, 0, '; ', 512),
                DS_state_ID = 4,
                DS_rating = -1
            WHERE Dataset_ID = @datasetID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @message = 'Unable to update dataset in T_Dataset: ' + @datasetName
                Set @myError = 50002
                Print @message
            End
            Else
            Begin
                -- Also update T_Dataset_Archive
                Exec AddArchiveDataset @datasetID
                
                Set @message = 'Marked dataset as bad: ' + @datasetName
                Print @message
                
            End
        End
    
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[HandleDatasetCaptureValidationFailure] TO [DDL_Viewer] AS [dbo]
GO
