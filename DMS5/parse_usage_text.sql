/****** Object:  StoredProcedure [dbo].[parse_usage_text] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[parse_usage_text]
/****************************************************
**
**  Desc:
**      Parse EMSL usage text in a comment to extract usage values and generate XML
**
**      Example usage values that can appear in @comment (note that each key can only be present once, so you cannot specify multiple proposals in a single @comment)
**        'UserRemote[100%], Proposal[49361], PropUser[50082]'
**        'UserOnsite[100%], Proposal[49361], PropUser[50082] Extra info about the interval'
**        'Remote[100%], Proposal[49361], PropUser[50082]'
**        'Onsite[100%], Proposal[49361], PropUser[50082]'
**        'CapDev[10%], UserOnsite[90%], Proposal[49361], PropUser[50082]'
**
**      Legacy examples:
**        'User[100%], Proposal[49361], PropUser[50082]'
**        'CapDev[10%], User[90%], Proposal[49361], PropUser[50082]'
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/02/2012
**          03/11/2012 grk - added OtherNotAvailable
**          03/11/2012 grk - return commment without usage text
**          09/18/2012 grk - added 'Operator' and 'PropUser' keywords
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**                         - Add parameters @seq, @showDebug, and @validateTotal
**          04/28/2017 mem - Disable logging to T_Log_Entries for Raiserror messages
**          08/02/2017 mem - Add output parameter @invalidUsage
**                         - Use Try_Convert when parsing UsageValue
**                         - Rename temp tables
**                         - Additional comment cleanup logic
**          08/29/2017 mem - Direct users to http://prismwiki.pnl.gov/wiki/Long_Interval_Notes
**          05/25/2021 mem - Add support for usage types 'UserOnsite' and 'UserRemote'
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          06/15/2023 mem - Add support for usage type 'ResourceOwner'
**
*****************************************************/
(
    @comment varchar(4096) output,      -- Usage (input / output); see above for examples.  Usage keys and values will be removed from this string
    @usageXML XML output,               -- Usage information, as XML.  Will be Null if @validateTotal is 1 and the percentages do not sum to 100%
    @message varchar(512) output,
    @seq int = -1,
    @showDebug tinyint = 0,
    @validateTotal tinyint = 1,         -- Raise an error (and do not update @comment or @usageXML) if the sum of the percentages is not 100
    @invalidUsage tinyint = 0 output    -- Set to 1 if the usage text in @comment cannot be parsed; update_run_op_log uses this to skip invalid entries (value passed back via add_update_run_interval)
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @comment = Ltrim(Rtrim(IsNull(@comment, '')))
    Set @message = ''
    Set @seq = IsNull(@seq, -1)
    Set @showDebug = IsNull(@showDebug, 0)
    Set @validateTotal = IsNull(@validateTotal, 1)
    Set @invalidUsage = 0

    If @showDebug > 0
        Print 'Initial comment for ID ' + cast(@seq as varchar(9)) + ': ' + @comment

    Declare @logErrors tinyint = 1

    ---------------------------------------------------
    -- Temp table to hold usage key-values
    ---------------------------------------------------

    CREATE TABLE #TmpUsageInfo (
        UsageKey varchar(32),
        UsageValue varchar(12) NULL,
        UniqueID int IDENTITY(1,1) NOT NULL
    )

    CREATE TABLE #TmpNonPercentageKeys (
        UsageKey varchar(32)
    )

    ---------------------------------------------------
    -- temp table to hold location of usage text
    ---------------------------------------------------

    CREATE TABLE #TmpUsageText (
        UsageText VARCHAR(64)
    )

    ---------------------------------------------------
    -- Usage keywords
    ---------------------------------------------------

    Declare @usageKeys VARCHAR(256) = 'CapDev, Broken, Maintenance, StaffNotAvailable, OtherNotAvailable, InstrumentAvailable, UserOnsite, UserRemote, ResourceOwner, Onsite, Remote, User'
    Declare @nonPercentageKeys VARCHAR(256) = 'Operator, Proposal, PropUser'
    Declare @commentToSearch Varchar(4096)

    BEGIN TRY
        ---------------------------------------------------
        -- Normalize punctuation to remove spaces around commas
        -- Furthermore, start @comment with a comma to allow for exact keyword matches
        ---------------------------------------------------

        Set @comment = REPLACE(@comment, ', ', ',')
        Set @comment = REPLACE(@comment, ' ,', ',')
        Set @commentToSearch = ',' + @comment

        ---------------------------------------------------
        -- Set up temp table with keywords
        ---------------------------------------------------

        -- Store the non-percentage based keys
        --
        INSERT INTO #TmpNonPercentageKeys (UsageKey)
        SELECT LTRIM(RTRIM(Item))
        FROM dbo.make_table_from_list(@nonPercentageKeys)

        -- Add the percentage-based keys to #TmpUsageInfo
        --
        INSERT INTO #TmpUsageInfo (UsageKey)
        SELECT LTRIM(RTRIM(Item))
        FROM dbo.make_table_from_list(@usageKeys)

        -- Add the non-percentage-based keys to #TmpUsageInfo
        --
        INSERT INTO #TmpUsageInfo (UsageKey)
        SELECT UsageKey
        FROM #TmpNonPercentageKeys

        ---------------------------------------------------
        -- Look for keywords in text and update table with
        -- corresponding values
        ---------------------------------------------------

        Declare @index int
        Declare @startOfValue int = 0
        Declare @endOfValue Int

        Declare @val varchar(24)
        Declare @curVal varchar(24)
        Declare @keywordStartIndex int = 0

        Declare @uniqueID int = 0, @nextID int = 0
        Declare @kw varchar(32)
        Declare @done tinyint = 0

        WHILE @done = 0
        BEGIN -- <a>
            ---------------------------------------------------
            -- Get next keyword to look for
            ---------------------------------------------------

            Set @kw = ''
            SELECT TOP 1
                @kw = ',' + UsageKey + '[',
                @curVal = UsageValue,
                @uniqueID = UniqueID
            FROM #TmpUsageInfo
            WHERE UniqueID > @nextID

            Set @nextID = @uniqueID

            ---------------------------------------------------
            -- Done if no more keywords,
            -- otherwise look for it in text
            ---------------------------------------------------

            IF @kw = ''
                Set @done = 1
            ELSE
            BEGIN -- <b>
                Set @index = CHARINDEX(@kw, @commentToSearch)

                ---------------------------------------------------
                -- If we found a keyword in the text
                -- parse out its values and save that in the usage table
                ---------------------------------------------------

                IF @index = 0
                BEGIN
                    if @showDebug > 0
                        Print '  keyword not found: ' + @kw
                END
                ELSE
                BEGIN -- <c>
                    if @showDebug > 0
                        Print 'Parse keyword ' + @kw + ' at index ' + Cast(@index as varchar(9))

                    Set @keywordStartIndex = @index
                    Set @startOfValue = @index + LEN(@kw)
                    Set @endOfValue = CHARINDEX(']', @commentToSearch, @startOfValue)
                    IF @endOfValue = 0
                    Begin
                        Set @logErrors = 0
                        Set @invalidUsage = 1
                        RAISERROR ('Could not find closing bracket for "%s"', 11, 4, @kw)
                    End

                    INSERT INTO #TmpUsageText ( UsageText )
                    VALUES (SUBSTRING(@commentToSearch, @keywordStartIndex + 1, (@endOfValue - @keywordStartIndex) + 1))

                    Set @val = ''
                    Set @val = SUBSTRING(@commentToSearch, @startOfValue, @endOfValue - @startOfValue)

                    Set @val = REPLACE(@val, '%', '')
                    Set @val = REPLACE(@val, ',', '')

                    If Try_Parse(@val as int) Is Null
                    Begin
                        Set @logErrors = 0
                        Set @invalidUsage = 1
                        RAISERROR ('Percentage value for usage "%s" is not a valid integer; see ID %d', 11, 5, @kw, @seq)
                    End

                    UPDATE #TmpUsageInfo
                    SET UsageValue = @val
                    WHERE UniqueID = @uniqueID

                END -- </c>
            END -- </b>
        END -- </a>

        ---------------------------------------------------
        -- Clear keywords not found from table
        ---------------------------------------------------

        DELETE FROM #TmpUsageInfo WHERE UsageValue IS null

        ---------------------------------------------------
        -- Updated abbreviated keywords
        ---------------------------------------------------

        UPDATE #TmpUsageInfo
        SET UsageKey = 'UserOnsite'
        WHERE UsageKey = 'Onsite'

        UPDATE #TmpUsageInfo
        SET UsageKey = 'UserRemote'
        WHERE UsageKey = 'Remote'

        ---------------------------------------------------
        -- Verify percentage total
        -- Skip keys in #TmpNonPercentageKeys ('Operator, Proposal, PropUser')
        ---------------------------------------------------

        Declare @total INT = 0
        SELECT @total = @total + CASE WHEN NOT UsageKey IN ( SELECT UsageKey FROM #TmpNonPercentageKeys )
                                      THEN COALESCE(Try_Parse(UsageValue as int), 0)
                                      ELSE 0
                                 END
        FROM #TmpUsageInfo

        IF @validateTotal > 0 And @total <> 100
        Begin
            Set @logErrors = 0
            Set @invalidUsage = 1
            RAISERROR ('Total percentage (%d) does not add up to 100 for ID %d; see %s', 11, 7, @total, @seq, 'http://prismwiki.pnl.gov/wiki/Long_Interval_Notes')
        End

        ---------------------------------------------------
        -- Verify proposal (if user present)
        ---------------------------------------------------

        Declare @hasUser INT = 0
        Declare @hasProposal INT = 0

        SELECT @hasUser = COUNT(*) FROM #TmpUsageInfo WHERE UsageKey IN ('User', 'UserOnsite', 'UserRemote')
        SELECT @hasProposal = COUNT(*) FROM #TmpUsageInfo WHERE UsageKey = 'Proposal'

        IF (@hasUser > 0 ) AND (@hasProposal = 0)
        Begin
            Set @logErrors = 0
            Set @invalidUsage = 1
            RAISERROR ('Proposal is needed if user allocation is specified; see ID %d', 11, 6, @seq)
        End

        ---------------------------------------------------
        -- Make XML
        ---------------------------------------------------

        Declare @s VARCHAR(512) = ''
        --
        SELECT @s = @s + UsageKey + '="' + UsageValue + '" '
        FROM #TmpUsageInfo
        --
        Set @usageXML = '<u ' + @s + ' />'

        ---------------------------------------------------
        -- Remove usage text from comment
        ---------------------------------------------------

        SELECT @comment = REPLACE(@comment, UsageText, '')
        FROM #TmpUsageText

        Set @comment = LTRIM(RTRIM(@comment))
        If @comment LIKE ',%'
            Set @comment = LTRIM(Substring(@comment, 2, LEN(@Comment)-1))

        If @comment LIKE '%,'
            Set @comment = RTRIM(Substring(@comment, 1, LEN(@Comment)-1))

        Set @comment = REPLACE(@comment, ',,', '')
        Set @comment = REPLACE(@comment, ', ,', '')
        Set @comment = REPLACE(@comment, '. ,', '. ')
        Set @comment = REPLACE(@comment, '.,', '. ')
        Set @comment = LTRIM(RTRIM(@comment))

        If @comment = ','
            Set @comment =''

        If @showDebug > 0
            Print 'Final comment for @seq ' + cast(@seq as varchar(9)) + ': ' + IsNull(@comment, '<Empty>') + '; @total = ' + Cast(@total as varchar(9))

    END TRY
    BEGIN CATCH
        --EXEC format_error_message @message output, @myError output
        Set @myError = ERROR_NUMBER()
        IF @myError = 50000
            Set @myError = ERROR_STATE()

        Set @message = ERROR_MESSAGE() -- + ' (' + ERROR_PROCEDURE() + ':' + CONVERT(VARCHAR(12), ERROR_LINE()) + ')'

        If @logErrors > 0
            Exec post_log_entry 'Error', @message, 'parse_usage_text'
    END CATCH

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[parse_usage_text] TO [DDL_Viewer] AS [dbo]
GO
