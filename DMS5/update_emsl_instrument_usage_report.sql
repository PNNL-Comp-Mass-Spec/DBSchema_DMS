/****** Object:  StoredProcedure [dbo].[UpdateEMSLInstrumentUsageReport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateEMSLInstrumentUsageReport]
/****************************************************
**
**  Desc:
**    Add entries to permanent EMSL monthly usage report (T_EMSL_Instrument_Usage_Report)
**    for given Instrument and month (as dictated via the @endDate parameter)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/21/2012
**          03/26/2012 grk - added code to clean up comments and pin trans-month interval starting time
**          04/09/2012 grk - modified algorithm
**          06/08/2012 grk - added lookup for @maxNormalInterval
**          08/30/2012 grk - don't overwrite existing non-blank items, do auto-comment non-onsite datasets
**          10/02/2012 grk - added debug output
**          10/06/2012 grk - adding "updated by" date and user
**          01/31/2013 mem - Now using IsNull(@message, '') when copying @message to @debug
**          03/12/2014 grk - Allow null [EMSL_Inst_ID] in #STAGING (OMCDA-1058)
**          02/23/2016 mem - Add set XACT_ABORT on
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          04/10/2017 mem - Remove @day and @hour since not used
**          04/11/2017 mem - Populate columns DMS_Inst_ID and Usage_Type instead of Instrument and Usage
**                         - Add parameter @infoOnly
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**                         - Set @validateTotal to 0 when calling ParseUsageText
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/02/2017 mem - Trim whitespace from the cleaned comment returned by ParseUsageText
**          01/05/2017 mem - Remove LF and CR from dataset comments
**          05/03/2019 mem - Add parameter @eusInstrumentId
**          04/17/2020 mem - Use Dataset_ID instead of ID
**          01/28/2022 mem - If a long interval has 'Broken' in the comment, store 'Broken' as the comment in T_EMSL_Instrument_Usage_Report
**                         - Replace SQL server specific syntax with more generic syntax for assigning sequential values to the seq column
**          02/15/2022 mem - Define column names when previewing updates
**          03/17/2022 mem - After populating the staging table, update @instrument if required
**                         - Call stored procedure UpdateEMSLInstrumentAcqOverlapColumn
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @instrument varchar(64),        -- Instrument name to process; leave this blank if processing by EMSL instrument ID
    @eusInstrumentId int,           -- EMSL instrument ID to process; use this to process instruments like the 12T or the 15T where there are two instrument entries in DMS, yet they both map to the same EUS_Instrument_ID
    @endDate datetime,              -- This is used to determine the target year and month; the day of the month does not really matter
    @message varchar(512) output,   -- Optionally specify debug reports to show, for example '1' or '1,2,3'
    @infoOnly tinyint = 0
)
AS
    SET XACT_ABORT, NOCOUNT ON

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @outputFormat varchar(12) = 'report'
    Declare @maxNormalInterval int
    Declare @callingUser varchar(128)

    Declare @year int
    Declare @month int
    Declare @bom datetime              -- Beginning of the month

    Declare @actualInstrument varchar(64)

    Declare @seq int
    Declare @cleanedComment varchar(4096)
    Declare @xml xml
    Declare @num int
    Declare @count int

    Set @instrument = IsNull(@instrument, '')
    Set @eusInstrumentId = IsNull(@eusInstrumentId, 0)

    Set @message = LTrim(RTrim(IsNull(@message, '')))

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'UpdateEMSLInstrumentUsageReport', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ------------------------------------------------------
    -- Create a table for tracking debug reports to show
    ------------------------------------------------------
    --
    CREATE TABLE #Tmp_DebugReports (
        Debug_ID int
    )

    If @message <> ''
    Begin
        ------------------------------------------------------
        -- Parse which debug reports should be shown
        ------------------------------------------------------
        --
        INSERT INTO #Tmp_DebugReports (Debug_ID)
        SELECT Value
        FROM dbo.udfParseDelimitedIntegerList(@message, ',')
        ORDER BY Value
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If Not Exists (Select * from #Tmp_DebugReports)
        Begin
            Set @message = 'To see debug reports, @message must have a comma separated list of integers'
            RAISERROR (@message, 10, 1)
        End
    End

    Set @message = ''

    BEGIN TRY
        Set @maxNormalInterval = dbo.GetLongIntervalThreshold()

        Set @callingUser = dbo.GetUserLoginWithoutDomain('')

        ---------------------------------------------------
        -- Figure out our time context
        ---------------------------------------------------

        Set @year = DATEPART(YEAR, @endDate)
        Set @month = DATEPART(MONTH, @endDate)

        Set @bom = CONVERT(varchar(12), @year) + '-' + CONVERT(varchar(12), @month) + '-01'

        ---------------------------------------------------
        -- Temporary table for staging report rows
        ---------------------------------------------------

        CREATE TABLE #STAGING (
            Staging_ID int PRIMARY KEY IDENTITY not null,
            [EMSL_Inst_ID] int NULL,
            [Instrument] varchar(64),
            [DMS_Inst_ID] int NULL,
            [Type] varchar(128),
            [Start] datetime,
            [Minutes] int,
            [Proposal] varchar(32) NULL,
            [Usage] varchar(32) NULL,
            [Usage_Type] tinyint NULL,
            [Users] varchar(1024),
            [Operator] varchar(64),        -- Could be an empty string or an Operator ID
            [Comment] varchar(4096) NULL,
            [Year] int,
            [Month] int,
            [Dataset_ID] int,
            [Operator_ID] int NULL,        -- Value of [Operator] if an integer, otherwise null
            [Mark] int NULL,               -- 0 if adding a new row to T_EMSL_Instrument_Usage_Report, 1 if matches an existing row that will be updated
            Seq int NULL
        )

        Create Index #IX_STAGING On #STAGING (Seq)

        ---------------------------------------------------
        -- Populate staging table with report rows for the instrument
        -- (specified by @instrument or @eusInstrumentId)
        -- for the target month (based on @endDate)
        ---------------------------------------------------

        INSERT INTO #STAGING
                ( [Instrument],
                  [EMSL_Inst_ID],
                  [Start],
                  [Type],
                  [Minutes],
                  [Proposal],
                  [Usage],
                  [Users],
                  [Operator],
                  [Comment],
                  [Year],
                  [Month],
                  [Dataset_ID]
                )
        EXEC GetMonthlyInstrumentUsageReport @instrument, @eusInstrumentId,
                                             @year, @month,
                                             @outputFormat, @message OUTPUT

        -- Assure that @instrument matches the data in #STAGING
        -- It could be an empty string if this procedure was called with @eusInstrumentId
        -- It may also have been changed if it corresponds to a DMS instrument that shares and EUS instrument ID with another DMS instrument

        SELECT TOP 1 @actualInstrument = Instrument
        FROM #STAGING
        WHERE Instrument <> ''

        Set @actualInstrument = IsNull(@actualInstrument, '')

        If @actualInstrument <> ''
        Begin
            If @instrument <> @actualInstrument And
               (@infoOnly > 0 Or Exists (Select * from #Tmp_DebugReports))
            Begin
                Print 'Setting @instrument to @actualInstrument'
            End

            Set @instrument = @actualInstrument
        End

        -- Populate the Operator_ID field and assure that the comment field does not have LF or CR
        UPDATE #STAGING
        SET Operator_ID = Try_Convert(int, Operator),
            Comment = Replace(Replace(Comment, Char(10), ' '), Char(13), ' ')

        ---------------------------------------------------
        -- Populate columns DMS_Inst_ID and Usage_Type
        ---------------------------------------------------
        --
        UPDATE #STAGING
        SET DMS_Inst_ID = InstName.Instrument_ID
        FROM #STAGING
             INNER JOIN T_Instrument_Name InstName
               ON #STAGING.Instrument = InstName.IN_Name

        UPDATE #STAGING
        SET Usage_Type = InstUsageType.ID
        FROM #STAGING
             INNER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
               ON #STAGING.Usage = InstUsageType.Name

        If Exists (Select * from #Tmp_DebugReports Where Debug_ID = 1)
        Begin
            SELECT 'Initial data' as State, * FROM #STAGING
        End

        ---------------------------------------------------
        -- Mark items that are already in report
        ---------------------------------------------------

        UPDATE #STAGING
        SET [Mark] = 1
        FROM #STAGING
             INNER JOIN T_EMSL_Instrument_Usage_Report TR
               ON #STAGING.Dataset_ID = TR.Dataset_ID AND
                  #STAGING.[Type] = TR.[Type]

        If Exists (Select * from #Tmp_DebugReports Where Debug_ID = 2)
        Begin
            SELECT 'Mark set to 1' as State, * FROM #STAGING WHERE [Mark] = 1
        End

        ---------------------------------------------------
        -- Add unique sequence value to new report rows
        -- In addition, set Mark to 0
        ---------------------------------------------------

        Set @seq = 0

        SELECT @seq = ISNULL(MAX(Seq), 0)
        FROM T_EMSL_Instrument_Usage_Report

        -- The following update query increments @seq after updating each row
        -- This is a SQL server specific syntax
        --
        /* UPDATE #STAGING
        Set @seq = Seq = @seq + 1,
        [Mark] = 0
        FROM #STAGING
        WHERE [Mark] IS NULL
        */

        UPDATE #STAGING
        SET Seq = SourceQ.New_Seq,
            Mark = 0
        FROM (SELECT Staging_ID,
                     @seq + row_number() over (order by Dataset_ID, [Type]) AS New_Seq
              FROM #STAGING
              WHERE Mark Is Null) SourceQ
        WHERE #STAGING.Staging_ID = SourceQ.Staging_ID

        If Exists (Select * from #Tmp_DebugReports Where Debug_ID = 3)
        Begin
            SELECT 'Mark set to 0' as State, * FROM #STAGING WHERE [Mark] = 0
        End

        ---------------------------------------------------
        -- Cleanup:
        --  Remove usage text from comments
        --  However, if the comment starts with 'Broken', keep that word
        ---------------------------------------------------

        Set @seq = 0
        Set @count = 0

        SELECT @num = COUNT(*) FROM #STAGING

        WHILE @count < @num
        BEGIN
            Set @cleanedComment = ''

            SELECT TOP 1
                @seq = Seq,
                @cleanedComment = Comment
            FROM #STAGING
            WHERE Seq > @seq
            ORDER BY Seq

            IF @cleanedComment <> ''
            BEGIN
                If LTrim(@cleanedComment) Like 'Broken%'
                Begin
                    Set @cleanedComment = 'Broken'
                End
                Else
                Begin
                    ---------------------------------------------------
                    -- ParseUsageText looks for special usage tags in the comment and extracts that information, returning it as XML
                    --
                    -- If @cleanedComment is initially 'User[100%], Proposal[49361], PropUser[50082] Extra information about interval'
                    -- after calling ParseUsageText, @cleanedComment will be ' Extra information about interval''
                    -- and @xml will be <u User="100" Proposal="49361" PropUser="50082" />
                    --
                    -- If @cleanedComment only has 'User[100%], Proposal[49361], PropUser[50082]', then @cleanedComment will be empty after the call to ParseUsageText
                    ---------------------------------------------------

                    EXEC dbo.ParseUsageText @cleanedComment output, @xml output, @message output, @seq=@seq, @showDebug=@infoOnly, @validateTotal=0
                End

                UPDATE #STAGING
                SET Comment = LTrim(RTrim(@cleanedComment))
                WHERE Seq = @seq
            END
            Set @count = @count + 1
        END

        If Exists (Select * from #Tmp_DebugReports Where Debug_ID = 4)
        Begin
            SELECT 'Comments cleaned' as State, * FROM #STAGING WHERE [Mark] = 0
        End

        ---------------------------------------------------
        -- Pin start time for month-spanning intervals
        ---------------------------------------------------

        UPDATE #STAGING
        SET [Start] = @bom
        WHERE [Type] = 'Interval' AND [Start] < @bom

        If Exists (Select * from #Tmp_DebugReports Where Debug_ID = 5)
        Begin
            SELECT 'Intervals' as State, * FROM #STAGING WHERE [Type] = 'Interval'
        End

        If Exists (Select * from #Tmp_DebugReports Where Debug_ID = 6)
        Begin -- <preview>

            SELECT #STAGING.[Start] AS [Start],
                   CASE WHEN ISNULL(InstUsage.Proposal, '') = '' THEN #STAGING.Proposal ELSE InstUsage.Proposal END AS Proposal,
                   CASE WHEN ISNULL(InstUsage.Usage_Type, 0) = 0 THEN #STAGING.Usage ELSE InstUsageType.Name END AS [Usage],
                   CASE WHEN ISNULL(InstUsage.Usage_Type, 0) = 0 THEN #STAGING.Usage_Type ELSE InstUsage.Usage_Type END AS Usage_Type,
                   CASE WHEN ISNULL(InstUsage.Users, '') = ''    THEN #STAGING.Users ELSE InstUsage.Users END AS Users,
                   CASE WHEN InstUsage.Operator Is Null          THEN #STAGING.Operator_ID ELSE InstUsage.Operator END AS Operator,
                   #STAGING.[Year] AS [Year],
                   #STAGING.[Month] AS [Month],
                   CASE WHEN ISNULL(InstUsage.[Comment], '') = '' THEN #STAGING.[Comment] ELSE InstUsage.[Comment] END AS [Comment]
            FROM T_EMSL_Instrument_Usage_Report InstUsage
                 INNER JOIN #STAGING
                   ON InstUsage.Dataset_ID = #STAGING.Dataset_ID AND
                      InstUsage.[Type] = #STAGING.[Type]
                 LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
                   ON InstUsage.Usage_Type = InstUsageType.ID
            WHERE #STAGING.Mark = 1
            ORDER BY #STAGING.[Start]

            SELECT EMSL_Inst_ID,
                   DMS_Inst_ID,
                   [Type],
                   [Start],
                   [Minutes],
                   Proposal,
                   [Usage],
                   Usage_Type,
                   Users,
                   Operator,
                   [Comment],
                   [Year],
                   [Month],
                   Dataset_ID,
                   Operator_ID,
                   Seq
            FROM #STAGING
            WHERE [Mark] = 0
            ORDER BY [Start], Dataset_ID

            ---------------------------------------------------
            -- Clean out any "long intervals" that don't appear
            -- in the main interval table
            ---------------------------------------------------

            SELECT InstUsage.EMSL_Inst_ID,
                   InstName.IN_Name AS Instrument,
                   InstUsage.[Type],
                   InstUsage.[Start],
                   InstUsage.[Minutes],
                   InstUsage.Proposal,
                   InstUsage.Usage_Type,
                   InstUsage.Users,
                   InstUsage.Operator,
                   InstUsage.[Comment],
                   InstUsage.[Year],
                   InstUsage.[Month],
                   InstUsage.Dataset_ID,
                   InstUsage.Seq
            FROM T_EMSL_Instrument_Usage_Report InstUsage
                 INNER JOIN T_Instrument_Name InstName
                   ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
            WHERE [Type] = 'Interval' AND
                  InstUsage.[Year] = @year AND
                  InstUsage.[Month] = @month AND
                  InstName.IN_Name = @instrument AND
                  NOT InstUsage.Dataset_ID IN ( SELECT ID FROM T_Run_Interval )

        End -- </preview>

        ---------------------------------------------------
        -- Update existing values in report table from staging table
        ---------------------------------------------------

        If Not Exists (Select * from #Tmp_DebugReports)
        Begin -- <a>

            If @infoOnly = 0
            Begin
                UPDATE InstUsage
                    SET
                    [Minutes] = #STAGING.[Minutes],
                    [Start] = #STAGING.[Start],
                    Proposal = CASE WHEN ISNULL(InstUsage.Proposal, '') = ''   THEN #STAGING.Proposal ELSE InstUsage.Proposal END,
                    Usage_Type = CASE WHEN ISNULL(InstUsage.Usage_Type, 0) = 0 THEN #STAGING.Usage_Type ELSE InstUsage.Usage_Type END,
                    Users = CASE WHEN ISNULL(InstUsage.Users, '') = ''         THEN #STAGING.Users ELSE InstUsage.Users END,
                    Operator = CASE WHEN InstUsage.Operator Is Null            THEN #STAGING.Operator ELSE InstUsage.Operator END,
                    [Year] = #STAGING.[Year],
                    [Month] = #STAGING.[Month],
                    Comment = CASE WHEN ISNULL(InstUsage.Comment, '') = '' THEN #STAGING.Comment ELSE InstUsage.Comment END,
                    [Updated] = GETDATE(),
                    UpdatedBy = @callingUser
                FROM T_EMSL_Instrument_Usage_Report InstUsage
                     INNER JOIN #STAGING
                       ON InstUsage.Dataset_ID = #STAGING.Dataset_ID AND
                          InstUsage.[Type] = #STAGING.[Type]
                WHERE #STAGING.MARK = 1
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
            Else
            Begin
                SELECT 'Update Row' as [Action],
                        #STAGING.[Minutes],
                        #STAGING.[Start],
                        CASE WHEN ISNULL(InstUsage.Proposal, '') = '' THEN #STAGING.Proposal ELSE InstUsage.Proposal END As Proposal,
                        CASE WHEN ISNULL(InstUsage.Usage_Type, 0) = 0 THEN #STAGING.Usage_Type ELSE InstUsage.Usage_Type END As Usage_Type,
                        CASE WHEN ISNULL(InstUsage.Users, '') = ''    THEN #STAGING.Users ELSE InstUsage.Users END As Users,
                        CASE WHEN InstUsage.Operator Is Null          THEN #STAGING.Operator ELSE InstUsage.Operator END As Operator,
                        #STAGING.[Year],
                        #STAGING.[Month],
                        CASE WHEN ISNULL(InstUsage.Comment, '') = '' THEN #STAGING.Comment ELSE InstUsage.Comment End As Comment,
                        GETDATE() As Updated,
                        @callingUser As CallingUser
                FROM T_EMSL_Instrument_Usage_Report InstUsage
                        INNER JOIN #STAGING
                        ON InstUsage.Dataset_ID = #STAGING.Dataset_ID AND
                            InstUsage.[Type] = #STAGING.[Type]
                WHERE #STAGING.MARK = 1
                ORDER BY #STAGING.[Start]
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount > 0
                    Print 'Would update ' + Cast(@myRowCount as varchar(9)) + ' rows in T_EMSL_Instrument_Usage_Report'
            End

            ---------------------------------------------------
            -- Clean out any short "long intervals"
            ---------------------------------------------------

            DELETE FROM #STAGING
            WHERE [Type] = 'Interval' AND
                  [Minutes] < @maxNormalInterval
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @infoOnly > 0 And @myRowCount > 0
                Print 'Deleted ' + Cast(@myRowCount as varchar(9)) + ' short "long intervals" from #STAGING'

            ---------------------------------------------------
            -- Add new values from staging table to database
            ---------------------------------------------------

            If @infoOnly = 0
            Begin
                INSERT INTO T_EMSL_Instrument_Usage_Report( EMSL_Inst_ID, DMS_Inst_ID, [Type],
                                                            [Start], [Minutes], Proposal, Usage_Type,
                                                            Users, Operator, Comment, [Year], [Month],
                                                            Dataset_ID, UpdatedBy, Seq )
                SELECT EMSL_Inst_ID, DMS_Inst_ID, [Type],
                       [Start], [Minutes], Proposal, Usage_Type,
                       Users, Operator_ID, Comment, [Year], [Month],
                       Dataset_ID, @callingUser, Seq
                FROM #STAGING
                WHERE [Mark] = 0
                ORDER BY [Start]
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
            Else
            Begin
                SELECT 'Insert Row' as [Action],
                       EMSL_Inst_ID, DMS_Inst_ID, [Type],
                       [Start], [Minutes], Proposal, Usage_Type,
                       Users, Operator_ID, Comment, [Year], [Month],
                       Dataset_ID, @callingUser as UpdatedBy, Seq
                FROM #STAGING
                WHERE [Mark] = 0
                ORDER BY [Start]
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount > 0
                    Print 'Would insert ' + Cast(@myRowCount as varchar(9)) + ' rows into T_EMSL_Instrument_Usage_Report'
            End

            ---------------------------------------------------
            -- Clean out short "long intervals"
            ---------------------------------------------------

            If @infoOnly = 0
            Begin
                DELETE FROM T_EMSL_Instrument_Usage_Report
                WHERE Dataset_ID IN ( SELECT Dataset_ID
                                      FROM #STAGING ) AND
                      [Type] = 'Interval' AND
                      [Minutes] < @maxNormalInterval
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
            Else
            Begin
                SELECT 'Delete short "long interval"' AS [Action], *
                FROM T_EMSL_Instrument_Usage_Report
                WHERE Dataset_ID IN ( SELECT Dataset_ID
                                      FROM #STAGING ) AND
                      [Type] = 'Interval' AND
                      [Minutes] < @maxNormalInterval
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount > 0
                    Print 'Would delete ' + Cast(@myRowCount as varchar(9)) + ' shorter "long intervals" from T_EMSL_Instrument_Usage_Report'
            End

            ---------------------------------------------------
            -- Clean out any "long intervals" that don't appear
            -- in the main interval table
            ---------------------------------------------------

            If @infoOnly = 0
            Begin
                DELETE T_EMSL_Instrument_Usage_Report
                FROM T_EMSL_Instrument_Usage_Report InstUsage
                     INNER JOIN T_Instrument_Name InstName
                       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
                WHERE InstUsage.[Type] = 'Interval' AND
                      InstUsage.[Year] = @year AND
                      InstUsage.[Month] = @month AND
                      InstName.IN_Name = @instrument AND
                      NOT InstUsage.Dataset_ID IN ( SELECT ID FROM T_Run_Interval )
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
            Else
            Begin
                SELECT 'Delete long "long interval"' AS [Action],
                       InstUsage.*
                FROM T_EMSL_Instrument_Usage_Report InstUsage
                     INNER JOIN T_Instrument_Name InstName
                       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
                WHERE InstUsage.[Type] = 'Interval' AND
                      InstUsage.[Year] = @year AND
                      InstUsage.[Month] = @month AND
                      InstName.IN_Name = @instrument AND
                      NOT InstUsage.Dataset_ID IN ( SELECT ID FROM T_Run_Interval )
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount > 0
                    Print 'Would delete ' + Cast(@myRowCount as varchar(9)) + ' longer "long intervals" from T_EMSL_Instrument_Usage_Report'
            End

            ---------------------------------------------------
            -- Add automatic log references for missing comments
            -- (ignoring MAINTENANCE and ONSITE entries)
            ---------------------------------------------------

            If @infoOnly = 0
            Begin
                UPDATE T_EMSL_Instrument_Usage_Report
                SET [Comment] = dbo.GetNearestPrecedingLogEntry(InstUsage.Seq, 0)
                FROM T_EMSL_Instrument_Usage_Report InstUsage
                    LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
                    ON InstUsage.Usage_Type = InstUsageType.ID
                WHERE InstUsage.[Year] = @year AND
                    InstUsage.[Month] = @month AND
                    InstUsage.[Type]= 'Dataset' AND
                    IsNull(InstUsageType.Name, '') NOT IN ('MAINTENANCE', 'ONSITE') AND
                    ISNULL(InstUsage.[Comment], '') = ''
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
            Else
            Begin
                SELECT 'Add log reference to comment' as [Action],
                       InstUsage.Seq,
                       InstName.IN_Name AS Instrument,
                       [Comment] AS OldComment,
                       dbo.GetNearestPrecedingLogEntry(InstUsage.Seq, 0) AS NewComment
                FROM T_EMSL_Instrument_Usage_Report InstUsage
                     INNER JOIN T_Instrument_Name InstName
                       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
                     LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
                       ON InstUsage.Usage_Type = InstUsageType.ID
                WHERE InstUsage.[Year] = @year AND
                      InstUsage.[Month] = @month AND
                      InstUsage.[Type] = 'Dataset' AND
                      IsNull(InstUsageType.Name, '') NOT IN ('MAINTENANCE', 'ONSITE') AND
                      ISNULL(InstUsage.[Comment], '') = ''
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End

            ---------------------------------------------------
            -- Remove "ONSITE" comments
            ---------------------------------------------------

            If @infoOnly = 0
            Begin
                UPDATE T_EMSL_Instrument_Usage_Report
                SET [Comment] = ''
                FROM T_EMSL_Instrument_Usage_Report InstUsage
                     INNER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
                       ON InstUsage.Usage_Type = InstUsageType.ID
                     INNER JOIN T_Instrument_Name InstName
                       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
                WHERE InstUsageType.Name IN ('ONSITE') AND
                      InstName.IN_Name = @instrument AND
                      InstUsage.[Year] = @year AND
                      InstUsage.[Month] = @month AND
                      ([Comment] IS NULL OR IsNull([Comment], '') <> '')
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
            Else
            Begin
                SELECT 'Clear maintenance and onsite comments' AS [Action],
                       InstUsage.Seq,
                       InstName.IN_Name AS Instrument,
                       [Comment] AS OldComment,
                       '' AS NewComment
                FROM T_EMSL_Instrument_Usage_Report InstUsage
                     INNER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
                       ON InstUsage.Usage_Type = InstUsageType.ID
                     INNER JOIN T_Instrument_Name InstName
                       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
                WHERE InstUsageType.Name IN ('ONSITE') AND
                      InstName.IN_Name = @instrument AND
                      InstUsage.[Year] = @year AND
                      InstUsage.[Month] = @month AND
                      ([Comment] IS NULL OR IsNull([Comment], '') <> '')
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End

            ---------------------------------------------------
            -- Populate field Dataset_ID_Acq_Overlap, which is used to track datasets with identical acquisition start times
            ---------------------------------------------------

            Exec UpdateEMSLInstrumentAcqOverlapData @instrument, @year, @month, @message = @message Output, @infoOnly = @infoOnly

        End -- </a>

    END TRY
    BEGIN CATCH

        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'UpdateEMSLInstrumentUsageReport'

    END CATCH

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEMSLInstrumentUsageReport] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateEMSLInstrumentUsageReport] TO [DMS2_SP_User] AS [dbo]
GO
