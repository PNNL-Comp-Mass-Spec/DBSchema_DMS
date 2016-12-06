/****** Object:  UserDefinedFunction [dbo].[GetEMSLInstrumentUsageDaily] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetEMSLInstrumentUsageDaily]
/****************************************************
**	Desc: 
**  Outputs contents of EMSL instrument usage report table as rollup
**
**	This UDF is used by the CodeIgniter instance at http://prismsupport.pnl.gov/dms2ws/
**	Example URL:
**		http://prismsupport.pnl.gov/dms2ws/instrument_usage_report/ws/2015/07
**
**	See also /file1/www/html/prismsupport/dms2ws/application/controllers/instrument_usage_report.php
**
**	Return values: 
**
**	Parameters:
**	
**	Auth: grk   
**	Date: 09/15/2015 grk - initial release
**	      10/20/2015 grk - added users to output
**	      02/10/2016 grk - added rollup of comments and operators
**    
*****************************************************/ 
(
	@Year INT, 
	@Month INT 
)
RETURNS @T_Report_Output TABLE
    (
      [EMSL_Inst_ID] [int] NULL ,
      [Instrument] [varchar](64) NULL ,
      [Type] [varchar](128) NULL ,
      [Start] [datetime] ,
      [Minutes] [int] ,
      [Proposal] [varchar](32) NULL ,
      [Usage] [varchar](32) NULL ,
      [Users] [varchar](1024) NULL ,
      [Operator] [varchar](64) NULL ,
      [Comment] [varchar](4096) NULL ,
      [Year] [int] ,
      [Month] [int] ,
      [ID] [int] NULL ,
      [Seq] [int] NULL ,
      [Updated] [datetime] NULL ,
      [UpdatedBy] [varchar](32) NULL
    )
AS 
    BEGIN	
		-- table for processing runs and intervals for reporting month
        DECLARE @T_Working TABLE
            (
              [ID] INT NULL ,
              [EMSL_Inst_ID] INT NULL ,
              [DMS_Instrument] VARCHAR(64) NULL ,
              [Type] VARCHAR(128) NULL ,
              [Proposal] VARCHAR(32) NULL ,
              [Users] [varchar](1024) NULL ,
              [Usage] VARCHAR(32) NULL ,
              [Start] DATETIME NULL ,
              [End] DATETIME NULL ,
              [EndOfDay] DATETIME NULL ,
              [Year] INT NULL ,
              [Month] INT NULL ,
              [Day] INT NULL ,
              [NextDay] INT NULL ,
              [NextMonth] INT NULL ,
              [BeginningOfNextDay] DATETIME NULL ,
              [DurationSeconds] INT NULL ,
              [DurationSecondsInCurrentDay] INT NULL ,
              [RemainingDurationSeconds] INT NULL ,
              Comment VARCHAR(MAX) NULL ,
              [Operator] [varchar](64) NULL
            )

		-- intermediate storage for report entries 
        DECLARE @T_Report_Accumulation TABLE
            (
              [Start] DATETIME ,
              [DurationSeconds] INT ,
              [Month] INT ,
              [Day] INT ,
              [EMSL_Inst_ID] INT ,
              [DMS_Instrument] VARCHAR(64) ,
              [Proposal] VARCHAR(32) ,
              [Usage] VARCHAR(32) ,
              [Year] [int] NULL ,
              [Type] [varchar](128) ,
              [Users] [varchar](1024) NULL ,
              [Operator] [varchar](64) NULL ,
              [Comment] [varchar](4096) NULL
            )
		
		-- import entries from EMSL instrument usage table
		-- for given month and year
		-- into working table
        INSERT  INTO @T_Working
                ( ID ,
                  EMSL_Inst_ID ,
                  [DMS_Instrument] ,
                  Type ,
                  Proposal ,
                  Usage ,
                  Users ,
                  Start ,
                  DurationSeconds ,
                  Year ,
                  Month ,
                  Comment ,
                  Operator
                )
                SELECT  ID ,
                        EMSL_Inst_ID ,
                        Instrument AS [DMS_Instrument] ,
                        [Type] ,
                        Proposal ,
                        Usage ,
                        Users ,
                        Start ,
                        [Minutes] * 60 AS [DurationSeconds] ,
                        [Year] ,
                        [Month] ,
                        Comment ,
                        Operator
                FROM    T_EMSL_Instrument_Usage_Report AS TEIUR
                WHERE   ( TEIUR.Year = @Year )
                        AND ( TEIUR.Month = @Month )

		-- repetive process to pull records out of working table
		-- into accumulation table, allowing for durations that
		-- cross daily boundaries
        DECLARE @cnt INT = 1
        DECLARE @done INT = 0
        WHILE @done = 0 
            BEGIN --<loop>--

			-- update working table with end times
                UPDATE  @T_Working
                SET     [Day] = DATEPART(DAY, Start) ,
                        [End] = DATEADD(second, [DurationSeconds], Start) ,
                        [NextDay] = DATEPART(Day,
                                             DATEADD(second, [DurationSeconds],
                                                     Start)) ,
                        [NextMonth] = DATEPART(Month,
                                               DATEADD(second,
                                                       [DurationSeconds],
                                                       Start)) ,
                        [EndOfDay] = DATEADD(ms, -2,
                                             DATEADD(dd, 1,
                                                     DATEDIFF(dd, 0, Start))) ,
                        [BeginningOfNextDay] = DATEADD(day, 1,
                                                       CAST(Start AS DATE))
			-- 
                UPDATE  @T_Working
                SET     [DurationSecondsInCurrentDay] = DATEDIFF(second, Start,
                                                              EndOfDay) ,
                        [RemainingDurationSeconds] = [DurationSeconds]
                        - DATEDIFF(second, Start, EndOfDay)
				
			-- copy usage records that do not span more than one day
			-- from working table to accumulation table, they are ready for report
                INSERT  INTO @T_Report_Accumulation
                        ( EMSL_Inst_ID ,
                          DMS_Instrument ,
                          Proposal ,
                          Usage ,
                          Users ,
                          [Start] ,
					--Minutes,
                          [DurationSeconds] ,
                          [Year] ,
                          [Month] ,
                          [Day] ,
                          [Type] ,
                          Comment ,
                          Operator
                        )
                        SELECT  EMSL_Inst_ID ,
                                DMS_Instrument ,
                                Proposal ,
                                Usage ,
                                Users ,
                                [Start] ,
                                [DurationSeconds] ,
                                [Year] ,
                                [Month] ,
                                [Day] ,
                                [Type] ,
                                Comment ,
                                Operator
                        FROM    @T_Working
                        WHERE   [Day] = [NextDay]
                                AND [MONTH] = [NextMonth]

			
			-- remove report entries from working table 
			-- whose duration does not cross daily boundary
                DELETE  FROM @T_Working
                WHERE   RemainingDurationSeconds < 0 
			
			-- copy report entries into accumulation table for
			-- remaining durations (cross daily boundaries) 
			-- using only duration time contained inside daily boundary
                INSERT  INTO @T_Report_Accumulation
                        ( EMSL_Inst_ID ,
                          DMS_Instrument ,
                          Proposal ,
                          Usage ,
                          Users ,
                          [Start] ,
                          [DurationSeconds] ,
                          [Year] ,
                          [Month] ,
                          [Day] ,
                          [Type] ,
                          Comment ,
                          Operator
                        )
                        SELECT  EMSL_Inst_ID ,
                                DMS_Instrument ,
                                Proposal ,
                                Usage ,
                                Users ,
                                [Start] ,
                                [DurationSecondsInCurrentDay] AS [DurationSeconds] ,
                                [Year] ,
                                [Month] ,
                                [Day] ,
                                [Type] ,
                                Comment ,
                                Operator
                        FROM    @T_Working 

			-- update start time and duration of entries in working table
                UPDATE  @T_Working
                SET     [Start] = BeginningOfNextDay ,
                        [DurationSeconds] = RemainingDurationSeconds ,
                        [Day] = NULL ,
                        [End] = NULL ,
                        [NextDay] = NULL ,
                        [EndOfDay] = NULL ,
                        [BeginningOfNextDay] = NULL ,
                        [DurationSecondsInCurrentDay] = NULL ,
                        [RemainingDurationSeconds] = NULL
			
			-- we are done when there is nothing left to process in working table
                SELECT  @cnt = COUNT(*)
                FROM    @T_Working
                IF @cnt = 0 
                    SET @done = 1
            END
 --<loop>

-- rollup comments and add to the accumulation table
        UPDATE  @T_Report_Accumulation
        SET     Comment = TZ.Comment
        FROM    @T_Report_Accumulation AS TA
                INNER JOIN ( SELECT EMSL_Inst_ID ,
                                    DMS_Instrument ,
                                    [Type] ,
                                    Proposal ,
                                    Usage ,
                                    Users ,
                                    Year ,
                                    Month ,
                                    DAY ,
                                    STUFF(( SELECT DISTINCT
                                                    ',' + Comment AS [text()]
                                            FROM    @T_Report_Accumulation TS
                                            WHERE   TX.EMSL_Inst_ID = TS.EMSL_Inst_ID
                                                    AND TX.DMS_Instrument = TS.DMS_Instrument
                                                    AND TX.[Type] = TS.[Type]
                                                    AND TX.Proposal = TS.Proposal
                                                    AND TX.Usage = TS.Usage
                                                    AND TX.Users = TS.Users
                                                    AND TX.[Year] = TS.[Year]
                                                    AND TX.[Month] = TS.[Month]
                                                    AND TX.[Day] = TS.[Day]
                                          FOR
                                            XML PATH('')
                                          ), 1, 1, '') AS [Comment]
                             FROM   @T_Report_Accumulation TX
                             GROUP BY EMSL_Inst_ID ,
                                    DMS_Instrument ,
                                    [Type] ,
                                    Proposal ,
                                    Usage ,
                                    Users ,
                                    [Year] ,
                                    [Month] ,
                                    [Day]
                           ) AS TZ ON TA.EMSL_Inst_ID = TZ.EMSL_Inst_ID
                                      AND TA.DMS_Instrument = TZ.DMS_Instrument
                                      AND TA.[Type] = TZ.[Type]
                                      AND TA.Proposal = TZ.Proposal
                                      AND TA.Usage = TZ.Usage
                                      AND TA.Users = TZ.Users
                                      AND TA.[Year] = TZ.[Year]
                                      AND TA.[Month] = TZ.[Month]
                                      AND TA.[Day] = TZ.[Day]

-- rollup operators and add to the accumulation table
        UPDATE  TA
        SET     Operator = TZ.Operator
        FROM    @T_Report_Accumulation AS TA
                INNER JOIN ( SELECT EMSL_Inst_ID ,
                                    DMS_Instrument ,
                                    [Type] ,
                                    Proposal ,
                                    Usage ,
                                    Users ,
                                    Year ,
                                    Month ,
                                    DAY ,
                                    STUFF(( SELECT DISTINCT
                                                    ',' + Operator AS [text()]
                                            FROM    @T_Report_Accumulation TS
                                            WHERE   TX.EMSL_Inst_ID = TS.EMSL_Inst_ID
                                                    AND TX.DMS_Instrument = TS.DMS_Instrument
                                                    AND TX.[Type] = TS.[Type]
                                                    AND TX.Proposal = TS.Proposal
                                                    AND TX.Usage = TS.Usage
                                                    AND TX.Users = TS.Users
                                                    AND TX.[Year] = TS.[Year]
                                                    AND TX.[Month] = TS.[Month]
                                                    AND TX.[Day] = TS.[Day]
                                          FOR
                                            XML PATH('')
                                          ), 1, 1, '') AS Operator
                             FROM   @T_Report_Accumulation TX
                             GROUP BY EMSL_Inst_ID ,
                                    DMS_Instrument ,
                                    [Type] ,
                                    Proposal ,
                                    Usage ,
                                    Users ,
                                    [Year] ,
                                    [Month] ,
                                    [Day]
                           ) AS TZ ON TA.EMSL_Inst_ID = TZ.EMSL_Inst_ID
                                      AND TA.DMS_Instrument = TZ.DMS_Instrument
                                      AND TA.[Type] = TZ.[Type]
                                      AND TA.Proposal = TZ.Proposal
                                      AND TA.Usage = TZ.Usage
                                      AND TA.Users = TZ.Users
                                      AND TA.[Year] = TZ.[Year]
                                      AND TA.[Month] = TZ.[Month]
                                      AND TA.[Day] = TZ.[Day]

		-- copy report entries from accumuation table to report output table
        INSERT  INTO @T_Report_Output
                ( [EMSL_Inst_ID] ,
                  [Instrument] ,
                  [Type] ,
                  [Start] ,
                  [Minutes] ,
                  [Proposal] ,
                  [Usage] ,
                  [Users] ,
                  [Operator] ,
                  [Comment] ,
                  [Year] ,
                  [Month] ,
                  [ID] ,
                  [Seq] ,
                  [Updated] ,
                  [UpdatedBy] 
                )
                SELECT  EMSL_Inst_ID ,
                        DMS_Instrument AS Instrument ,
                        [Type] ,
                        MIN(Start) AS Start ,
                        CEILING(CONVERT(FLOAT, SUM([DurationSeconds])) / 60) AS [Minutes] ,
                        Proposal ,
                        Usage ,
                        Users ,
                        Operator ,
                        Comment ,
                        Year ,
                        Month ,
                        NULL AS ID ,
                        NULL AS Seq ,
                        NULL AS Updated ,
                        NULL AS UpdatedBy
                FROM    @T_Report_Accumulation
                GROUP BY EMSL_Inst_ID ,
                        DMS_Instrument ,
                        [Type] ,
                        Proposal ,
                        Usage ,
                        Users ,
                        Operator ,
                        Comment ,
                        [Year] ,
                        [Month] ,
                        [Day]
                ORDER BY EMSL_Inst_ID DESC ,
                        DMS_Instrument DESC ,
                        [Month] DESC ,
                        [Day] ASC ,
                        START ASC

        RETURN
    END


GO
GRANT VIEW DEFINITION ON [dbo].[GetEMSLInstrumentUsageDaily] TO [DDL_Viewer] AS [dbo]
GO
