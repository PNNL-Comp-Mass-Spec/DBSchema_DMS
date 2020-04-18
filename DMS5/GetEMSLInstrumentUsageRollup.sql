/****** Object:  UserDefinedFunction [dbo].[GetEMSLInstrumentUsageRollup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetEMSLInstrumentUsageRollup]
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
**	Auth:	grk   
**	Date:	09/11/2012 grk - initial release
**			04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**          04/17/2020 mem - Use Dataset_ID instead of ID
**    
*****************************************************/ 
( 
	@Year INT, 
	@Month INT 
)
RETURNS @T_Report_Output TABLE
	(
		[EMSL_Inst_ID] [int] ,
		[DMS_Instrument] [varchar](64) ,
		[Month] INT,
		[Day] INT,
		[Proposal] [varchar](32) ,
		[Usage] [varchar](32) ,
		[Minutes] [int] 
	)
AS 
	BEGIN	
		-- table for processing runs and intervals for reporting month
		DECLARE @T_Working TABLE
		(
			[Dataset_ID] INT NULL,
			[EMSL_Inst_ID] INT NULL,
			[DMS_Instrument] VARCHAR(64) NULL,
			[Type] VARCHAR(128) NULL,
			[Proposal] VARCHAR(32) NULL,
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
			[RemainingDurationSeconds]  INT NULL
		)

		-- intermediate storage for report entries 
		DECLARE @T_Report_Accumulation TABLE
		(
			[Start] DATETIME,
			[DurationSeconds] INT,
			[Month] INT,
			[Day] INT,
			[EMSL_Inst_ID] INT ,
			[DMS_Instrument] VARCHAR(64) ,
			[Proposal] VARCHAR(32) ,
			[Usage] VARCHAR(32) 
		)
		
		-- import entries from EMSL instrument usage table
		-- for given month and year
		-- into working table
		INSERT INTO @T_Working (
			Dataset_ID,
			EMSL_Inst_ID,
			[DMS_Instrument],
			Type,
			Proposal,
			Usage,
			Start,
			DurationSeconds,
			Year,
			Month
		)
		SELECT InstUsage.Dataset_ID,
		       InstUsage.EMSL_Inst_ID,
		       InstName.IN_Name AS [DMS_Instrument],
		       InstUsage.[Type],
		       InstUsage.Proposal,
		       InstUsageType.Name AS [Usage],
		       InstUsage.Start,
		       InstUsage.[Minutes] * 60 AS [DurationSeconds],
		       InstUsage.[Year],
		       InstUsage.[Month]
		FROM T_EMSL_Instrument_Usage_Report InstUsage
		     INNER JOIN T_Instrument_Name InstName
		       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
		     LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
		       ON InstUsage.Usage_Type = InstUsageType.ID
		WHERE (InstUsage.[Year] = @Year) AND
		      (InstUsage.[Month] = @Month)


		-- repetitive process to pull records out of working table
		-- into accumulation table, allowing for durations that
		-- cross daily boundaries
		DECLARE @cnt INT = 1
		DECLARE @done INT = 0
		WHILE @done = 0
		BEGIN --<loop>--

			-- update working table with end times
			UPDATE @T_Working
			SET
				[Day] = DATEPART(DAY, Start),
				[End] = DATEADD(second, [DurationSeconds], Start),
				[NextDay] = DATEPART(Day, DATEADD(second, [DurationSeconds], Start)),
				[NextMonth] = DATEPART(Month, DATEADD(second, [DurationSeconds], Start)),
				[EndOfDay] = DATEADD(ms, -2, DATEADD(dd, 1, DATEDIFF(dd, 0, Start))),
				[BeginningOfNextDay] = DATEADD(day, 1, CAST(Start As Date))
			-- 
			UPDATE @T_Working
			SET
				[DurationSecondsInCurrentDay] = DATEDIFF(second, Start, EndOfDay),
				[RemainingDurationSeconds] = [DurationSeconds] - DATEDIFF(second, Start, EndOfDay)

--SELECT * FROM @T_Working ORDER BY EMSL_Inst_ID, DMS_Instrument, [Month], [Day], [DurationSeconds] DESC
				
			-- copy usage records that do not span more than one day
			-- from working table to accumulation table, they are ready for report
			INSERT INTO @T_Report_Accumulation ( 
					EMSL_Inst_ID ,
					DMS_Instrument,
					Proposal ,
					Usage ,
					[Start],
					--Minutes,
					[DurationSeconds],
					[Month],
					[Day]	 
				)
			SELECT 
					EMSL_Inst_ID ,
					DMS_Instrument,
					Proposal ,
					Usage ,
					[Start],
					[DurationSeconds],
					[Month],
					[Day]
			FROM @T_Working 
			WHERE [Day] = [NextDay] AND [MONTH] = [NextMonth]

			
			-- remove report entries from working table 
			-- whose duration does not cross daily boundary
			DELETE FROM @T_Working WHERE RemainingDurationSeconds < 0 
			
			-- copy report entries into accumulation table for
			-- remaining durations (cross daily boundaries) 
			-- using only duration time contained inside daily boundary
			INSERT INTO @T_Report_Accumulation ( 
					EMSL_Inst_ID ,
					DMS_Instrument,
					Proposal ,
					Usage ,
					[Start],
					[DurationSeconds],
					[Month],
					[Day]	 
				)
			SELECT 
					EMSL_Inst_ID ,
					DMS_Instrument,
					Proposal ,
					Usage ,
					[Start],
					[DurationSecondsInCurrentDay] AS [DurationSeconds],
					[Month],
					[Day]
			FROM @T_Working 

			-- update start time and duration of entries in working table
			UPDATE @T_Working
			SET
				[Start] = BeginningOfNextDay,
				[DurationSeconds] = RemainingDurationSeconds,
				[Day] = null,
				[End] = null,
				[NextDay] = null,
				[EndOfDay] = null,
				[BeginningOfNextDay] = NULL,
				[DurationSecondsInCurrentDay] = NULL,
				[RemainingDurationSeconds] = NULL
			
			-- we are done when there is nothing left to process in working table
			SELECT @cnt = COUNT(*) FROM @T_Working
			IF @cnt = 0 SET @done = 1
		END --<loop>					
		
		-- copy report entries from accumulation table to report output table
		INSERT INTO @T_Report_Output ( 
				EMSL_Inst_ID ,
				DMS_Instrument,
				Proposal ,
				Usage ,
				Minutes,
				[Month],
				[Day]	 
			)
			SELECT EMSL_Inst_ID ,
					DMS_Instrument ,
					Proposal ,
					Usage ,
					--ROUND(SUM([DurationSeconds])/60, 1) AS [Minutes],
					CEILING(CONVERT(FLOAT, SUM([DurationSeconds]))/60)  AS [Minutes],
					[Month],
					[Day]
			FROM @T_Report_Accumulation
			GROUP BY EMSL_Inst_ID ,
					DMS_Instrument ,
					Proposal ,
					Usage ,
					[Month],
					[Day]
			ORDER BY EMSL_Inst_ID, DMS_Instrument, [Month], [Day], [Minutes] DESC
							
		RETURN
	END


GO
GRANT VIEW DEFINITION ON [dbo].[GetEMSLInstrumentUsageRollup] TO [DDL_Viewer] AS [dbo]
GO
