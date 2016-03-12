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
**			04/25/2008 grk - Added "% Blank Datasets" column
**			08/30/2010 mem - Added parameter @productionOnly and updated to allow @startDate and/or @endDate to be blank
**						   - try/catch error handling
**			09/08/2010 mem - Now grouping Method Development (MD) datasets in with Troubleshooting datasets
**						   - Added checking for invalid dates
**			09/09/2010 mem - Now reporting % Study Specific datasets
**			09/26/2010 grk - Added accounting for reruns
**			02/03/2011 mem - Now using Dataset Acq Time (Acq_Time_Start) instead of Dataset Created (DS_Created), provided Acq_Time_Start is not null
**			03/30/2011 mem - Now reporting number of Unreviewed datasets
**						   - Removed the Troubleshooting column since datasets are no longer being updated that start with TS or MD
**			11/30/2011 mem - Added parameter @CampaignIDFilterList
**			               - Added column "% EMSL Owned"
**			               - Added new columns, including "% EMSL Owned", "EMSL-Funded Study Specific Datasets", and "EF Study Specific Datasets per day"
**			03/15/2012 mem - Added parameter @EUSUsageFilterList
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@startDate varchar(24),
	@endDate varchar(24),
	@productionOnly tinyint = 1,			-- When 0 then shows all instruments; otherwise limits the report to production instruments only
	@CampaignIDFilterList varchar(2000) = '',
	@EUSUsageFilterList varchar(2000) = '',
	@message varchar(256) = '' output	
)
AS
	Set XACT_ABORT, nocount on

	declare @myRowCount int = 0
	declare @myError int = 0
	
	declare @daysInRange float
	declare @stDate datetime
	declare @eDate datetime

	declare @msg varchar(256)

	declare @eDateAlternate datetime

	BEGIN TRY 

	--------------------------------------------------------------------
	-- Validate the inputs
	--------------------------------------------------------------------
	--
	Set @productionOnly = IsNull(@productionOnly, 1)
	Set @CampaignIDFilterList = LTrim(RTrim(IsNull(@CampaignIDFilterList, '')))
	Set @EUSUsageFilterList = LTrim(RTrim(IsNull(@EUSUsageFilterList, '')))
	Set @message = ''

	--------------------------------------------------------------------
	-- Populate a temporary table with the Campaign IDs to filter on
	--------------------------------------------------------------------
	--
	CREATE TABLE #Tmp_CampaignFilter (
		Campaign_ID int NOT NULL,
		Fraction_EMSL_Funded float NULL
	)
	
	CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_CampaignFilter ON #Tmp_CampaignFilter (Campaign_ID)
	
	If @CampaignIDFilterList <> ''
	Begin	
		INSERT INTO #Tmp_CampaignFilter (Campaign_ID)
		SELECT DISTINCT Value
		FROM dbo.udfParseDelimitedIntegerList(@CampaignIDFilterList, ',')
		ORDER BY Value
		
		-- Look for invalid Campaign ID values
		Set @msg = ''
		SELECT @msg = Convert(varchar(12), CF.Campaign_ID) + ',' + @msg
		FROM #Tmp_CampaignFilter CF
		     LEFT OUTER JOIN T_Campaign C
		       ON CF.Campaign_ID = C.Campaign_ID
		WHERE C.Campaign_ID IS NULL
		--
		SELECT @myRowCount = @@RowCount
		
		If @myRowCount > 0 
		Begin
			-- Remove the trailing comma
			Set @msg = Substring(@msg, 1, Len(@msg)-1)
			
			If @myRowCount = 1
				set @msg = 'Invalid Campaign ID: ' + @msg
			Else
				set @msg = 'Invalid Campaign IDs: ' + @msg

			print @msg
			RAISERROR (@msg, 11, 15)
		End

		-- Update column Fraction_EMSL_Funded
		--	
		UPDATE #Tmp_CampaignFilter
		SET Fraction_EMSL_Funded = C.CM_Fraction_EMSL_Funded
		FROM #Tmp_CampaignFilter CF
		     INNER JOIN T_Campaign C
		       ON CF.Campaign_ID = C.Campaign_ID

	End
	Else
	Begin
		INSERT INTO #Tmp_CampaignFilter (Campaign_ID, Fraction_EMSL_Funded)
		SELECT Campaign_ID, CM_Fraction_EMSL_Funded
		FROM T_Campaign
		ORDER BY Campaign_ID
	End
	
	
	--------------------------------------------------------------------
	-- Populate a temporary table with the EUS Usage types to filter on
	--------------------------------------------------------------------
	--
	CREATE TABLE #Tmp_EUSUsageFilter (
		Usage_ID int NOT NULL,
		Usage_Name varchar(64) NOT NULL
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_EUSUsageFilter ON #Tmp_EUSUsageFilter (Usage_ID)
	
	If @EUSUsageFilterList <> ''
	Begin	
		INSERT INTO #Tmp_EUSUsageFilter (Usage_Name, Usage_ID)
		SELECT DISTINCT Value AS Usage_Name, 0 AS ID
		FROM dbo.udfParseDelimitedList(@EUSUsageFilterList, ',')
		ORDER BY Value
		
		-- Look for invalid Usage_Name values
		Set @msg = ''
		SELECT @msg = Convert(varchar(12), UF.Usage_Name) + ',' + @msg
		FROM #Tmp_EUSUsageFilter UF
		     LEFT OUTER JOIN T_EUS_UsageType U
		       ON UF.Usage_Name = U.Name
		WHERE U.ID IS NULL
		--
		SELECT @myRowCount = @@RowCount
		
		If @myRowCount > 0 
		Begin
			-- Remove the trailing comma
			Set @msg = Substring(@msg, 1, Len(@msg)-1)
			
			If @myRowCount = 1
				set @msg = 'Invalid Usage Type: ' + @msg
			Else
				set @msg = 'Invalid Usage Type: ' + @msg
			
			Set @msg = @msg + '; known types are: '
			
			SELECT @msg = @msg + Name + ', '
			FROM T_EUS_UsageType
			WHERE (ID <> 1)
			
			-- Remove the trailing comma
			Set @msg = Substring(@msg, 1, Len(@msg)-1)
			
			print @msg
			RAISERROR (@msg, 11, 15)
		End

		-- Update column Usage_ID
		--	
		UPDATE #Tmp_EUSUsageFilter
		SET Usage_ID = U.ID
		FROM #Tmp_EUSUsageFilter UF
		     INNER JOIN T_EUS_UsageType U
		       ON UF.Usage_Name = U.Name

	End
	Else
	Begin
		INSERT INTO #Tmp_EUSUsageFilter (Usage_ID, Usage_Name)
		SELECT ID, Name
		FROM T_EUS_UsageType
		ORDER BY ID
	End
	
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

	
	--------------------------------------------------------------------
	-- Populate a temporary table with the datasets to use
	--------------------------------------------------------------------
	--
	CREATE TABLE #Tmp_Datasets (
		Dataset_ID int NOT NULL,
		Campaign_ID int NOT NULL
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_Datasets ON #Tmp_Datasets (Dataset_ID, Campaign_ID)
	
	If @EUSUsageFilterList <> ''
	Begin
		-- Filter on the EMSL usage types defined in #Tmp_EUSUsageFilter
		--
		INSERT INTO #Tmp_Datasets( Dataset_ID,
		                           Campaign_ID )
		SELECT D.Dataset_ID,
		       E.EX_campaign_ID
		FROM T_Dataset D
		     INNER JOIN T_Experiments E
		       ON E.Exp_ID = D.Exp_ID
		     INNER JOIN T_Requested_Run RR
		       ON D.Dataset_ID = RR.DatasetID
		WHERE ISNULL(D.Acq_Time_Start, D.DS_created) BETWEEN @stDate AND @eDate 
		      AND
		      RR.RDS_EUS_UsageType IN ( SELECT Usage_ID
		                                FROM #Tmp_EUSUsageFilter )

	End
	Else
	Begin
		INSERT INTO #Tmp_Datasets ( Dataset_ID, Campaign_ID)
		SELECT D.Dataset_ID, E.EX_campaign_ID
		FROM T_Dataset D
		     INNER JOIN T_Experiments E
		       ON E.Exp_ID = D.Exp_ID
		WHERE ISNULL(D.Acq_Time_Start, D.DS_created) BETWEEN @stDate AND @eDate
	End	
	
	
	---------------------------------------------------
	-- Generate report
	---------------------------------------------------

	SELECT
		Instrument,
		[Total] AS [Total Datasets],
		@daysInRange AS [Days in range],
		convert(decimal(5,1), [Total]/@daysInRange) AS [Datasets per day],
		[Blank] AS [Blank Datasets],
		[QC] AS [QC Datasets],
		-- [TS] as [Troubleshooting],
		[Bad] as [Bad Datasets],
		[Reruns] AS [Reruns],
		[Unreviewed] AS [Unreviewed],
		[Study Specific] AS [Study Specific Datasets],
		convert(decimal(5,1), [Study Specific] / @daysInRange) AS [Study Specific Datasets per day],
		CASE WHEN [EF_Total] > 0 AND [EF Study Specific] >= 0.01 THEN Convert(float, Convert(decimal(9,2), [EF Study Specific])) ELSE NULL END AS [EMSL-Funded Study Specific Datasets],
		CASE WHEN [EF_Total] > 0 AND [EF Study Specific] >= 0.01 THEN convert(decimal(5,1), [EF Study Specific] / @daysInRange) ELSE NULL END AS [EF Study Specific Datasets per day],

		Instrument AS [Inst.],
		Percent_EMSL_Owned AS [% Inst EMSL Owned],
		
		-- EMSL Funded Counts:
		Convert(float, Convert(decimal(9,2), [EF_Total])) AS [EF Total Datasets],
		convert(decimal(5,1), [EF_Total]/@daysInRange) AS [EF Datasets per day],
		Convert(float, Convert(decimal(9,2), [EF_Blank])) AS [EF Blank Datasets],
		Convert(float, Convert(decimal(9,2), [EF_QC])) AS [EF QC Datasets],
		Convert(float, Convert(decimal(9,2), [EF_Bad])) as [EF Bad Datasets],
		Convert(float, Convert(decimal(9,2), [EF_Reruns])) AS [EF Reruns],
		Convert(float, Convert(decimal(9,2), [EF_Unreviewed])) AS [EF Unreviewed],

		convert(decimal(5,1), ([Blank] * 100.0/[Total])) AS [% Blank Datasets],
		convert(decimal(5,1), ([QC] * 100.0/[Total])) AS [% QC Datasets],
		convert(decimal(5,1), ([Bad] * 100.0/[Total])) AS [% Bad Datasets],
		convert(decimal(5,1), ([Reruns] * 100.0/[Total])) AS [% Reruns],
		convert(decimal(5,1), ([Study Specific] * 100.0/[Total])) AS [% Study Specific],

		CASE WHEN [EF_Total] > 0 THEN convert(decimal(5,1), ([EF_Blank] * 100.0/[EF_Total])) ELSE NULL END AS [% EF Blank Datasets],
		CASE WHEN [EF_Total] > 0 THEN convert(decimal(5,1), ([EF_QC] * 100.0/[EF_Total])) ELSE NULL END AS [% EF QC Datasets],
		CASE WHEN [EF_Total] > 0 THEN convert(decimal(5,1), ([EF_Bad] * 100.0/[EF_Total])) ELSE NULL END AS [% EF Bad Datasets],
		CASE WHEN [EF_Total] > 0 THEN convert(decimal(5,1), ([EF_Reruns] * 100.0/[EF_Total])) ELSE NULL END AS [% EF Reruns],
		CASE WHEN [EF_Total] > 0 THEN convert(decimal(5,1), ([EF Study Specific] * 100.0/[EF_Total])) ELSE NULL END AS [% EF Study Specific],
		
		Instrument AS [Inst]
	FROM (
		SELECT Instrument, Percent_EMSL_Owned, 
		    [Total], [Bad], [Blank], [QC], [Reruns], [Unreviewed],
			[Total] - ([Blank] + [QC] + [Bad] + [Reruns] + [Unreviewed]) AS [Study Specific],			
			[EF_Total], [EF_Bad], [EF_Blank], [EF_QC], [EF_Reruns], [EF_Unreviewed],
			[EF_Total] - ([EF_Blank] + [EF_QC] + [EF_Bad] + [EF_Reruns] + [EF_Unreviewed]) AS [EF Study Specific]			    

		FROM
			(SELECT Instrument, 
			        Percent_EMSL_Owned,
					SUM([Total]) AS [Total],		-- Total
					SUM([Bad]) AS [Bad],			-- Bad
					SUM([Blank]) AS [Blank],		-- Blank
					SUM([QC]) AS [QC],				-- QC
					-- SUM([TS]) AS [TS],			-- Troubleshooting and Method Development
					SUM([Reruns]) AS [Reruns],			-- Rerun
					SUM([Unreviewed]) AS [Unreviewed],	-- Unreviewed
					
					-- EMSL Funded Counts:
					Sum([EF_Total]) AS [EF_Total],
					Sum([EF_Bad]) AS [EF_Bad],
					Sum([EF_Blank]) AS [EF_Blank],
					Sum([EF_QC]) AS [EF_QC],
					Sum([EF_Reruns]) AS [EF_Reruns],
					Sum([EF_Unreviewed]) AS [EF_Unreviewed]
			FROM
				(	-- Select Good datasets (excluded Bad, Not Released, Unreviewed, etc.)
					SELECT
						I.IN_Name as Instrument, 
						I.Percent_EMSL_Owned,
						COUNT(*) AS [Total],														-- Total
						0 AS [Bad],																	-- Bad
						SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Blank],	-- Blank
						SUM(CASE WHEN D.Dataset_Num LIKE 'QC%' THEN 1 ELSE 0 END) AS [QC],			-- QC
						SUM(CASE WHEN D.DS_Rating = -6 THEN 1 ELSE 0 END) AS [Reruns],				-- Rerun (Good Data)
						-- SUM(CASE WHEN D.Dataset_Num LIKE 'TS%' OR D.Dataset_Num LIKE 'MD%' THEN 1 ELSE 0 END) AS [TS],				-- Troubleshooting or Method Development
						0 AS [Unreviewed],															-- Unreviewed
						
						-- EMSL Funded Counts:
						SUM(CF.Fraction_EMSL_Funded) AS [EF_Total],
						0 AS [EF_Bad],																						-- Bad
						SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN CF.Fraction_EMSL_Funded ELSE 0 END) AS [EF_Blank],	-- Blank
						SUM(CASE WHEN D.Dataset_Num LIKE 'QC%' THEN CF.Fraction_EMSL_Funded ELSE 0 END) AS [EF_QC],			-- QC
						SUM(CASE WHEN D.DS_Rating = -6 THEN CF.Fraction_EMSL_Funded ELSE 0 END) AS [EF_Reruns],				-- Rerun (Good Data)
						0 AS [EF_Unreviewed]																				-- Unreviewed
					FROM
						#Tmp_Datasets DF INNER JOIN
						T_Dataset D ON DF.Dataset_ID = D.Dataset_ID INNER JOIN
						T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID INNER JOIN 
						#Tmp_CampaignFilter CF ON CF.Campaign_ID = DF.Campaign_ID
					WHERE NOT ( D.Dataset_Num LIKE 'Bad%' OR
								D.DS_Rating IN (-1,-2,-5) OR
								D.DS_State_ID = 4
							) AND
						D.DS_Rating <> -10 AND						-- Exclude unreviewed datasets
						(I.IN_operations_role = 'Production' OR @productionOnly = 0)
					GROUP BY I.IN_Name, I.Percent_EMSL_Owned
					UNION
					-- Select Bad or Not Released datasets (exclude Unreviewed)
					SELECT
						I.IN_Name as Instrument, 
						I.Percent_EMSL_Owned,
						COUNT(*) AS [Total],														-- Total
						SUM(CASE WHEN D.Dataset_Num NOT LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Bad],	-- Bad
						SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Blank],	-- Blank
						0 AS [QC],																	-- QC
						0 AS [Reruns],																-- Rerun (Good Data)
						-- 0 AS [TS],																-- Troubleshooting or Method Development
						0 AS [Unreviewed],															-- Unreviewed
						
						-- EMSL Funded Counts:
						SUM(CF.Fraction_EMSL_Funded) AS [EF_Total],														-- Total
						SUM(CASE WHEN D.Dataset_Num NOT LIKE 'Blank%' THEN CF.Fraction_EMSL_Funded ELSE 0 END) AS [EF_Bad],	-- Bad
						SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN CF.Fraction_EMSL_Funded ELSE 0 END) AS [EF_Blank],	-- Blank
						0 AS [EF_QC],																						-- QC
						0 AS [EF_Reruns],																					-- Rerun (Good Data)
						0 AS [EF_Unreviewed]																				-- Unreviewed
					FROM
						#Tmp_Datasets DF INNER JOIN
						T_Dataset D ON DF.Dataset_ID = D.Dataset_ID INNER JOIN
						T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID INNER JOIN 
						#Tmp_CampaignFilter CF ON CF.Campaign_ID = DF.Campaign_ID
					WHERE ( D.Dataset_Num LIKE 'Bad%' OR
							D.DS_Rating IN (-1,-2,-5) OR
							D.DS_State_ID = 4
						) AND
						D.DS_Rating <> -10 AND						-- Exclude unreviewed datasets
						(I.IN_operations_role = 'Production' OR @productionOnly = 0) 
					GROUP BY I.IN_Name, I.Percent_EMSL_Owned
					UNION
					-- Select Unreviewed datasets (but exclude Bad or Not Released datasets)
					SELECT
						I.IN_Name as Instrument, 
						I.Percent_EMSL_Owned,
						COUNT(*) AS [Total],														-- Total
						0 AS [Bad],																	-- Bad
						0 AS [Blank],																-- Blank
						0 AS [QC],																	-- QC
						0 AS [Reruns],																-- Rerun (Good Data),
						-- 0 AS [TS],																-- Troubleshooting or Method Development
						COUNT(*) AS [Unreviewed],													-- Unreviewed
						
						-- EMSL Funded Counts:
						SUM(CF.Fraction_EMSL_Funded) AS [EF_Total],									-- Total
						0 AS [EF_Bad],																-- Bad
						0 AS [EF_Blank],															-- Blank
						0 AS [EF_QC],																-- QC
						0 AS [EF_Reruns],															-- Rerun (Good Data)
						SUM(CF.Fraction_EMSL_Funded) AS [EF_Unreviewed]								-- Unreviewed
					FROM
						#Tmp_Datasets DF INNER JOIN
						T_Dataset D ON DF.Dataset_ID = D.Dataset_ID INNER JOIN
						T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID INNER JOIN 
						#Tmp_CampaignFilter CF ON CF.Campaign_ID = DF.Campaign_ID
					WHERE NOT ( D.Dataset_Num LIKE 'Bad%' OR
								D.DS_Rating IN (-1,-2,-5) OR
								D.DS_State_ID = 4
							) AND
						D.DS_Rating = -10 AND						-- Select unreviewed datasets
						(I.IN_operations_role = 'Production' OR @productionOnly = 0)
					GROUP BY I.IN_Name, I.Percent_EMSL_Owned
				) StatsQ
			GROUP BY Instrument, Percent_EMSL_Owned
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
