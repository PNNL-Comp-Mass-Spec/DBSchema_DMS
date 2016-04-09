/****** Object:  StoredProcedure [dbo].[ParseUsageText] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.ParseUsageText
/****************************************************
**
**  Desc: 
**    Parse EMSL usage text in comment into XML
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	03/02/2012 
**			03/11/2012 grk - added OtherNotAvailable
**			03/11/2012 grk - return commment without usage text
**			09/18/2012 grk - added 'Operator' and 'PropUser' keywords
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
	@comment VARCHAR(4096) output,
	@usageXML XML output,
	@message varchar(512) output
)
AS
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

--PRINT @comment	
	---------------------------------------------------
	-- temp table to hold usage key-values
	---------------------------------------------------
	
	CREATE TABLE #TU (
		UsageKey varchar(32),
		UsageValue VARCHAR(12) NULL,
		Seq int IDENTITY(1,1) NOT NULL
	)

	CREATE TABLE #TN (
		UsageKey varchar(32)
	)

	---------------------------------------------------
	-- temp table to hold location of usage text
	---------------------------------------------------
	
	CREATE TABLE #UT (
		UsageText VARCHAR(64)
	)
	
	---------------------------------------------------
	-- usage keywords
	---------------------------------------------------
	
	DECLARE @usageKeys VARCHAR(256) = 'CapDev, Operator, Broken, Maintenance, StaffNotAvailable, OtherNotAvailable, InstrumentAvailable, User, Proposal, PropUser'
	DECLARE @nonPercentageKeys VARCHAR(256) =  'Operator, Proposal, PropUser'

	BEGIN TRY 
		---------------------------------------------------
		-- normalize punctuation
		---------------------------------------------------
		
		SET @comment = REPLACE(@comment, ', ', ',')
		SET @comment = REPLACE(@comment, ' ,', ',')
	
		---------------------------------------------------
		-- set up temp table with keywords
		---------------------------------------------------
		
		INSERT INTO #TU (UsageKey)
		SELECT Item FROM dbo.MakeTableFromList(@usageKeys)
		
		UPDATE #TU
		SET UsageKey = LTRIM(RTRIM(UsageKey))

		INSERT INTO #TN (UsageKey)
		SELECT Item FROM dbo.MakeTableFromList(@nonPercentageKeys)
		
		UPDATE #TN
		SET UsageKey = LTRIM(RTRIM(UsageKey))

		---------------------------------------------------
		-- look for keywords in text and update table with
		-- corresponding values
		---------------------------------------------------
		
		DECLARE @index int
		DECLARE @eov int
		DECLARE @val VARCHAR(24)
		DECLARE @curVal VARCHAR(24)
		DECLARE @bot INT = 0
		
		DECLARE @seq INT = 0, @next INT = 0
		DECLARE @kw VARCHAR(32)
		DECLARE @done INT = 0
		WHILE @done = 0
		BEGIN --<a>
			---------------------------------------------------
			-- get next keyword to look for
			---------------------------------------------------
			SET @kw = ''
			SELECT TOP 1 
				@kw = UsageKey + '[',
				@curVal = UsageValue,
				@seq = Seq
			FROM #TU
			WHERE Seq > @next
		
			SET @next = @seq

			---------------------------------------------------
			-- done if no more keywords,
			-- otherwise look for it in text
			---------------------------------------------------

			IF @kw = ''
				SET @done = 1
			ELSE 
			BEGIN --<b>
				SET @index = CHARINDEX(@kw, @comment)
				
				---------------------------------------------------
				-- if we found a keyword in the text
				-- parse out its values and save that in the usage table
				---------------------------------------------------
			
				IF @index > 0
				BEGIN --<c>
					SET @bot = @index
					SET @index = @index + LEN(@kw)
					SET @eov = CHARINDEX(']', @comment, @index)
					IF @eov = 0
						RAISERROR ('Could not find closing bracket for "%s"', 11, 4, @kw)

					INSERT INTO #UT ( UsageText )VALUES (SUBSTRING(@comment, @bot, (@eov - @bot) + 1))

					SET @val = ''
					SET @val = SUBSTRING(@comment, @index, @eov - @index)
					
					SET @val = REPLACE(@val, '%', '')
					SET @val = REPLACE(@val, ',', '')

					If Try_Convert(int, @val) Is Null
						RAISERROR ('Percentage value for usage "%s" is not a valid integer', 11, 5, @kw)

					UPDATE #TU
					SET UsageValue = @val
					WHERE Seq = @seq
				END --<c>
			END --<b>
		END --<a>
		---------------------------------------------------
		-- clear keywords not found from table
		---------------------------------------------------
		
		DELETE FROM #TU WHERE UsageValue IS null

		---------------------------------------------------
		-- verify percentage total
		---------------------------------------------------

		DECLARE @total INT = 0
		SELECT @total = @total + CASE WHEN NOT UsageKey IN (SELECT UsageKey FROM #TN) THEN CONVERT(INT, UsageValue) ELSE 0 END 
		FROM #TU

		IF @total <> 100
				RAISERROR ('Total percentage (%d) does not add up to 100', 11, 7, @total)
	
		---------------------------------------------------
		-- verify proposal (if user present)
		---------------------------------------------------
		DECLARE @hasUser INT = 0
		DECLARE @hasProposal INT = 0
		
		SELECT @hasUser = COUNT(*) FROM #TU WHERE UsageKey = 'User'
		SELECT @hasProposal = COUNT(*) FROM #TU WHERE UsageKey = 'Proposal'
		
		IF (@hasUser > 0 ) AND (@hasProposal = 0)
				RAISERROR ('Proposal is needed if user allocation is specified', 11, 6)
				
		---------------------------------------------------
		-- FUTURE: Vaidate proposal number?		
		---------------------------------------------------
		
		---------------------------------------------------
		-- make XML
		---------------------------------------------------

		DECLARE @s VARCHAR(512) = ''
		--
		SELECT @s =  @s + UsageKey + '="' + UsageValue + '" '
		FROM #TU
		--
		SET @usageXML = '<u ' + @s + ' />'

		---------------------------------------------------
		-- remove usage text from comment	
		---------------------------------------------------

		SELECT @comment = REPLACE(@comment, UsageText, '') FROM #UT
		
		SET @comment = REPLACE(@comment, ',,', '')
		SET @comment = REPLACE(@comment, ', ,', '')
		SET @comment = REPLACE(@comment, '. ,', '. ')
		SET @comment = REPLACE(@comment, '.,', '. ')
		SET @comment = RTRIM(@comment)

	---------------------------------------------------
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		--EXEC FormatErrorMessage @message output, @myError output
		SET @myError = ERROR_NUMBER()
		IF @myError = 50000
			SET @myError = ERROR_STATE()

		SET @message = ERROR_MESSAGE() -- + ' (' + ERROR_PROCEDURE() + ':' + CONVERT(VARCHAR(12), ERROR_LINE()) + ')'

	END CATCH

	RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ParseUsageText] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ParseUsageText] TO [PNL\D3M580] AS [dbo]
GO
