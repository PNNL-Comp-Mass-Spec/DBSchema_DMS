/****** Object:  StoredProcedure [dbo].[get_monthly_instrument_usage_report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_monthly_instrument_usage_report]
/****************************************************
**
**  Desc:
**    Create a monthly usage report for given
**    Instrument, year, and month
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/06/2012
**          03/06/2012 grk - Rename @mode to @outputFormat
**          03/06/2012 grk - Add long interval comment to 'detail' output format
**          03/10/2012 grk - Add '@OtherNotAvailable'
**          03/15/2012 grk - Add 'report' @outputFormat
**          03/20/2012 grk - Add users to 'report' @outputFormat
**          03/21/2012 grk - Add operator ID for ONSITE interval to 'report' @outputFormat
**          08/21/2012 grk - Add code to pull comment from dataset
**          08/28/2012 grk - Add code to clear comment from ONSITE capability type
**          08/31/2012 grk - Remove 'Auto-switched dataset type ...' text from dataset comments
**          09/11/2012 grk - Add percent column to 'rollup' mode
**          09/18/2012 grk - Handle "Operator" and "PropUser" prorata comment fields
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/03/2019 mem - Add parameter @eusInstrumentId, which is sent to get_run_tracking_monthly_info_by_id if non-zero
**          04/17/2020 mem - Add defaults for parameters @eusInstrumentId and @message
**                           Use Dataset_ID instead of ID
**          04/27/2020 mem - Update data validation checks
**                         - Make several columns in the output table nullable
**          05/26/2021 mem - Add support for usage types UserRemote and UserOnsite
**                         - Use REMOTE when the usage has UserRemote
**          03/17/2022 mem - Update comments and whitespace
**          05/27/2022 mem - Do not log year or month conversion errors to the database
**                         - Validate @year, @month, and @outputFormat
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @instrument varchar(64),
    @eusInstrumentId int = 0,               -- EMSL instrument ID to process; use this to process instruments like the 12T or the 15T where there are two instrument entries in DMS, yet they both map to the same EUS_Instrument_ID
    @year varchar(12),
    @month varchar(12),
    @outputFormat varchar(12) = 'details',  -- 'details', 'rollup', 'check', 'report'
    @message varchar(512) = '' Output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @logErrors tinyint = 0
    Declare @monthValue Int
    Declare @yearValue Int

    Set @instrument = IsNull(@instrument, '')
    Set @eusInstrumentId = IsNull(@eusInstrumentId, 0)
    Set @outputFormat = IsNull(@outputFormat, '')

    Set @message = ''

    Declare @processByEUS tinyint = 0

    If @eusInstrumentId > 0
    Begin
        Set @processByEUS = 1
    End

    ---------------------------------------------------
    ---------------------------------------------------
    BEGIN TRY

        Set @monthValue = Try_Cast(@month As Int)
        If @monthValue Is Null Or Not @monthValue Between 1 And 12
        Begin
            RAISERROR ('Invalid month, must be an integer between 1 and 12', 11, 7)
        End

        Set @yearValue = Try_Cast(@year As Int)
        If @yearValue Is Null Or @yearValue < 1970
        Begin
            RAISERROR ('Invalid year, must be an integer', 11, 7)
        End

        If Not @outputFormat In ('', 'report', 'details', 'rollup', 'check', 'debug1', 'debug2', 'debug3')
        Begin
            RAISERROR ('Invalid output format; should be report, details, rollup, or check', 11, 7)
        End

        If @processByEUS = 0
        Begin
            -- Auto switch to @eusInstrumentId if needed
            -- Look for EUS Instruments mapped to two or more DMS instruments

            SELECT @eusInstrumentId = InstMapping.EUS_Instrument_ID
            FROM T_Instrument_Name InstName
                 INNER JOIN T_EMSL_DMS_Instrument_Mapping InstMapping
                   ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
                 INNER JOIN ( SELECT EUS_Instrument_ID
                              FROM T_Instrument_Name InstName
                                   INNER JOIN T_EMSL_DMS_Instrument_Mapping InstMapping
                                     ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
                              GROUP BY EUS_Instrument_ID
                              HAVING Count(*) > 1 ) LookupQ
                   ON InstMapping.EUS_Instrument_ID = LookupQ.EUS_Instrument_ID
            WHERE InstName.IN_name = @instrument

            If @eusInstrumentId > 0
            Begin
                Set @processByEUS = 1
            End

        End

        ---------------------------------------------------
        -- Get maximum time available in month
        ---------------------------------------------------

        Declare @date DATETIME = CONVERT(DATE, @month + '/1/' + @year, 101)
        Declare @daysInMonth Int = DAY(DATEADD (m, 1, DATEADD (d, 1 - DAY(@date), @date)) - 1)
        Declare @minutesInMonth INT = @daysInMonth * 1440

        Set @logErrors = 1

        ---------------------------------------------------
        -- Create temporary table to contain report data
        -- and populate with datasets in for the specified
        -- instrument and reporting month
        -- (the UDF returns intervals adjusted to monthly boundaries)
        ---------------------------------------------------

        CREATE TABLE #TR (
            Dataset_ID INT,
            [Type] VARCHAR(128),
            Start DATETIME,
            Duration INT,
            [Interval] INT,
            Proposal varchar(32) NULL,
            [Usage] varchar(32) NULL,
            [UsageID] INT NULL,
            [Normal] TINYINT NULL,
            Comment VARCHAR(4096) NULL,
            Users VARCHAR(1024) NULL,
            Operator VARCHAR(128) NULL
        )

        If @instrument = '' AND @eusInstrumentId = 0
        Begin
            INSERT INTO #TR (
                Dataset_ID,
                [Type],
                Start,
                Duration,
                [Interval],
                Proposal,
                [UsageID],
                [Usage],
                [Normal],
                [Comment]
            )
            VALUES (1, 'Error', NULL, 0, 0, '', 0, '', 0, 'Must define @instrument or @eusInstrumentId');

            SELECT * FROM #TR
            RETURN 1
        End

        If @processByEUS > 0
        Begin;
            INSERT INTO #TR (
                Dataset_ID,
                [Type],
                Start,
                Duration,
                [Interval],
                Proposal,
                [UsageID],
                [Usage],
                [Normal]
            )
            SELECT GRTMI.ID,
                   'Dataset' AS [Type],
                   GRTMI.Time_Start AS Start,
                   GRTMI.Duration,
                   ISNULL(GRTMI.INTERVAL, 0) AS [Interval],
                   ISNULL(TRR.RDS_EUS_Proposal_ID, '') AS Proposal,
                   TRR.RDS_EUS_UsageType AS UsageID,
                   TEUT.Name AS [Usage],
                   1
            FROM dbo.get_run_tracking_monthly_info_by_id ( @eusInstrumentId, @year, @month, '' ) AS GRTMI
                 LEFT OUTER JOIN T_Requested_Run AS TRR
                   ON GRTMI.ID = TRR.DatasetID
                 INNER JOIN T_EUS_UsageType TEUT
                   ON TRR.RDS_EUS_UsageType = TEUT.ID;

        End;
        Else
        Begin;

            INSERT INTO #TR (
                Dataset_ID,
                [Type],
                Start,
                Duration,
                [Interval],
                Proposal,
                [UsageID],
                [Usage],
                [Normal]
            )
            SELECT GRTMI.ID,
                   'Dataset' AS [Type],
                   GRTMI.Time_Start AS Start,
                   GRTMI.Duration,
                   ISNULL(GRTMI.INTERVAL, 0) AS [Interval],
                   ISNULL(TRR.RDS_EUS_Proposal_ID, '') AS Proposal,
                   TRR.RDS_EUS_UsageType AS UsageID,
                   TEUT.Name AS [Usage],
                   1
            FROM dbo.get_run_tracking_monthly_info ( @instrument, @year, @month, '' ) AS GRTMI
                 LEFT OUTER JOIN T_Requested_Run AS TRR
                   ON GRTMI.ID = TRR.DatasetID
                 INNER JOIN T_EUS_UsageType TEUT
                   ON TRR.RDS_EUS_UsageType = TEUT.ID;

        End;

        ---------------------------------------------------
        -- Pull comments from datasets
        --
        -- The Common Table Expression (CTE) is used to create a cleaned up comment that removes
        --  text of the form Auto-switched dataset type from HMS-MSn to HMS-HCD-HMSn on 2012-01-01
        ---------------------------------------------------

        WITH DSCommentClean (Dataset_ID, Comment)
        AS ( SELECT Dataset_ID, REPLACE(DS_Comment, TextToRemove, '') AS Comment
             FROM ( SELECT Dataset_ID, DS_Comment,
                           SUBSTRING(DS_Comment, AutoSwitchIndex, AutoSwitchIndex + AutoSwitchIndexEnd) AS TextToRemove
                    FROM ( SELECT Dataset_ID, DS_Comment, AutoSwitchIndex,
                                  PATINDEX('%[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]%', AutoSwitchTextPortion) + 10 AS AutoSwitchIndexEnd
                            FROM ( SELECT Dataset_ID, DS_Comment, AutoSwitchIndex,
                                          SUBSTRING(DS_Comment, AutoSwitchIndex, 200) AS AutoSwitchTextPortion
                                    FROM ( SELECT DS.Dataset_ID, DS_Comment,
                                                  PATINDEX('%Auto-switched dataset type from%to%on [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]%', DS_comment) AS AutoSwitchIndex
                                            FROM T_Dataset DS INNER JOIN
                                                 #TR ON DS.Dataset_ID = #TR.Dataset_ID
                                          ) FilterQ
                                    WHERE AutoSwitchIndex > 0
                                  ) FilterQ2
                           ) FilterQ3
                    ) FilterQ4
          )
        UPDATE #TR
        SET Comment = IsNull(DSCommentClean.Comment, IsNull(TDS.DS_comment, ''))
        FROM #TR INNER JOIN
             T_Dataset AS TDS ON TDS.Dataset_ID = #TR.Dataset_ID LEFT OUTER JOIN
             DSCommentClean ON DSCommentClean.Dataset_ID = #TR.Dataset_ID;

        ---------------------------------------------------
        -- Make a temp table to work with long intervals
        -- and populate it with long intervals for the datasets
        -- that were added to the temp report table
        ---------------------------------------------------

        CREATE TABLE #TI (
              Dataset_ID INT,
              Start DATETIME,
              Breakdown XML NULL,
              Comment VARCHAR(4096) NULL
        )

        INSERT Into #TI (
            Dataset_ID,
            Start,
            Breakdown,  -- Holds usage description, from T_Run_Interval.Comment
            Comment
        )
        SELECT
                TRI.ID,
                TRI.Start,
                TRI.Usage,  -- Examples: 'Maintenance[100%]' or 'UserOnsite[100%], Proposal[50587], PropUser[45631]' or 'User[100%], Proposal[51667], PropUser[48542]'
                TRI.Comment
        FROM  T_Run_Interval TRI
                INNER JOIN #TR ON TRI.ID = #TR.Dataset_ID

        ---------------------------------------------------
        -- Mark datasets in temp report table
        -- that have long intervals
        ---------------------------------------------------

        UPDATE #TR
        SET [Normal] = 0
        WHERE #TR.Dataset_ID IN (SELECT Dataset_ID FROM #TI)

        ---------------------------------------------------
        -- Make temp table to hold apportioned long interval values
        ---------------------------------------------------

        CREATE TABLE #TQ (
            Dataset_ID INT,
            Start DATETIME,
            [Interval] INT,
            Proposal varchar(32) NULL,
            [Usage] varchar(32) NULL,
            Comment VARCHAR(4096) NULL,
            Users VARCHAR(1024) NULL,
            Operator VARCHAR(128) NULL
        )

        ---------------------------------------------------
        -- Extract long interval apportionments from XML
        -- and use to save apportioned intervals to the temp table
        ---------------------------------------------------

        INSERT INTO #TQ (Dataset_ID, Start, [Interval], Proposal, [Usage], Comment)
        SELECT
            #TI.Dataset_ID,
            #TI.Start,
            CONVERT(FLOAT, ISNULL(xmlNode.value('@Broken', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
            '' AS Proposal,
            'BROKEN' AS USAGE,
            #TI.Comment
        FROM #TI
        INNER JOIN #TR ON #TR.Dataset_ID = #TI.Dataset_ID
                CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

        INSERT INTO #TQ (Dataset_ID, Start, [Interval], Proposal, [Usage], Comment)
        SELECT
            #TI.Dataset_ID,
            #TI.Start,
            CONVERT(FLOAT, ISNULL(xmlNode.value('@Maintenance', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
            '' AS Proposal,
            'MAINTENANCE' AS Usage,            -- This is defined in T_EMSL_Instrument_Usage_Type
            #TI.Comment
        FROM #TI
        INNER JOIN #TR ON #TR.Dataset_ID = #TI.Dataset_ID
                CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

        INSERT INTO #TQ (Dataset_ID, Start, [Interval], Proposal, [Usage], Comment)
        SELECT
            #TI.Dataset_ID,
            #TI.Start,
            CONVERT(FLOAT, ISNULL(xmlNode.value('@OtherNotAvailable', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
            '' AS Proposal,
            'UNAVAILABLE' AS Usage,            -- This is defined in T_EMSL_Instrument_Usage_Type
            #TI.Comment
        FROM #TI
        INNER JOIN #TR ON #TR.Dataset_ID = #TI.Dataset_ID
                CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

        INSERT INTO #TQ (Dataset_ID, Start, [Interval], Proposal, [Usage], Comment)
        SELECT
            #TI.Dataset_ID,
            #TI.Start,
            CONVERT(FLOAT, ISNULL(xmlNode.value('@StaffNotAvailable', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
            '' AS Proposal,
            'UNAVAIL_STAFF' AS Usage,            -- This is defined in T_EMSL_Instrument_Usage_Type
            #TI.Comment
        FROM #TI
        INNER JOIN #TR ON #TR.Dataset_ID = #TI.Dataset_ID
                CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

        INSERT INTO #TQ (Dataset_ID, Start, [Interval], Operator, Proposal, [Usage], Comment)
        SELECT
            #TI.Dataset_ID,
            #TI.Start,
            CONVERT(FLOAT, ISNULL(xmlNode.value('@CapDev', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
            xmlNode.value('@Operator', 'varchar(32)') AS Operator,
            '' AS Proposal,
            'CAP_DEV' AS Usage,                    -- This is defined in T_EMSL_Instrument_Usage_Type
            #TI.Comment
        FROM #TI
        INNER JOIN #TR ON #TR.Dataset_ID = #TI.Dataset_ID
                CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

        INSERT INTO #TQ (Dataset_ID, Start, [Interval], Proposal, [Usage], Comment)
        SELECT
            #TI.Dataset_ID,
            #TI.Start,
            CONVERT(FLOAT, ISNULL(xmlNode.value('@InstrumentAvailable', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
            '' AS Proposal,
            'AVAILABLE' AS Usage,                -- This is defined in T_EMSL_Instrument_Usage_Type
            #TI.Comment
        FROM #TI
        INNER JOIN #TR ON #TR.Dataset_ID = #TI.Dataset_ID
                CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

        INSERT INTO #TQ (Dataset_ID, Start, [Interval], Proposal, Users, [Usage], Comment)
        SELECT
            #TI.Dataset_ID,
            #TI.Start,
            (
             CONVERT(FLOAT, ISNULL(xmlNode.value('@User', 'varchar(32)'), '0')) +
             CONVERT(FLOAT, ISNULL(xmlNode.value('@UserRemote', 'varchar(32)'), '0')) +
             CONVERT(FLOAT, ISNULL(xmlNode.value('@UserOnsite', 'varchar(32)'), '0'))
            ) * #TR.[Interval] / 100 AS [Interval],
            xmlNode.value('@Proposal', 'varchar(32)') AS Proposal,
            xmlNode.value('@PropUser', 'varchar(32)') AS Users,
            Case When CONVERT(FLOAT, ISNULL(xmlNode.value('@UserRemote', 'varchar(32)'), '0')) > 0
            Then 'REMOTE'       -- Defined in T_EMSL_Instrument_Usage_Type; means we analyzed a sample for a person outside PNNL, typically as part of an EMSL User Project
            Else 'ONSITE'       -- Defined in T_EMSL_Instrument_Usage_Type; means we analyzed a sample for a PNNL staff member, or for an external collaborator who was actually onsite overseeing the data acquisition
            End AS Usage,
            #TI.Comment
        FROM #TI
        INNER JOIN #TR ON #TR.Dataset_ID = #TI.Dataset_ID
                CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

        ---------------------------------------------------
        -- Get rid of meaningless apportioned long intervals
        ---------------------------------------------------

        DELETE FROM #TQ WHERE [Interval] = 0

        IF @outputFormat = 'debug1'
        BEGIN
            SELECT * FROM #TQ
        END

        ---------------------------------------------------
        -- Clean up unecessary comments
        ---------------------------------------------------

        UPDATE #TQ
        SET Comment = ''
        WHERE Usage In ('CAP_DEV', 'ONSITE', 'REMOTE')

        ---------------------------------------------------
        -- Add apportioned long intervals to report table
        ---------------------------------------------------

        INSERT INTO #TR (
            Dataset_ID,
            [Type],
            Start,
            Duration,
            [Interval],
            Proposal,
            [Usage],
            Comment,
            Users,
            Operator
        )
        SELECT
            Dataset_ID,
            'Interval' AS [Type],
            Start,
            0 AS Duration,
            Interval,
            Proposal,
            Usage,
            Comment,
            Users,
            Operator
        FROM #TQ

        IF @outputFormat = 'debug2'
        BEGIN
            SELECT * FROM #TR
        END

        ---------------------------------------------------
        -- Zero interval values for datasets with long intervals
        ---------------------------------------------------

        UPDATE #TR
        SET [Interval] = 0
        WHERE [Type] = 'Dataset' AND [Normal] = 0

        ---------------------------------------------------
        -- Translate remaining DMS usage categories
        -- to EMSL usage categories
        ---------------------------------------------------

        UPDATE #TR
        SET [Usage] = 'ONSITE'
        WHERE [Usage] In ('USER', 'USER_ONSITE')

        UPDATE #TR
        SET [Usage] = 'REMOTE'
        WHERE [Usage] = 'USER_REMOTE'

        ---------------------------------------------------
        -- Remove artifacts
        ---------------------------------------------------

        DELETE FROM #TR WHERE Duration = 0 AND [Interval] = 0

        ---------------------------------------------------
        -- Add interval to duration for normal datasets
        ---------------------------------------------------

        UPDATE #TR
        SET Duration = Duration + [Interval],
            [Interval] = 0
        WHERE [Type] = 'Dataset' AND [Normal] > 0

        ---------------------------------------------------
        -- Uncomment to debug
        --
        -- SELECT * FROM #TR ORDER BY Start
        -- SELECT * FROM #TQ ORDER BY Start
        -- SELECT * FROM #TI
        -- SELECT * FROM #TF
        ---------------------------------------------------

        IF @outputFormat = 'debug3'
        BEGIN
            SELECT * FROM #TR
        END

        ---------------------------------------------------
        -- Provide output report according to mode
        ---------------------------------------------------

        IF @outputFormat = 'report'
        BEGIN
            ---------------------------------------------------
            -- Return results as a report
            ---------------------------------------------------

            If @eusInstrumentId = 0
            Begin
                -- Look up EMSL instrument ID for this instrument (will be null if not an EMSL tracked instrument)
                SELECT @eusInstrumentId = InstMapping.EUS_Instrument_ID
                FROM T_Instrument_Name AS InstName
                     LEFT OUTER JOIN T_EMSL_DMS_Instrument_Mapping AS InstMapping
                       ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
                WHERE InstName.IN_name = @instrument
            End
            Else
            Begin
                -- Look up DMS Instrument Name for this EUSInstrumentID
                SELECT TOP 1 @instrument = InstName.IN_name
                FROM T_Instrument_Name AS InstName
                     INNER JOIN T_EMSL_DMS_Instrument_Mapping AS InstMapping
                       ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
                WHERE InstMapping.EUS_Instrument_ID = @eusInstrumentID
                ORDER BY InstName.IN_name
            End

            -- Get user lists for datasets
            UPDATE #TR
            SET Users = '',
                Operator = ''
            WHERE #TR.[Type] = 'Dataset'

            UPDATE #TR
            SET Operator = TEU.PERSON_ID
            FROM #TR
                 INNER JOIN T_Dataset AS TD
                   ON #TR.Dataset_ID = TD.Dataset_ID
                 INNER JOIN T_Users AS TU
                   ON TD.DS_Oper_PRN = TU.U_PRN
                 INNER JOIN T_EUS_Users AS TEU
                   ON TU.U_HID = TEU.HID
            WHERE #TR.[Type] = 'Dataset'

            -- Get operator user ID for datasets
            UPDATE #TR
            SET Users = dbo.get_requested_run_eus_users_list(TRR.ID, 'I')
            FROM #TR
                 INNER JOIN dbo.T_Requested_Run TRR
                   ON #TR.Dataset_ID = TRR.DatasetID
            WHERE #TR.[Type] = 'Dataset'

            -- Get operator user ID for ONSITE and REMOTE intervals
            UPDATE #TR
            SET Operator = TEU.PERSON_ID
            FROM #TR
                 INNER JOIN dbo.T_Run_Interval TRI
                   ON TRI.ID = #TR.Dataset_ID
                 INNER JOIN T_Users AS TU
                   ON TRI.Entered_By = TU.U_PRN
                 INNER JOIN T_EUS_Users AS TEU
                   ON TU.U_HID = TEU.HID
            WHERE #TR.[Type] = 'Interval' AND
                  #TR.[Usage] In ('ONSITE', 'REMOTE')

            -- Output report rows
            SELECT
                @instrument AS Instrument,
                @eusInstrumentId AS EMSL_Inst_ID,
                CONVERT(VARCHAR(32), [Start], 100) AS [Start],
                [Type],
                CASE WHEN [Type] = 'Interval' THEN [Interval] ELSE Duration END AS [Minutes],
                Proposal,
                [Usage],
                Users,
                Operator,
                ISNULL(Comment, '') AS Comment,
                @year AS [Year],
                @month AS [Month],
                #TR.Dataset_ID
             FROM #TR
             ORDER BY Start
        END

        IF @outputFormat = 'details' OR @outputFormat = '' -- default mode
        BEGIN
            ---------------------------------------------------
            -- Return usage details
            ---------------------------------------------------

            SELECT
                CONVERT(VARCHAR(32), [Start], 100) AS [Start],
                [Type],
                CASE WHEN [Type] = 'Interval' THEN [Interval] ELSE Duration END AS [Minutes],
                Proposal,
                [Usage],
                ISNULL(Comment, '') AS Comment,
                Dataset_ID
             FROM #TR ORDER BY Start
        END

        IF @outputFormat = 'rollup'
        BEGIN
            ---------------------------------------------------
            -- Rollup by type, category, and proposal
            ---------------------------------------------------

            SELECT
                [Type],
                [Minutes],
                CONVERT(DECIMAL(10,1), CONVERT(FLOAT, [Minutes])/@minutesInMonth * 100.0) AS [Percentage],
                [Usage],
                Proposal
            FROM
            (
            SELECT
                [Type],
                SUM(CASE WHEN [Type] = 'Interval' THEN [Interval] ELSE Duration END) AS [Minutes],
                [Usage],
                Proposal
            FROM #TR
            GROUP BY [Type], [Usage], Proposal
            ) TQZ
            ORDER BY [Type], [Usage], Proposal
        END

        IF @outputFormat = 'check'
        BEGIN
            ---------------------------------------------------
            -- Check grand totals against available
            ---------------------------------------------------

            SELECT
                @minutesInMonth AS 'Available',
                SUM(Duration) AS Duration,
                SUM([Interval]) AS [Interval],
                SUM (Duration + INTERVAL) AS [Total],
                CONVERT(DECIMAL(10,1), CONVERT(FLOAT, SUM (Duration + INTERVAL))/@minutesInMonth * 100.0) AS [Percentage]
            FROM #TR
        END

    ---------------------------------------------------
    ---------------------------------------------------
    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec post_log_entry 'Error', @message, 'get_monthly_instrument_usage_report'
        End
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_monthly_instrument_usage_report] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_monthly_instrument_usage_report] TO [DMS2_SP_User] AS [dbo]
GO
