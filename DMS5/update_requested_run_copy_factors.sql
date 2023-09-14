/****** Object:  StoredProcedure [dbo].[update_requested_run_copy_factors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_requested_run_copy_factors]
/****************************************************
**
**  Desc:
**      Copy factors from source requested run to destination requested run
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   02/24/2010
**          09/02/2011 mem - Now calling post_usage_log_entry
**          04/25/2012 mem - Now assuring that @callingUser is not blank
**          11/11/2022 mem - Exclude unnamed factors when querying T_Factor
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/13/2023 mem - Only delete factors for the destination requested run if the source requested run actually has factors
**
*****************************************************/
(
    @srcRequestID INT,
    @destRequestID INT,
    @message varchar(512) OUTPUT,
    @callingUser varchar(128) = ''
)
AS
    SET NOCOUNT ON

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Set @callingUser = IsNull(@callingUser, '(copy factors)')

    -----------------------------------------------------------
    -- Temp table to hold factors being copied
    -----------------------------------------------------------

    CREATE TABLE #TMPF (
        Request INT,
        Factor VARCHAR(128),
        Value VARCHAR(128)
    )

    -----------------------------------------------------------
    -- Populate temp table
    -----------------------------------------------------------

    INSERT INTO #TMPF ( Request, Factor, Value )
    SELECT TargetID AS Request,
           Name AS Factor,
           Value
    FROM T_Factor
    WHERE T_Factor.Type = 'Run_Request' AND
          TargetID = @srcRequestID AND
          LTrim(RTrim(T_Factor.Name)) <> ''
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error populating temp table with source request "' + CONVERT(varchar(12), @srcRequestID) + '"'
        Return 51009
    End

    -----------------------------------------------------------
    -- Get rid of any blank entries from temp table
    -- (shouldn't be any, but let's be cautious)
    -----------------------------------------------------------

    DELETE FROM #TMPF WHERE ISNULL(Value, '') = ''

    -----------------------------------------------------------
    -- Anything to copy?
    -----------------------------------------------------------

    IF NOT EXISTS (SELECT * FROM #TMPF)
    BEGIN
        Set @message = 'Nothing to copy'
        Return 0
    END

    -----------------------------------------------------------
    -- Clean out old factors for @destRequest
    -----------------------------------------------------------

    DELETE FROM T_Factor
    WHERE T_Factor.Type = 'Run_Request' AND TargetID = @destRequestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error removing existing factors for request "' + CONVERT(varchar(12), @destRequestID) + '"'
        Return 51003
    End

    -----------------------------------------------------------
    -- Copy from temp table to factors table for @destRequest
    -----------------------------------------------------------

    INSERT INTO dbo.T_Factor
        ( Type, TargetID, Name, Value )
    SELECT
        'Run_Request' AS Type, @destRequestID AS TargetID, Factor AS Name, Value
    FROM #TMPF
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error copying factors to table for new request "' + CONVERT(varchar(12), @destRequestID) + '"'
        Return 51003
    End

    -----------------------------------------------------------
    -- Convert changed items to XML for logging
    -----------------------------------------------------------

    DECLARE @changeSummary varchar(max) = ''

    SELECT @changeSummary = @changeSummary + '<r i="' + CONVERT(varchar(12), @destRequestID) + '" f="' + Factor + '" v="' + Value + '" />'
    FROM #TMPF

    -----------------------------------------------------------
    -- Log changes
    -----------------------------------------------------------

    INSERT INTO T_Factor_Log (changed_by, changes)
    VALUES (@callingUser, @changeSummary)

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512) = ''
    Set @UsageMessage = 'Source: ' + Convert(varchar(12), @srcRequestID) + '; Target: ' + Convert(varchar(12), @destRequestID)
    Exec post_usage_log_entry 'update_requested_run_copy_factors', @UsageMessage

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_copy_factors] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_copy_factors] TO [Limited_Table_Write] AS [dbo]
GO
