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
**      The procedure marks the dataset state as Inactive,
**      changes the rating to -1 = No Data (Blank/bad),
**      and makes sure a dataset archive entry exists
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
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**
*****************************************************/
(
    @datasetNameOrID varchar(255),
    @comment varchar(255) = 'Bad .raw file',        -- If space, period, semicolon, comma, exclamation mark or caret, will not change the dataset comment
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
AS
    Declare @myError int
    EXEC @myError = HandleDatasetCaptureValidationFailure @datasetNameOrID, @comment, @infoOnly, @message output
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[handle_dataset_capture_validation_failure] TO [DDL_Viewer] AS [dbo]
GO
