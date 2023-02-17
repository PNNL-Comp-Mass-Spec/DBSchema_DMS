/****** Object:  StoredProcedure [dbo].[local_error_handler] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[local_error_handler]
/****************************************************
**
**  Desc:   This procedure should be called from within a Try...Catch block
**          It will generate an error description and optionally log the error
**          It also returns the Error Severity and Error Number via output parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   11/30/2006
**          01/03/2008 mem - Added parameter @duplicateEntryHoldoffHours
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          03/15/2021 mem - Treat @errorNum as an input/output parameter
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @callingProcName varchar(128)='',           -- Optionally provide the calling procedure name; if not provided then uses ERROR_PROCEDURE()
    @callingProcLocation varchar(128)='',       -- Custom description of the location within the calling procedure within which the error occurred
    @logError tinyint = 0,                      -- Set to 1 to log the error in T_Log_Entries
    @displayError tinyint = 0,                  -- Set to 1 to display the error via SELECT @message
    @logWarningErrorList varchar(512) = '1205', -- Comma separated list of errors that should be treated as warnings if logging to T_Log_Entries
    @errorSeverity int=0 output,
    @errorNum int=0 output,
    @message varchar(512)='' output,            -- Populated with a description of the error
    @duplicateEntryHoldoffHours int = 0         -- Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
)
AS
    Set XACT_ABORT, nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @currentLocation varchar(128) = 'Start'

    Declare @errorNumber int
    Declare @errorState int
    Declare @errorProc varchar(256)
    Declare @errorLine int
    Declare @errorMessage varchar(256)
    Declare @logErrorType varchar(64)

    Begin Try
        Set @currentLocation = 'Validating the inputs'

        -- Validate the inputs
        Set @callingProcName = IsNull(@callingProcName, '')
        Set @callingProcLocation = IsNull(@callingProcLocation, '')
        Set @logError = IsNull(@logError, 0)
        Set @displayError = IsNull(@displayError, 0)
        Set @errorSeverity = 0
        Set @errorNum = IsNull(@errorNum, 0)
        Set @message = ''

        -- Lookup current error information
        Set @currentLocation = 'Populating the error tracking variables'
        SELECT
            @errorSeverity = IsNull(ERROR_SEVERITY(), 0),
            @errorNumber = IsNull(ERROR_NUMBER(), 0),
            @errorState = IsNull(ERROR_STATE(), 0),
            @errorProc = IsNull(ERROR_PROCEDURE(), ''),
            @errorLine = IsNull(ERROR_LINE(), 0),
            @errorMessage = IsNull(ERROR_MESSAGE(), '')

        -- Generate the error description
        Set @currentLocation = 'Generating the error description'
        If Len(IsNull(@errorProc, '')) = 0
        Begin
            -- Update @errorProc using @callingProcName
            If len(@callingProcName) = 0
                Set @callingProcName = 'Unknown Procedure'

            Set @errorProc = @callingProcName
        End

        -- Update @callingProcName using @errorProc (required for calling post_log_entry)
        Set @callingProcName = @errorProc

        If @errorNumber = 0 And Len(@errorMessage) = 0
        Begin
            If @errorNum <> 0
                Set @message = 'Error encountered in ' + @errorProc + '; Error ' + Cast(@errorNum as varchar(12))
            Else
                Set @message = 'No Error for ' + @errorProc
        End
        Else
        Begin
            Set @message = 'Error caught in ' + @errorProc
            If Len(@callingProcLocation) > 0
                Set @message = @message + ' at "' + @callingProcLocation + '"'
            Set @message = @message + ': ' + @errorMessage +
                '; Severity ' + Cast(@errorSeverity as varchar(12)) +
                '; SQL Server Error ' + Cast(@errorNumber as varchar(12)) +
                '; Line ' + Cast(@errorLine as varchar(12))

            If @errorNum = 0
                Set @errorNum = @errorNumber
            Else
                Set @message = @message + '; Local error ' + Cast(@errorNum as varchar(12))
        End

        If @logError <> 0
        Begin
            Set @currentLocation = 'Examining @logWarningErrorList'
            If Exists (SELECT Value FROM dbo.parse_delimited_integer_list(@logWarningErrorList, ',') WHERE Value = @errorNum)
                Set @logErrorType = 'Warning'
            Else
                Set @logErrorType = 'Error'

            Set @currentLocation = 'Calling post_log_entry'
            execute post_log_entry @logErrorType, @message, @callingProcName, @duplicateEntryHoldoffHours
        End

        If @displayError <> 0
            SELECT @message as Error_Description

    End Try
    Begin Catch
        Set @message = 'Error ' + @currentLocation + ' in local_error_handler: ' + IsNull(ERROR_MESSAGE(), '?') + '; Error ' + Cast(IsNull(ERROR_NUMBER(), 0) as varchar(12))
        Set @myError = ERROR_NUMBER()
        SELECT @message as Error_Description
        Print @message

        Declare @postedBy varchar(128) = 'local_error_handler (' + @callingProcName + ')'
        Exec post_log_entry 'Error', @message, @postedBy
    End Catch

    RETURN @myError

GO
GRANT EXECUTE ON [dbo].[local_error_handler] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[local_error_handler] TO [Mgr_Config_Admin] AS [dbo]
GO
