/****** Object:  UserDefinedFunction [dbo].[get_emsl_instrument_usage_daily_details] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_emsl_instrument_usage_daily_details]
/****************************************************
**  Desc:
**      Outputs contents of EMSL instrument usage report table as a daily rollup, including rows with Dataset_ID_Acq_Overlap
**      This UDF is used by the CodeIgniter instance at http://prismsupport.pnl.gov/dms2ws/
**
**      Example URL:
**      https://prismsupport.pnl.gov/dms2ws/instrument_usage_report/dailydetails/2020/03
**
**      See also /file1/www/html/prismsupport/dms2ws/application/controllers/instrument_usage_report.php
**
**  Auth:   grk
**  Date:   09/15/2015 grk - initial release, modeled after get_emsl_instrument_usage_daily
**          10/20/2015 grk - added users to output
**          02/10/2016 grk - added rollup of comments and operators
**          04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**          04/09/2020 mem - Truncate the concatenated comment if over 4090 characters long
**          04/18/2020 mem - Update to show dataset details for all datasets that are not Maintenance runs
**                         - Saved as new UDF named get_emsl_instrument_usage_daily_details
**          04/27/2020 mem - Populate the Seq column using Seq values in T_EMSL_Instrument_Usage_Report
**          03/17/2022 mem - Add ID_Acq_Overlap (from Dataset_ID_Acq_Overlap) to the output
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @year int,
    @month int
)
RETURNS @T_Report_Output TABLE
    (
      [EMSL_Inst_ID] [int] NULL,
      [Instrument] [varchar](64) NULL,
      [Type] [varchar](128) NULL,       -- Dataset or Interval
      [Start] [datetime],
      [Minutes] [int],
      [Proposal] [varchar](32) NULL,
      [Usage] [varchar](32) NULL,
      [Users] [varchar](1024) NULL,
      [Operator] [varchar](64) NULL,    -- Could be a comma separated list of Operator IDs
      [Comment] [varchar](4096) NULL,
      [Year] [int],
      [Month] [int],
      [ID] [int] NULL,                  -- Dataset_ID
      [ID_Acq_Overlap] [int] Null,      -- Dataset_ID_Acq_Overlap
      [Seq] [int] NULL,
      [Updated] [datetime] NULL,
      [UpdatedBy] [varchar](32) NULL
    )
AS
    BEGIN
        -- Table for processing runs and intervals for reporting month
        Declare @T_Working TABLE
            (
              [Dataset_ID] int NULL,
              [EMSL_Inst_ID] int NULL,
              [DMS_Instrument] varchar(64) NULL,
              [Type] varchar(128) NULL,         -- Dataset or Interval
              [Proposal] varchar(32) NULL,
              [Users] [varchar](1024) NULL,
              [Usage] varchar(32) NULL,
              [Start] datetime NULL,
              [End] datetime NULL,
              [EndOfDay] datetime NULL,
              [Year] int NULL,
              [Month] int NULL,
              [Day] int NULL,
              [DayAtRunEnd] int NULL,
              [MonthAtRunEnd] int NULL,
              [BeginningOfNextDay] datetime NULL,
              [DurationSeconds] int NULL,
              [DurationSecondsInCurrentDay] int NULL,
              [RemainingDurationSeconds] int NULL,
              [Dataset_ID_Acq_Overlap] int NULL,
              Comment varchar(MAX) NULL,
              [Operator] int NULL,
              [Seq] int NULL
            )

        -- Intermediate storage for report entries
        --
        Declare @T_Report_Accumulation TABLE
            (
              [Start] datetime,
              [DurationSeconds] int,
              [Month] int,
              [Day] int,
              [Dataset_ID] int,
              [EMSL_Inst_ID] int,
              [DMS_Instrument] varchar(64),
              [Proposal] varchar(32),
              [Usage] varchar(32),
              [Year] [int] NULL,
              [Type] [varchar](128),
              [Users] [varchar](1024) NULL,
              [Operator] [varchar](64) NULL,        -- Could be a comma separated list of Operator IDs
              [Dataset_ID_Acq_Overlap] int NULL,
              [Comment] [varchar](4096) NULL,
              [Seq] int NULL
            )

        -- Import entries from EMSL instrument usage table
        -- for given month and year into working table
        INSERT  INTO @T_Working
                ( Dataset_ID,
                  EMSL_Inst_ID,
                  [DMS_Instrument],
                  Type,             -- Dataset or Interval
                  Proposal,
                  Usage,
                  Users,
                  [Start],
                  DurationSeconds,
                  Year,
                  Month,
                  Dataset_ID_Acq_Overlap,
                  Comment,
                  Operator,
                  [Seq]
                )
                SELECT InstUsage.Dataset_ID,
                       InstUsage.EMSL_Inst_ID,
                       InstName.IN_Name AS [DMS_Instrument],
                       InstUsage.[Type],
                       InstUsage.Proposal,
                       InstUsageType.Name AS [Usage],
                       InstUsage.Users,
                       InstUsage.[Start],
                       InstUsage.[Minutes] * 60 AS [DurationSeconds],
                       InstUsage.[Year],
                       InstUsage.[Month],
                       InstUsage.Dataset_ID_Acq_Overlap,
                       InstUsage.[Comment],
                       InstUsage.Operator,
                       InstUsage.Seq
                FROM T_EMSL_Instrument_Usage_Report InstUsage
                     INNER JOIN T_Instrument_Name InstName
                       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
                     LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
                       ON InstUsage.Usage_Type = InstUsageType.ID
                WHERE InstUsage.[Year] = @Year AND
                      InstUsage.[Month] = @Month

        -- Repetitive process to pull records out of working table
        -- into accumulation table
        --
        -- For datasets that start on one day and end on another day (i.e. are mid-acquisition at midnight)
        -- we will copy those datasets into @T_Report_Accumulation twice (or three times if the run lasts 3 days)
        -- This is done so that we can accurately record instrument usage time on the first day, plus the additional time used on the second day
        --
        -- For example, if a dataset is 30 minutes long and is started at 11:40 pm on April 17,
        -- this dataset will be listed in @T_Report_Accumulation as:
        --  a. starting at 11:40 pm on April 17 and lasting 20 minutes
        --  b. starting at 12:00 am on April 18 and lasting 10 minutes

        Declare @done int = 0

        WHILE @done = 0
        BEGIN -- <loop>

            -- Update working table with end times
            UPDATE  @T_Working
            SET     [Day] = DATEPART(day, [Start]),
                    [End] = DATEADD(second, [DurationSeconds], [Start]),
                    [DayAtRunEnd] = DATEPART(day,     DATEADD(second, [DurationSeconds], [Start])),
                    [MonthAtRunEnd] = DATEPART(month, DATEADD(second, [DurationSeconds], [Start])),
                    [EndOfDay] = DATEADD(ms, -2, DATEADD(dd, 1,DATEDIFF(dd, 0, [Start]))),
                    [BeginningOfNextDay] = DATEADD(day, 1, CAST([Start] AS DATE))
            --
            UPDATE  @T_Working
            SET     [DurationSecondsInCurrentDay] = DATEDIFF(second, [Start], EndOfDay),
                    [RemainingDurationSeconds] = [DurationSeconds] - DATEDIFF(second, [Start], EndOfDay)

            -- Copy usage records that do not span more than one day
            -- from working table to accumulation table
            INSERT INTO @T_Report_Accumulation
                    ( EMSL_Inst_ID,
                      DMS_Instrument,
                      Proposal,
                      Usage,
                      Users,
                      [Start],
                      --Minutes,
                      [DurationSeconds],
                      [Year],
                      [Month],
                      [Day],
                      [Dataset_ID],
                      [Type],
                      Dataset_ID_Acq_Overlap,
                      Comment,
                      Operator,
                      [Seq]
                    )
                    SELECT  EMSL_Inst_ID,
                            DMS_Instrument,
                            Proposal,
                            Usage,
                            Users,
                            [Start],
                            [DurationSeconds],
                            [Year],
                            [Month],
                            [Day],
                            Dataset_ID,
                            [Type],
                            Dataset_ID_Acq_Overlap,
                            Comment,
                            Cast(Operator as varchar(12)),
                            [Seq]
                    FROM @T_Working
                    WHERE [Day] = [DayAtRunEnd] AND
                          [Month] = [MonthAtRunEnd]

            -- Remove the usage records that we just copied into @T_Report_Accumulation
            DELETE  FROM @T_Working
            WHERE   [Day] = [DayAtRunEnd] AND
                    [Month] = [MonthAtRunEnd]

            -- Also remove any rows that have a negative value for RemainingDurationSeconds
            -- This will be true for any datasets that were started in the evening on the last day of the month
            -- and were still acquiring data when we reached midnight and entered a new month
            DELETE  FROM @T_Working
            WHERE   RemainingDurationSeconds < 0

            -- Copy report entries into accumulation table for
            -- remaining durations (datasets that cross daily boundaries)
            -- using only duration time contained inside the daily boundary
            INSERT INTO @T_Report_Accumulation
                    (   EMSL_Inst_ID,
                        DMS_Instrument,
                        Proposal,
                        Usage,
                        Users,
                        [Start],
                        [DurationSeconds],
                        [Year],
                        [Month],
                        [Day],
                        [Dataset_ID],
                        [Type],
                        Dataset_ID_Acq_Overlap,
                        Comment,
                        Operator,
                        [Seq]
                    )
                    SELECT  EMSL_Inst_ID,
                            DMS_Instrument,
                            Proposal,
                            Usage,
                            Users,
                            [Start],
                            [DurationSecondsInCurrentDay] AS [DurationSeconds],
                            [Year],
                            [Month],
                            [Day],
                            [Dataset_ID],
                            [Type],
                            Dataset_ID_Acq_Overlap,
                            Comment,
                            Cast(Operator as varchar(12)),
                            [Seq]
                    FROM @T_Working

            -- Update start time and duration of entries in working table
            UPDATE @T_Working
            SET     [Start] = BeginningOfNextDay,
                    [DurationSeconds] = RemainingDurationSeconds,
                    [Day] = NULL,
                    [End] = NULL,
                    [DayAtRunEnd] = NULL,
                    [MonthAtRunEnd] = NULL,
                    [EndOfDay] = NULL,
                    [BeginningOfNextDay] = NULL,
                    [DurationSecondsInCurrentDay] = NULL,
                    [RemainingDurationSeconds] = NULL

            -- We are done when there is nothing left to process in working table
            IF NOT EXISTS (SELECT * FROM @T_Working)
            Begin
                Set @done = 1
            End

        END -- </loop>

        ----------------------------------------------------
        -- Rollup comments and update the accumulation table
        -- Only do this rollup for rows where the usage is 'AVAILABLE', 'BROKEN', or 'MAINTENANCE'
        ----------------------------------------------------

        UPDATE @T_Report_Accumulation
        SET Comment = CASE WHEN LEN(TZ.Comment) > 4090 THEN SUBSTRING(TZ.Comment, 1, 4090) + ' ...' ELSE TZ.Comment End
        FROM @T_Report_Accumulation AS TA
                INNER JOIN ( SELECT EMSL_Inst_ID,
                                    DMS_Instrument,
                                    [Type],
                                    Proposal,
                                    Usage,
                                    Users,
                                    Year,
                                    Month,
                                    Day,
                                    STUFF(( SELECT DISTINCT
                                                    ',' + Comment AS [text()]
                                            FROM    @T_Report_Accumulation TS
                                            WHERE   TX.EMSL_Inst_ID = TS.EMSL_Inst_ID AND
                                                    TX.DMS_Instrument = TS.DMS_Instrument AND
                                                    TX.[Type] = TS.[Type] AND
                                                    TX.Proposal = TS.Proposal AND
                                                    TX.Usage = TS.Usage AND
                                                    TX.Users = TS.Users AND
                                                    TX.[Year] = TS.[Year] AND
                                                    TX.[Month] = TS.[Month] AND
                                                    TX.[Day] = TS.[Day]
                                          FOR
                                            XML PATH('')
                                          ), 1, 1, '') AS [Comment]
                             FROM   @T_Report_Accumulation TX
                             WHERE TX.Usage IN ('AVAILABLE', 'BROKEN', 'MAINTENANCE')
                             GROUP BY EMSL_Inst_ID,
                                    DMS_Instrument,
                                    [Type],
                                    Proposal,
                                    Usage,
                                    Users,
                                    [Year],
                                    [Month],
                                    [Day]
                           ) AS TZ ON TA.EMSL_Inst_ID = TZ.EMSL_Inst_ID AND
                                      TA.DMS_Instrument = TZ.DMS_Instrument AND
                                      TA.[Type] = TZ.[Type] AND
                                      TA.Proposal = TZ.Proposal AND
                                      TA.Usage = TZ.Usage AND
                                      TA.Users = TZ.Users AND
                                      TA.[Year] = TZ.[Year] AND
                                      TA.[Month] = TZ.[Month] AND
                                      TA.[Day] = TZ.[Day]

        -- Rollup operators and add to the accumulation table
        UPDATE  @T_Report_Accumulation
        SET     Operator = TZ.Operator
        FROM    @T_Report_Accumulation AS TA
                INNER JOIN ( SELECT EMSL_Inst_ID,
                                    DMS_Instrument,
                                    [Type],
                                    Proposal,
                                    Usage,
                                    Users,
                                    Year,
                                    Month,
                                    DAY,
                                    STUFF(( SELECT DISTINCT
                                                    ',' + Operator AS [text()]
                                            FROM    @T_Report_Accumulation TS
                                            WHERE   TX.EMSL_Inst_ID = TS.EMSL_Inst_ID AND
                                                    TX.DMS_Instrument = TS.DMS_Instrument AND
                                                    TX.[Type] = TS.[Type] AND
                                                    TX.Proposal = TS.Proposal AND
                                                    TX.Usage = TS.Usage AND
                                                    TX.Users = TS.Users AND
                                                    TX.[Year] = TS.[Year] AND
                                                    TX.[Month] = TS.[Month] AND
                                                    TX.[Day] = TS.[Day]
                                          FOR
                                            XML PATH('')
                                          ), 1, 1, '') AS Operator
                             FROM   @T_Report_Accumulation TX
                             WHERE TX.Usage IN ('AVAILABLE', 'BROKEN', 'MAINTENANCE')
                             GROUP BY EMSL_Inst_ID,
                                    DMS_Instrument,
                                    [Type],
                                    Proposal,
                                    Usage,
                                    Users,
                                    [Year],
                                    [Month],
                                    [Day]
                           ) AS TZ ON TA.EMSL_Inst_ID = TZ.EMSL_Inst_ID AND
                                      TA.DMS_Instrument = TZ.DMS_Instrument AND
                                      TA.[Type] = TZ.[Type] AND
                                      TA.Proposal = TZ.Proposal AND
                                      TA.Usage = TZ.Usage AND
                                      TA.Users = TZ.Users AND
                                      TA.[Year] = TZ.[Year] AND
                                      TA.[Month] = TZ.[Month] AND
                                      TA.[Day] = TZ.[Day]


        ----------------------------------------------------
        -- Copy report entries from accumulation table to report output table
        ----------------------------------------------------

        -- First add non-maintenance datasets
        -- Include each dataset as a separate row
        --
        INSERT  INTO @T_Report_Output
                ( [EMSL_Inst_ID],
                  [Instrument],
                  [Type],
                  [Start],
                  [Minutes],
                  [Proposal],
                  [Usage],
                  [Users],
                  [Operator],
                  [Comment],
                  [Year],
                  [Month],
                  [ID],                 -- Dataset_ID
                  [ID_Acq_Overlap],     -- Dataset_ID_Acq_Overlap
                  [Seq],
                  [Updated],
                  [UpdatedBy]
                )
                SELECT  EMSL_Inst_ID,
                        DMS_Instrument AS Instrument,
                        [Type],
                        MIN([Start]) AS [Start],
                        CEILING(CONVERT(FLOAT, SUM([DurationSeconds])) / 60) AS [Minutes],
                        Proposal,
                        Usage,
                        Users,
                        Operator,
                        Comment,
                        Year,
                        Month,
                        Dataset_ID,
                        Dataset_ID_Acq_Overlap,
                        MIN([Seq]),
                        NULL AS Updated,
                        NULL AS UpdatedBy
                FROM @T_Report_Accumulation
                WHERE NOT Usage IN ('AVAILABLE', 'BROKEN', 'MAINTENANCE')
                GROUP BY EMSL_Inst_ID,
                        DMS_Instrument,
                        [Type],
                        Proposal,
                        Usage,
                        Users,
                        Operator,
                        Comment,
                        [Year],
                        [Month],
                        [Day],
                        Dataset_ID,
                        Dataset_ID_Acq_Overlap
                ORDER BY EMSL_Inst_ID DESC,
                         DMS_Instrument DESC,
                         [Month] DESC,
                         [Day] ASC,
                         [Start] ASC

        -- Next, add maintenance datasets, where we report one entry per day
        --
        INSERT  INTO @T_Report_Output
                ( [EMSL_Inst_ID],
                  [Instrument],
                  [Type],
                  [Start],
                  [Minutes],
                  [Proposal],
                  [Usage],
                  [Users],
                  [Operator],
                  [Comment],
                  [Year],
                  [Month],
                  [ID],                 -- Dataset_ID
                  [ID_Acq_Overlap],     -- Dataset_ID_Acq_Overlap
                  [Seq],
                  [Updated],
                  [UpdatedBy]
                )
                SELECT  EMSL_Inst_ID,
                        DMS_Instrument AS Instrument,
                        [Type],
                        MIN([Start]) AS [Start],
                        CEILING(CONVERT(FLOAT, SUM([DurationSeconds])) / 60) AS [Minutes],
                        Proposal,
                        Usage,
                        Users,
                        Operator,
                        Comment,
                        Year,
                        Month,
                        NULL AS Dataset_ID,             -- Store null since we're rolling up multiple rows
                        NULL As Dataset_ID_Acq_Overlap,
                        MIN([Seq]),
                        NULL AS Updated,
                        NULL AS UpdatedBy
                FROM @T_Report_Accumulation
                WHERE Usage IN ('AVAILABLE', 'BROKEN', 'MAINTENANCE')
                GROUP BY EMSL_Inst_ID,
                        DMS_Instrument,
                        [Type],
                        Proposal,
                        Usage,
                        Users,
                        Operator,
                        Comment,
                        [Year],
                        [Month],
                        [Day]
                ORDER BY EMSL_Inst_ID DESC,
                         DMS_Instrument DESC,
                         [Month] DESC,
                         [Day] ASC,
                         [Start] ASC

        RETURN
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_emsl_instrument_usage_daily_details] TO [DDL_Viewer] AS [dbo]
GO
