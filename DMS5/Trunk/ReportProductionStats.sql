/****** Object:  StoredProcedure [dbo].[ReportProductionStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.ReportProductionStats
/****************************************************
**
**	Desc: Generates dataset statistics for production instruments
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	02/25/2005
**			03/01/2005 grk - added column for instrument name at end
**			12/19/2005 grk - added "MD" and "TS" prefixes (ticket #345)
**			08/17/2007 mem - Updated to examine Dataset State and Dataset Rating when counting Bad and Blank datasets (ticket #520)
**						   - Now excluding TS datasets from the Study Specific Datasets total (in addition to excluding Blank, QC, and Bad datasets)
**						   - Now extending the end date to 11:59:59 pm on the given day if @endDate does not contain a time component
**			04/25/2008 grk - added "% Blank Datasets" column
**    
*****************************************************/
(
	@startDate varchar(24),
	@endDate varchar(24),
	@message varchar(256) output
)
AS
	SET NOCOUNT ON

	declare @daysInRange float
	declare @stDate datetime
	declare @eDate datetime

	set @stDate = CONVERT(DATETIME, @startDate, 102)
	set @eDate = CONVERT(DATETIME, @endDate, 102) 

	declare @eDateAlternate datetime
	set @eDateAlternate = Convert(datetime, Floor(Convert(float, @eDate)))
	
	If @eDate = @eDateAlternate
	Begin
		-- @endDate only specified year, month, and day
		-- Update @eDateAlternate to span thru 23:59:59.997 on the given day,
		--  then copy that value to @eDate
		
		set @eDateAlternate = DateAdd(second, 86399, @eDateAlternate)
		set @eDateAlternate = DateAdd(millisecond, 995, @eDateAlternate)
		set @eDate = @eDateAlternate
	End
	
	set @daysInRange = DateDiff(dd, @stDate, @eDate)

	---------------------------------------------------
	-- Generate report
	---------------------------------------------------

	SELECT
		Instrument,
		[Total] as [Total Datasets],
		@daysInRange as [Days in range],
		convert(decimal(5,1), [Total]/@daysInRange) as [Datasets per day],
		[Blank] as [Blank Datasets],
		[QC] as [QC Datasets],
		[MD] as [Method Dev.],
		[TS] as [Troubleshooting],
		[Bad] as [Bad Datasets],
		convert(decimal(5,1), ([Blank] * 100.0/[Total])) as [% Blank Datasets],
		convert(decimal(5,1), ([QC] * 100.0/[Total])) as [% QC Datasets],
		convert(decimal(5,1), ([Bad] * 100.0/[Total])) as [% Bad Datasets],
		[Total] - ([Blank] + [QC] + [TS] + [Bad]) as [Study Specific Datasets],
		convert(decimal(5,1), ([Total] - ([Blank] + [QC] + [TS] + [Bad])) / @daysInRange) as [Study Specific Datasets per day],
		Instrument as [Inst.]
	FROM
		(SELECT Instrument, 
			    SUM([Total]) AS [Total],
			    SUM([Bad]) AS [Bad],			-- Bad
			    SUM([Blank]) AS [Blank],		-- Blank
			    SUM([QC]) AS [QC],				-- QC
			    SUM([MD]) AS [MD],				-- Method Development
			    SUM([TS]) AS [TS]				-- Troubleshooting
		 FROM
			(	SELECT
					I.IN_Name as Instrument, 
					COUNT(*) AS [Total],
					0 AS [Bad],																	-- Bad
					SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Blank],	-- Blank
					SUM(CASE WHEN D.Dataset_Num LIKE 'QC%' THEN 1 ELSE 0 END) AS [QC],			-- QC
					SUM(CASE WHEN D.Dataset_Num LIKE 'MD%' THEN 1 ELSE 0 END) AS [MD],			-- Method Development
					SUM(CASE WHEN D.Dataset_Num LIKE 'TS%' THEN 1 ELSE 0 END) AS [TS]			-- Troubleshooting
				FROM
					T_Dataset D INNER JOIN
					T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID
				WHERE NOT ( D.Dataset_Num LIKE 'Bad%' OR
							D.DS_Rating IN (-1,-2,-5) OR
							D.DS_State_ID = 4) AND
					  D.DS_Rating <> -10 AND						-- Exclude unreviewed datasets
					  I.IN_operations_role = 'Production' AND
					  D.DS_created BETWEEN @stDate AND @eDate
				GROUP BY I.IN_Name
				UNION
				SELECT
					I.IN_Name as Instrument, 
					COUNT(*) AS [Total],
					SUM(CASE WHEN D.Dataset_Num NOT LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Bad],	-- Bad
					SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Blank],	-- Blank
					0 AS [QC],																	-- QC
					0 AS [MD],																	-- Method Development
					0 AS [TS]																	-- Troubleshooting
				FROM
					T_Dataset D INNER JOIN
					T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID
				WHERE ( D.Dataset_Num LIKE 'Bad%' OR
						D.DS_Rating IN (-1,-2,-5) OR
						D.DS_State_ID = 4) AND
					  I.IN_operations_role = 'Production' AND
					  D.DS_created BETWEEN @stDate AND @eDate
				GROUP BY I.IN_Name
			) StatsQ
		GROUP BY Instrument	
		) CombinedStatsQ 
	ORDER BY Instrument


	RETURN

GO
GRANT EXECUTE ON [dbo].[ReportProductionStats] TO [DMS_User]
GO
GRANT EXECUTE ON [dbo].[ReportProductionStats] TO [DMS2_SP_User]
GO
