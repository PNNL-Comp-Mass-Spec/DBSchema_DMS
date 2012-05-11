/****** Object:  StoredProcedure [dbo].[UpdateEMSLInstrumentUsageReport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateEMSLInstrumentUsageReport
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

	SET @message = ''
	
	DECLARE @outputFormat varchar(12) = 'report'
	
	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 

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

		---------------------------------------------------
		-- mark items that are already in report
		---------------------------------------------------

		UPDATE    #STAGING
		SET       [Mark] = 1
		FROM      #STAGING
				INNER JOIN T_EMSL_Instrument_Usage_Report TR ON #STAGING.ID = TR.ID
				AND #STAGING.Type = TR.Type

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

		---------------------------------------------------
		-- pin start time for month-spanning intervals
		---------------------------------------------------
		
		UPDATE #STAGING
		SET Start = @bom
		WHERE [Type] = 'Interval' AND Start < @bom

		---------------------------------------------------
		-- update existing values in report table from staging table
		---------------------------------------------------
		
		DECLARE 
			@now DATETIME = GETDATE()
		DECLARE 
			@yearNow INT = DATEPART(YEAR, @now),
			@monthNow INT = DATEPART(MONTH, @now),
			@dayNow INT = DATEPART(DAY, @now)
			
		IF(@monthNow = @month) AND (@yearNow = @year)
		BEGIN --<m>	
			UPDATE T_EMSL_Instrument_Usage_Report
			SET
				T_EMSL_Instrument_Usage_Report.Minutes = #STAGING.Minutes,
				Start = #STAGING.Start, 
				Proposal = #STAGING.Proposal, 
				Usage = #STAGING.Usage, 
				Users = #STAGING.Users, 
				Operator = #STAGING.Operator, 
				[Year] = #STAGING.Year, 
				[Month] = #STAGING.Month,
				Comment = #STAGING.Comment
			FROM
				T_EMSL_Instrument_Usage_Report
				INNER JOIN #STAGING ON dbo.T_EMSL_Instrument_Usage_Report.ID = #STAGING.ID 
				AND dbo.T_EMSL_Instrument_Usage_Report.Type = #STAGING.Type
			WHERE
				#STAGING.Mark = 1
		END --<m>

		---------------------------------------------------
		-- clean out and short "long intervals"
		---------------------------------------------------
	
		DELETE FROM #STAGING
		WHERE Type = 'Interval'
		AND Minutes < 90

		---------------------------------------------------
		-- add new values from staging table to database
		---------------------------------------------------

		INSERT INTO T_EMSL_Instrument_Usage_Report
		 (EMSL_Inst_ID, Instrument, Type, Start, Minutes, Proposal, Usage, Users, Operator, Comment, Year, Month, ID, Seq)
		SELECT EMSL_Inst_ID, Instrument, Type, Start, Minutes, Proposal, Usage, Users, Operator, Comment, Year, Month, ID, Seq
		 FROM #STAGING
		WHERE [Mark] = 0 
		AND NOT [EMSL_Inst_ID] IS NULL
		ORDER BY [Start]

		---------------------------------------------------
		-- clean out and short "long intervals"
		---------------------------------------------------
	
		DELETE FROM T_EMSL_Instrument_Usage_Report
		WHERE ID IN (SELECT ID FROM #STAGING)
		AND Type = 'Interval'
		AND Minutes < 90
			
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
