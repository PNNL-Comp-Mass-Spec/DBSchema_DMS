/****** Object:  StoredProcedure [dbo].[UpdateEMSLInstrumentUsageReport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateEMSLInstrumentUsageReport]
/****************************************************
**
**  Desc: 
**    Add entries to permanent EMSL monthly usage report for given  
**    Instrument, and date
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 03/21/2012 
**          03/26/2012 grk - added code to clean up comments and pin trans-month interval starting time
**          04/09/2012 grk - modified algorithm
**			06/08/2012 grk - added lookup for @maxNormalInterval
**          08/30/2012 grk - don't overwrite existing non-blank items, do auto-comment non-onsite datasets
**          10/02/2012 grk - added debug output
**          10/06/2012 grk - adding "updated by" date and user
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
	@instrument VARCHAR(64),
	@endDate DATETIME,
	@message varchar(512) output
AS
	SET NOCOUNT ON 

	DECLARE @myError int
	SET @myError = 0

	DECLARE @myRowCount int
	SET @myRowCount = 0
	 	DECLARE @debug VARCHAR(12) = ''
	SET @debug = @message

	SET @message = ''
	
	DECLARE @outputFormat varchar(12) = 'report'
	
	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 
		DECLARE @maxNormalInterval INT = dbo.GetLongIntervalThreshold()
		
		DECLARE @callingUser varchar(128) = REPLACE(SUSER_SNAME(), 'PNL\', '')

		---------------------------------------------------
		-- figure out our time context
		---------------------------------------------------

		DECLARE @year INT = DATEPART(YEAR, @endDate)
		DECLARE @month INT = DATEPART(MONTH, @endDate)
		DECLARE @day INT = DATEPART(DAY, @endDate)
		DECLARE @hour INT = DATEPART(HOUR, @endDate)
		
		DECLARE @bom DATETIME = CONVERT(VARCHAR(12), @month) + '/1/' + CONVERT(VARCHAR(12), @year)

		---------------------------------------------------
		-- temporary table for staging report rows
		---------------------------------------------------

		CREATE TABLE #STAGING (
			[EMSL_Inst_ID] INT,
			[Instrument] VARCHAR(64),
			[Type] VARCHAR(128),
			[Start] DATETIME,
			[Minutes] INT,
			[Proposal] varchar(32) NULL,
			[Usage] varchar(32) NULL,
			[Users] VARCHAR(1024),
			[Operator] VARCHAR(64),
			[Comment] VARCHAR(4096) NULL,
			[Year] INT,
			[Month] INT,
			[ID] INT,
			[Mark] INT NULL,
			Seq INT NULL
		)

		---------------------------------------------------
		-- populate staging table with report rows for 
		-- instument for current month
		---------------------------------------------------

		INSERT  INTO #STAGING
				( [Instrument] ,
				  [EMSL_Inst_ID] ,
				  [Start] ,
				  [Type] ,
				  [Minutes] ,
				  [Proposal] ,
				  [Usage] ,
				  [Users] ,
				  [Operator] ,
				  [Comment] ,
				  [Year] ,
				  [Month] ,
				  [ID]
				)
		EXEC GetMonthlyInstrumentUsageReport @instrument, @year, @month, @outputFormat, @message OUTPUT

		IF @debug = '1' SELECT * FROM #STAGING		

		---------------------------------------------------
		-- mark items that are already in report
		---------------------------------------------------

		UPDATE    #STAGING
		SET       [Mark] = 1
		FROM      #STAGING
				INNER JOIN T_EMSL_Instrument_Usage_Report TR ON #STAGING.ID = TR.ID
				AND #STAGING.Type = TR.Type

		IF @debug = '2' SELECT * FROM #STAGING		

		---------------------------------------------------
		-- Add unique sequence tag to new report rows
		---------------------------------------------------

		DECLARE @seq INT = 0
		SELECT @seq = ISNULL(MAX(Seq), 0) FROM T_EMSL_Instrument_Usage_Report
		--
		UPDATE #STAGING
		SET @seq = Seq = @seq + 1,
		[Mark] = 0
		FROM #STAGING
		WHERE [Mark] IS NULL

		IF @debug = '3' SELECT * FROM #STAGING		

		---------------------------------------------------
		-- cleanup: remove usage text from comments
		---------------------------------------------------
		
		SET @seq = 0
		DECLARE @cleanedComment VARCHAR(4096)
		DECLARE @xml XML
		DECLARE @num INT
		DECLARE @count INT = 0
		SELECT @num = COUNT(*) FROM #STAGING
		WHILE @count < @num
		BEGIN 
			SET @cleanedComment = ''
			SELECT TOP 1
				@seq = Seq ,
				@cleanedComment = Comment
			FROM #STAGING
			WHERE Seq > @seq
			ORDER BY Seq
			IF @cleanedComment <> ''
			BEGIN
				EXEC dbo.ParseUsageText @cleanedComment output, @xml output, @message  output
				UPDATE #STAGING
				SET Comment = @cleanedComment
				WHERE Seq = @seq
			END 
			SET @count = @count + 1
		END

		IF @debug = '4' SELECT * FROM #STAGING		

		---------------------------------------------------
		-- pin start time for month-spanning intervals
		---------------------------------------------------
		
		UPDATE #STAGING
		SET Start = @bom
		WHERE [Type] = 'Interval' AND Start < @bom

		IF @debug = '5' SELECT * FROM #STAGING
		
		---------------------------------------------------
		---------------------------------------------------
		IF @debug = '6'
		BEGIN --<6>
			SELECT
				Start = #STAGING.Start ,
				Proposal = CASE WHEN ISNULL(TEIUR.Proposal, '') = '' THEN #STAGING.Proposal ELSE TEIUR.Proposal END ,
				Usage = CASE WHEN ISNULL(TEIUR.Usage, '') = '' THEN #STAGING.Usage ELSE TEIUR.Usage END ,
				Users = CASE WHEN ISNULL(TEIUR.Users, '') = '' THEN #STAGING.Users ELSE TEIUR.Users END ,
				Operator = CASE WHEN ISNULL(TEIUR.Operator, '') = '' THEN #STAGING.Operator ELSE TEIUR.Operator END ,
				[Year] = #STAGING.Year ,
				[Month] = #STAGING.Month ,
				Comment = CASE WHEN ISNULL(TEIUR.Comment, '') = '' THEN #STAGING.Comment ELSE TEIUR.Comment END
			FROM T_EMSL_Instrument_Usage_Report TEIUR
				INNER JOIN #STAGING ON TEIUR.ID = #STAGING.ID
				AND TEIUR.Type = #STAGING.Type
			WHERE #STAGING.Mark = 1		

			SELECT  EMSL_Inst_ID ,
				Instrument ,
				Type ,
				Start ,
				Minutes ,
				Proposal ,
				Usage ,
				Users ,
				Operator ,
				Comment ,
				Year ,
				Month ,
				ID ,
				Seq
			FROM    #STAGING
			WHERE [Mark] = 0 
			AND NOT [EMSL_Inst_ID] IS NULL
			ORDER BY [Start]
		
			---------------------------------------------------
			-- clean out any "long intervals" that don't appear
			-- in the main interval table	
			---------------------------------------------------

			SELECT  EMSL_Inst_ID ,
					Instrument ,
					Type ,
					Start ,
					Minutes ,
					Proposal ,
					Usage ,
					Users ,
					Operator ,
					Comment ,
					Year ,
					Month ,
					ID ,
					Seq
			FROM T_EMSL_Instrument_Usage_Report
			WHERE Type = 'Interval' AND Year = @year AND Month = @month
			AND Instrument = @instrument	
			AND  NOT ID IN (SELECT ID FROM T_Run_Interval)
					

		END --<6>

		---------------------------------------------------
		-- update existing values in report table from staging table
		---------------------------------------------------
		
		IF @debug = ''
		BEGIN --<a>
			BEGIN --<m>	
				UPDATE TEIUR
				SET
				[Minutes] = #STAGING.Minutes ,
				Start = #STAGING.Start ,
				Proposal = CASE WHEN ISNULL(TEIUR.Proposal, '') = '' THEN #STAGING.Proposal ELSE TEIUR.Proposal END ,
				Usage = CASE WHEN ISNULL(TEIUR.Usage, '') = '' THEN #STAGING.Usage ELSE TEIUR.Usage END ,
				Users = CASE WHEN ISNULL(TEIUR.Users, '') = '' THEN #STAGING.Users ELSE TEIUR.Users END ,
				Operator = CASE WHEN ISNULL(TEIUR.Operator, '') = '' THEN #STAGING.Operator ELSE TEIUR.Operator END ,
				[Year] = #STAGING.Year ,
				[Month] = #STAGING.Month ,
				Comment = CASE WHEN ISNULL(TEIUR.Comment, '') = '' THEN #STAGING.Comment ELSE TEIUR.Comment END,
				[Updated] = GETDATE(),
				UpdatedBy = @callingUser						
				FROM T_EMSL_Instrument_Usage_Report TEIUR
					INNER JOIN #STAGING ON TEIUR.ID = #STAGING.ID
					AND TEIUR.Type = #STAGING.Type
				WHERE #STAGING.Mark = 1
			END --<m>

			---------------------------------------------------
			-- clean out any short "long intervals"
			---------------------------------------------------
	
			DELETE FROM #STAGING
			WHERE Type = 'Interval'
			AND Minutes < @maxNormalInterval

			---------------------------------------------------
			-- add new values from staging table to database
			---------------------------------------------------
		

			INSERT INTO T_EMSL_Instrument_Usage_Report ( 
				EMSL_Inst_ID ,
				Instrument ,
				Type ,
				Start ,
				Minutes ,
				Proposal ,
				Usage ,
				Users ,
				Operator ,
				Comment ,
				Year ,
				Month ,
				ID ,
				UpdatedBy,       
				Seq
			)
				SELECT  EMSL_Inst_ID ,
				Instrument ,
				Type ,
				Start ,
				Minutes ,
				Proposal ,
				Usage ,
				Users ,
				Operator ,
				Comment ,
				Year ,
				Month ,
				ID ,
				@callingUser,		
				Seq
			FROM    #STAGING
			WHERE [Mark] = 0 
			AND NOT [EMSL_Inst_ID] IS NULL
			ORDER BY [Start]

			---------------------------------------------------
			-- clean out short "long intervals"
			---------------------------------------------------
	
			DELETE FROM T_EMSL_Instrument_Usage_Report
			WHERE ID IN (SELECT ID FROM #STAGING)
			AND Type = 'Interval'
			AND Minutes < @maxNormalInterval
		

			---------------------------------------------------
			-- clean out any "long intervals" that don't appear
			-- in the main interval table	
			---------------------------------------------------

			DELETE 
			FROM T_EMSL_Instrument_Usage_Report
			WHERE Type = 'Interval' AND Year = @year AND Month = @month
			AND Instrument = @instrument	
			AND  NOT ID IN (SELECT ID FROM T_Run_Interval)

			---------------------------------------------------
			-- add automatic log references for missing comments
			---------------------------------------------------

			UPDATE T_EMSL_Instrument_Usage_Report
			SET Comment = dbo.GetNearestPrecedingLogEntry(Seq, 0) 
			WHERE   ( Year = @year)
					AND ( Month = @month )
					AND Type = 'Dataset'
					AND Usage <> 'ONSITE'       
					AND ISNULL(Comment, '') = ''

			---------------------------------------------------
			-- remove "MAINTENANCE" and "ONSITE" comments
			---------------------------------------------------
			
			UPDATE T_EMSL_Instrument_Usage_Report
			SET Comment = ''
			WHERE Usage in ('MAINTENANCE', 'ONSITE')
			AND Instrument = @instrument	
			AND Year = @year AND Month = @month
					
	  	       
	END --<a>
	---------------------------------------------------
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	RETURN @myError

GO
GRANT EXECUTE ON [dbo].[UpdateEMSLInstrumentUsageReport] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEMSLInstrumentUsageReport] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEMSLInstrumentUsageReport] TO [PNL\D3M580] AS [dbo]
GO
