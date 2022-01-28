/****** Object:  UserDefinedFunction [dbo].[GetEMSLInstrumentUsageDaily] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetEMSLInstrumentUsageDaily]
/****************************************************
**  Desc: 
**      Outputs contents of EMSL instrument usage report table as rollup
**      This UDF is used by the CodeIgniter instance at http://prismsupport.pnl.gov/dms2ws/
**
**      Example URL:
**      https://prismsupport.pnl.gov/dms2ws/instrument_usage_report/daily/2019/03
**
**      See also /files1/www/html/prismsupport/dms2ws/application/controllers/Instrument_usage_report.php
**
**  Auth:   grk   
**  Date:   09/15/2015 grk - initial release
**          10/20/2015 grk - added users to output
**          02/10/2016 grk - added rollup of comments and operators
**          04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**          04/09/2020 mem - Truncate the concatenated comment if over 4090 characters long
**          04/17/2020 mem - Use Dataset_ID instead of ID
**    
*****************************************************/ 
(
    @Year INT, 
    @Month INT 
)
RETURNS @T_Report_Output TABLE
    (
      [EMSL_Inst_ID] [int] NULL,
      [Instrument] [varchar](64) NULL,
      [Type] [varchar](128) NULL,
      [Start] [datetime],
      [Minutes] [int],
      [Proposal] [varchar](32) NULL,
      [Usage] [varchar](32) NULL,
      [Users] [varchar](1024) NULL,
      [Operator] [varchar](64) NULL,
      [Comment] [varchar](4096) NULL,
      [Year] [int],
      [Month] [int],
      [ID] [int] NULL,
      [Seq] [int] NULL,
      [Updated] [datetime] NULL,
      [UpdatedBy] [varchar](32) NULL
    )
AS 
    BEGIN    
        -- Table for processing runs and intervals for reporting month
        Declare @T_Working TABLE
            (
              [Dataset_ID] INT NULL,
              [EMSL_Inst_ID] INT NULL,
              [DMS_Instrument] VARCHAR(64) NULL,
              [Type] VARCHAR(128) NULL,
              [Proposal] VARCHAR(32) NULL,
              [Users] [varchar](1024) NULL,
              [Usage] VARCHAR(32) NULL,
              [Start] DATETIME NULL,
              [End] DATETIME NULL,
              [EndOfDay] DATETIME NULL,
              [Year] INT NULL,
              [Month] INT NULL,
              [Day] INT NULL,
              [NextDay] INT NULL,
              [NextMonth] INT NULL,
              [BeginningOfNextDay] DATETIME NULL,
              [DurationSeconds] INT NULL,
              [DurationSecondsInCurrentDay] INT NULL,
              [RemainingDurationSeconds] INT NULL,
              Comment VARCHAR(MAX) NULL,
              [Operator] [varchar](64) NULL
            )

        -- Intermediate storage for report entries 
        Declare @T_Report_Accumulation TABLE
            (
              [Start] DATETIME,
              [DurationSeconds] INT,
              [Month] INT,
              [Day] INT,
              [EMSL_Inst_ID] INT,
              [DMS_Instrument] VARCHAR(64),
              [Proposal] VARCHAR(32),
              [Usage] VARCHAR(32),
              [Year] [int] NULL,
              [Type] [varchar](128),
              [Users] [varchar](1024) NULL,
              [Operator] [varchar](64) NULL,
              [Comment] [varchar](4096) NULL
            )
        
        -- Import entries from EMSL instrument usage table
        -- for given month and year into working table
        INSERT  INTO @T_Working
                ( Dataset_ID,
                  EMSL_Inst_ID,
                  [DMS_Instrument],
                  Type,
                  Proposal,
                  Usage,
                  Users,
                  [Start],
                  DurationSeconds,
                  Year,
                  Month,
                  Comment,
                  Operator
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
                       InstUsage.[Comment],
                       InstUsage.Operator
                FROM T_EMSL_Instrument_Usage_Report InstUsage
                     INNER JOIN T_Instrument_Name InstName
                       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
                     LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
                       ON InstUsage.Usage_Type = InstUsageType.ID
                WHERE (InstUsage.[Year] = @Year) AND
                      (InstUsage.[Month] = @Month)


        -- Repetitive process to pull records out of working table
        -- into accumulation table, allowing for durations that
        -- cross daily boundaries
        Declare @cnt INT = 1
        Declare @done INT = 0
        WHILE @done = 0 
        BEGIN -- <loop>

            -- Update working table with end times
            UPDATE  @T_Working
            SET     [Day] = DATEPART(DAY, [Start]),
                    [End] = DATEADD(second, [DurationSeconds], [Start]),
                    [NextDay] = DATEPART(Day,     DATEADD(second, [DurationSeconds], [Start])),
                    [NextMonth] = DATEPART(Month, DATEADD(second, [DurationSeconds], [Start])),
                    [EndOfDay] = DATEADD(ms, -2, DATEADD(dd, 1,DATEDIFF(dd, 0, [Start]))),
                    [BeginningOfNextDay] = DATEADD(day, 1, CAST([Start] AS DATE))
            -- 
            UPDATE  @T_Working
            SET     [DurationSecondsInCurrentDay] = DATEDIFF(second, [Start], EndOfDay),
                    [RemainingDurationSeconds] = [DurationSeconds] - DATEDIFF(second, [Start], EndOfDay)
                
            -- Copy usage records that do not span more than one day
            -- from working table to accumulation table, they are ready for report
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
                      [Type],
                      Comment,
                      Operator
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
                            [Type],
                            Comment,
                            Operator
                    FROM @T_Working
                    WHERE [Day] = [NextDay] AND
                          [Month] = [NextMonth]

            
            -- Remove report entries from working table 
            -- whose duration does not cross daily boundary
            DELETE  FROM @T_Working
            WHERE   RemainingDurationSeconds < 0 
            
            -- Copy report entries into accumulation table for
            -- remaining durations (cross daily boundaries) 
            -- using only duration time contained inside daily boundary
            INSERT INTO @T_Report_Accumulation
                    ( EMSL_Inst_ID,
                        DMS_Instrument,
                        Proposal,
                        Usage,
                        Users,
                        [Start],
                        [DurationSeconds],
                        [Year],
                        [Month],
                        [Day],
                        [Type],
                        Comment,
                        Operator
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
                            [Type],
                            Comment,
                            Operator
                    FROM @T_Working 

            -- Update start time and duration of entries in working table
            UPDATE @T_Working
            SET     [Start] = BeginningOfNextDay,
                    [DurationSeconds] = RemainingDurationSeconds,
                    [Day] = NULL,
                    [End] = NULL,
                    [NextDay] = NULL,
                    [EndOfDay] = NULL,
                    [BeginningOfNextDay] = NULL,
                    [DurationSecondsInCurrentDay] = NULL,
                    [RemainingDurationSeconds] = NULL
            
            -- We are done when there is nothing left to process in working table
            SELECT @cnt = COUNT(*)
            FROM @T_Working

            IF @cnt = 0 
                Set @done = 1

        END -- </loop>

        -- Rollup comments and add to the accumulation table
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
                                    DAY,
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
        UPDATE  TA
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

        -- Copy report entries from accumulation table to report output table
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
                  [ID],
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
                        NULL AS ID,
                        NULL AS Seq,
                        NULL AS Updated,
                        NULL AS UpdatedBy
                FROM @T_Report_Accumulation
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
GRANT VIEW DEFINITION ON [dbo].[GetEMSLInstrumentUsageDaily] TO [DDL_Viewer] AS [dbo]
GO
