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
**			08/30/2010 mem - Added parameter @productionOnly and updated to allow @startDate and/or @endDate to be blank
**						   - try/catch error handling
**			09/08/2010 mem - Now grouping Method Development (MD) datasets in with Troubleshooting datasets
**						   - Added checking for invalid dates
**			09/09/2010 mem - Now reporting % Study Specific datasets
**			09/26/2010 grk - Added accounting for reruns
**    
*****************************************************/
(
	@startDate varchar(24),
	@endDate varchar(24),
	@productionOnly tinyint = 1,			-- When 0 then shows all instruments; otherwise limits the report to production instruments only
	@message varchar(256) output
)
AS
	SET NOCOUNT ON

	declare @myError int = 0
	
	declare @daysInRange float
	declare @stDate datetime
	declare @eDate datetime

	declare @msg varchar(256)

	declare @eDateAlternate datetime

	BEGIN TRY 

	Set @productionOnly = IsNull(@productionOnly, 1)
	Set @message = ''
	
	--------------------------------------------------------------------
	-- If @endDate is empty, auto-set to the end of the current day
	--------------------------------------------------------------------
	--
	If IsNull(@endDate, '') = ''
	Begin
		Set @eDateAlternate = CONVERT(datetime, convert(varchar(32), GETDATE(), 101))
		Set @eDateAlternate = DateAdd(second, 86399, @eDateAlternate)
		Set @eDateAlternate = DateAdd(millisecond, 995, @eDateAlternate)
		Set @endDate = Convert(varchar(32), @eDateAlternate, 121)
	End
	Else
	Begin
		If IsDate(@endDate) = 0
		Begin
			set @msg = 'End date "' + @endDate + '" is not a valid date'
			RAISERROR (@msg, 11, 15)
		End
	End
		
	--------------------------------------------------------------------
	-- Check whether @endDate only contains year, month, and day
	--------------------------------------------------------------------
	--
	set @eDate = CONVERT(DATETIME, @endDate, 102) 

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
	
	--------------------------------------------------------------------
	-- If @startDate is empty, auto-set to 2 weeks before @eDate
	--------------------------------------------------------------------
	--
	If IsNull(@startDate, '') = ''
		Set @stDate = DateAdd(day, -14, Convert(datetime, Floor(Convert(float, @eDate))))
	Else
	Begin
		If IsDate(@startDate) = 0
		Begin
			set @msg = 'Start date "' + @startDate + '" is not a valid date'
			RAISERROR (@msg, 11, 16)
		End

		Set @stDate = CONVERT(DATETIME, @startDate, 102) 
	End
	
	--------------------------------------------------------------------
	-- Compute the number of days to be examined
	--------------------------------------------------------------------
	--
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
		[TS] as [Troubleshooting],
		[Bad] as [Bad Datasets],
		[Reruns] AS [Reruns],
		convert(decimal(5,1), ([Blank] * 100.0/[Total])) as [% Blank Datasets],
		convert(decimal(5,1), ([QC] * 100.0/[Total])) as [% QC Datasets],
		convert(decimal(5,1), ([Bad] * 100.0/[Total])) as [% Bad Datasets],
		convert(decimal(5,1), ([Reruns] * 100.0/[Total])) as [% Reruns],
		convert(decimal(5,1), ([Study Specific] * 100.0/[Total])) as [% Study Specific],
		[Study Specific] as [Study Specific Datasets],
		convert(decimal(5,1), [Study Specific] / @daysInRange) as [Study Specific Datasets per day],
		Instrument as [Inst.]
	FROM (
		SELECT Instrument, [Total], 
			[Bad],[Blank], [QC], [TS], [Reruns],
			[Total] - ([Blank] + [QC] + [TS] + [Bad] + [Reruns]) AS [Study Specific]			    
		FROM
			(SELECT Instrument, 
					SUM([Total]) AS [Total],
					SUM([Bad]) AS [Bad],			-- Bad
					SUM([Blank]) AS [Blank],		-- Blank
					SUM([QC]) AS [QC],				-- QC
					SUM([TS]) AS [TS],				-- Troubleshooting and Method Development
					SUM([Reruns]) AS [Reruns]
			FROM
				(	SELECT
						I.IN_Name as Instrument, 
						COUNT(*) AS [Total],
						0 AS [Bad],																	-- Bad
						SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Blank],	-- Blank
						SUM(CASE WHEN D.Dataset_Num LIKE 'QC%' THEN 1 ELSE 0 END) AS [QC],			-- QC
						SUM(CASE WHEN D.DS_Rating = -6 THEN 1 ELSE 0 END) AS [Reruns],				-- Rerun (Good Data)
						SUM(CASE WHEN D.Dataset_Num LIKE 'TS%' 
								OR D.Dataset_Num LIKE 'MD%' THEN 1 ELSE 0 END) AS [TS]			-- Troubleshooting or Method Development
					FROM
						T_Dataset D INNER JOIN
						T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID
					WHERE NOT ( D.Dataset_Num LIKE 'Bad%' OR
								D.DS_Rating IN (-1,-2,-5) OR
								D.DS_State_ID = 4
							) AND
						D.DS_Rating <> -10 AND						-- Exclude unreviewed datasets
						(I.IN_operations_role = 'Production' OR @productionOnly = 0) AND
						D.DS_created BETWEEN @stDate AND @eDate
					GROUP BY I.IN_Name
					UNION
					SELECT
						I.IN_Name as Instrument, 
						COUNT(*) AS [Total],
						SUM(CASE WHEN D.Dataset_Num NOT LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Bad],	-- Bad
						SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Blank],	-- Blank
						0 AS [QC],																	-- QC
						0 AS [TS],																	-- Troubleshooting or Method Development
						0 AS [Reruns]																-- Rerun (Good Data)
					FROM
						T_Dataset D INNER JOIN
						T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID
					WHERE ( D.Dataset_Num LIKE 'Bad%' OR
							D.DS_Rating IN (-1,-2,-5) OR
							D.DS_State_ID = 4
						) AND
						(I.IN_operations_role = 'Production' OR @productionOnly = 0) AND
						D.DS_created BETWEEN @stDate AND @eDate
					GROUP BY I.IN_Name
				) StatsQ
			GROUP BY Instrument	
			) CombinedStatsQ 
		) OuterQ
	ORDER BY Instrument


	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
	RETURN @myError


GO
GRANT EXECUTE ON [dbo].[ReportProductionStats] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ReportProductionStats] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReportProductionStats] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReportProductionStats] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReportProductionStats] TO [PNL\D3M580] AS [dbo]
GO
