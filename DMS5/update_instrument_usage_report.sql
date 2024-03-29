/****** Object:  StoredProcedure [dbo].[update_instrument_usage_report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_instrument_usage_report]
/****************************************************
**
**  Desc:
**      Update requested EMSL instument usage table from input XML list
**
**  @factorList will look like this
**
**      <id type="Seq" />
**      <r i="1939" f="Comment" v="..." />
**      <r i="1941" f="Comment" v="..." />
**      <r i="2058" f="Proposal" v="..." />
**      <r i="1941" f="Proposal" v="..." />
**
**      In the XML:
**        "i" specifies the sequence ID in table t_emsl_instrument_usage_report
**        "f" is the field to update: 'Proposal', 'Operator', 'Comment', 'Users', or 'Usage' (operator is EUS user ID of the instrument operator)
**        "v" is the value to store
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   10/07/2012
**          10/09/2012 grk - Enabled 10 day edit cutoff and update_dataset_interval for 'reload'
**          11/21/2012 mem - Extended cutoff for 'reload' to be 45 days instead of 10 days
**          01/09/2013 mem - Extended cutoff for 'reload' to be 90 days instead of 45 days
**          04/03/2013 grk - Made Usage editable
**          04/04/2013 grk - Clearing Usage on reload
**          02/23/2016 mem - Add set XACT_ABORT on
**          11/08/2016 mem - Use get_user_login_without_domain to obtain the user's network login
**          11/10/2016 mem - Pass '' to get_user_login_without_domain
**          04/11/2017 mem - Now using fields DMS_Inst_ID and Usage_Type in T_EMSL_Instrument_Usage_Report
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/03/2019 mem - Pass 0 to update_emsl_instrument_usage_report for @eusInstrumentID
**          09/10/2019 mem - Extended cutoff for 'update' to be 365 days instead of 90 days
**                         - Changed the cutoff for reload to 60 days
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**          03/02/2024 mem - Trim leading and trailing whitespace from Field and Value text parsed from the XML
**                         - Allow @year and @month to be undefined if @operation is 'update'
**
*****************************************************/
(
    @factorList text,
    @operation varchar(32),        -- 'update', 'refresh', 'reload'
    @year varchar(12),
    @month varchar(12),
    @instrument varchar(128),
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on
    Set CONCAT_NULL_YIELDS_NULL ON
    Set ANSI_PADDING ON

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(512)

    Declare @startOfMonth datetime
    Declare @startOfNextMonth datetime
    Declare @endOfMonth datetime
    Declare @lockDateReload datetime
    Declare @lockDateUpdate datetime

    Declare @xml AS xml

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_instrument_usage_report', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate inputs
    ---------------------------------------------------

    If IsNull(@callingUser, '') = ''
        Set @callingUser = dbo.get_user_login_without_domain('')

    Declare @instrumentID int = 0

    Set @instrument = IsNull(@instrument, '')

    If @Instrument <> ''
    Begin
        SELECT @instrumentID = Instrument_ID
        FROM T_Instrument_Name
        WHERE IN_name = @Instrument
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @instrumentID = 0
        Begin
            RAISERROR ('Instrument not found: "%s"', 11, 4, @Instrument)
        End
    End

    Set @operation = Ltrim(Rtrim(IsNull(@operation, '')))

    If Len(@operation) = 0
    Begin
        RAISERROR ('Operation must be specified', 11, 4)
    End

    Set @month = Ltrim(Rtrim(IsNull(@month, '')))
    Set @year  = Ltrim(Rtrim(IsNull(@year, '')))

    If @operation = 'update'
    Begin
        -- @month and @year are effectively ignored when @operation is 'update'
        -- However, make sure that they are defined so that @startOfMonth can be initialized (even though it also is not used when @operation is 'update')

        If Len(@month) = 0
        Begin
            Set @month = Cast(month(current_timestamp) As varchar(12))
        End

        If Len(@year) = 0
        Begin
            Set @year = Cast(year(current_timestamp) As varchar(12))
        End
    End
    Else
    Begin
        If Len(@month) = 0
        Begin
            RAISERROR ('Month must be specified', 11, 4)
        End

        If Len(@year) = 0
        Begin
            RAISERROR ('Year must be specified', 11, 4)
        End
    End

    Declare @monthValue int = Try_Cast(@month As int)
    Declare @yearValue int  = Try_Cast(@year As int)

    If @monthValue Is Null
    Begin
        RAISERROR ('Month must be an integer, not: "%s"', 11, 4, @month)
    End

    If @yearValue Is Null
    Begin
        RAISERROR ('Year must be an integer, not: "%s"', 11, 4, @year)
    End

    -- Uncomment to debug
    -- Declare @debugMessage varchar(1024) = 'Operation: ' + @operation + '; Instrument: ' + @instrument + '; ' + @year + '-' + @month + '; ' + Cast(@factorList As varchar(1024))
    -- Exec post_log_entry 'Debug', @debugMessage, 'update_instrument_usage_report'

    -----------------------------------------------------------
    -- Copy @factorList text variable into the XML variable
    -----------------------------------------------------------
    Set @xml = @factorList

    ---------------------------------------------------
    ---------------------------------------------------
    BEGIN TRY

        ---------------------------------------------------
        -- Define boundary dates
        ---------------------------------------------------

        Set @startOfMonth     = @month + '/1/' + @year                  -- Beginning of the month that we are updating
        Set @startOfNextMonth = DATEADD(MONTH, 1, @startOfMonth)        -- Beginning of the next month after @startOfMonth
        Set @endOfMonth       = DATEADD(MINUTE, -1, @startOfNextMonth)  -- End of the month that we are editing
        Set @lockDateReload   = DATEADD(DAY, 60, @startOfNextMonth)     -- Date threshold, afterwhich users can no longer reload this month's data
        Set @lockDateUpdate   = DATEADD(DAY, 365, @startOfNextMonth)    -- Date threshold, afterwhich users can no longer update this month's data

        If @operation In ('update') And GETDATE() > @lockDateUpdate
            RAISERROR ('Changes are not allowed to instrument usage data over 365 days old', 11, 13)

        If Not @operation In ('update') And GETDATE() > @lockDateReload
            RAISERROR ('Instrument usage data over 60 days old cannot be reloaded or refreshed', 11, 13)

        -----------------------------------------------------------
        -- Foundational actions for various operations
        -----------------------------------------------------------

        If @operation in ('update')
        Begin --<a>

            -----------------------------------------------------------
            -- Temp table to hold update items
            -----------------------------------------------------------
            --
            CREATE TABLE #TMP (
                Identifier int null,
                Field varchar(128) null,
                Value varchar(128) null,
            )

            -----------------------------------------------------------
            -- Populate temp table with new parameters
            -----------------------------------------------------------
            --
            INSERT INTO #TMP (Identifier, Field, Value)
            SELECT
                xmlNode.value('@i', 'int') Identifier,
                LTrim(RTrim(xmlNode.value('@f', 'nvarchar(256)'))) Field,
                LTrim(RTrim(xmlNode.value('@v', 'nvarchar(256)'))) Value
            FROM @xml.nodes('//r') AS R(xmlNode)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
                RAISERROR ('Error trying to convert list', 11, 1)

            -----------------------------------------------------------
            -- Make sure changed fields are allowed
            -----------------------------------------------------------

            Declare @badFields varchar(4096) = ''

            SELECT DISTINCT @badFields = @badFields + Field + ','
            FROM #TMP
            WHERE NOT Field IN ('Proposal', 'Operator', 'Comment', 'Users', 'Usage')
            --
            If @badFields <> ''
                RAISERROR ('The following field(s) are not editable: %s', 11, 27, @badFields)

        End --<a>

        If @operation in ('reload', 'refresh')
        Begin--<b>
            -----------------------------------------------------------
            -- Validation
            -----------------------------------------------------------

            If @operation = 'reload' AND ISNULL(@instrument, '') = ''
                RAISERROR ('An instrument must be specified for the reload operation', 11, 10)

            If ISNULL(@year, '') = '' OR ISNULL(@month, '') = ''
                RAISERROR ('A year and month must be specified for this operation', 11, 11)

            If ISNULL(@instrument, '') = ''
            Begin
                ---------------------------------------------------
                -- Get list of EMSL instruments
                ---------------------------------------------------
                --
                CREATE TABLE #Tmp_Instruments (
                    Seq int IDENTITY(1,1) NOT NULL,
                    Instrument varchar(65)
                )
                INSERT INTO #Tmp_Instruments (Instrument)
                SELECT [Name]
                FROM V_Instrument_Tracked
                WHERE ISNULL(EUS_Primary_Instrument, '') = 'Y'
            End

        End --<b>

        If @operation = 'update'
        Begin
            UPDATE T_EMSL_Instrument_Usage_Report
            SET Comment = #TMP.Value
            FROM T_EMSL_Instrument_Usage_Report
                 INNER JOIN #TMP ON Seq = Identifier
            WHERE Field = 'Comment'

            UPDATE T_EMSL_Instrument_Usage_Report
            SET Proposal = #TMP.Value
            FROM T_EMSL_Instrument_Usage_Report
                 INNER JOIN #TMP ON Seq = Identifier
            WHERE Field = 'Proposal'

            UPDATE T_EMSL_Instrument_Usage_Report
            SET Operator = Try_Convert(int, #TMP.Value)
            FROM T_EMSL_Instrument_Usage_Report
                 INNER JOIN #TMP ON Seq = Identifier
            WHERE Field = 'Operator'

            UPDATE T_EMSL_Instrument_Usage_Report
            SET Users = #TMP.Value
            FROM T_EMSL_Instrument_Usage_Report
                 INNER JOIN #TMP ON Seq = Identifier
            WHERE Field = 'Users'

            UPDATE T_EMSL_Instrument_Usage_Report
            SET Usage_Type = InstUsageType.ID
            FROM T_EMSL_Instrument_Usage_Report InstUsage
                 INNER JOIN #TMP
                   ON InstUsage.Seq = #TMP.Identifier
                 INNER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
                   ON #TMP.VALUE = InstUsageType.Name
            WHERE Field = 'Usage'

            UPDATE T_EMSL_Instrument_Usage_Report
            SET Updated = GETDATE(),
                UpdatedBy = @callingUser
            FROM T_EMSL_Instrument_Usage_Report
            INNER JOIN #TMP ON Seq = Identifier

        End

        If @operation = 'reload'
        Begin
            UPDATE T_EMSL_Instrument_Usage_Report
            SET
                Usage_Type = Null,
                Proposal = '',
                Users = '',
                Operator = Null,
                Comment = ''
            WHERE [Year] = @year AND
                  [Month] = @month AND
                  (@instrument = '' OR DMS_Inst_ID = @instrumentID)

            EXEC update_dataset_interval @instrument, @startOfMonth, @endOfMonth, @message output

            Set @operation = 'refresh'
        End

        If @operation = 'refresh'
        Begin
            If Len(ISNULL(@instrument, '')) > 0
            Begin
                EXEC @myError = update_emsl_instrument_usage_report @instrument, 0, @endOfMonth, @msg output
                If(@myError <> 0)
                    RAISERROR (@msg, 11, 6)
            End
            ELSE
            Begin --<m>
                Declare @inst varchar(64)
                Declare @index int = 0
                Declare @done TINYINT = 0

                WHILE @done = 0
                Begin --<x>
                    Set @inst = NULL
                    SELECT TOP 1 @inst = Instrument
                    FROM #Tmp_Instruments
                    WHERE Seq > @index

                    Set @index = @index + 1

                    If @inst IS NULL
                    Begin
                        Set @done = 1
                    End
                    ELSE
                    Begin --<y>
                        EXEC update_emsl_instrument_usage_report @inst, 0, @endOfMonth, @msg output
                    End  --<y>
                End --<x>
            End --<m>
        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_instrument_usage_report] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_instrument_usage_report] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_instrument_usage_report] TO [DMS2_SP_User] AS [dbo]
GO
