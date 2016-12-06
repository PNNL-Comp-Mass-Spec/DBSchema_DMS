/****** Object:  StoredProcedure [dbo].[GetMonthlyEMSLInstrumentUsageReport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetMonthlyEMSLInstrumentUsageReport
/****************************************************
**
**  Desc: 
**    Create a monthly usage report for multiple  
**    instruments for given year and month 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	grk
**  Date:	03/16/2012 
**			02/23/2016 mem - Add set XACT_ABORT on
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
	@year VARCHAR(12),
	@month VARCHAR(12),
	@message varchar(512) output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	DECLARE @infoOnly tinyint = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @message = ''	
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	---------------------------------------------------
	-- temp table to hold results
	---------------------------------------------------
	
	CREATE TABLE #ZR (
		EMSL_Inst_ID INT,
		Instrument VARCHAR(64),
		[Type] VARCHAR(128),
		Start DATETIME,
		Minutes INT,
		Proposal varchar(32) NULL,
		[Usage] varchar(32) NULL,
		Comment VARCHAR(4096) NULL,
		[Year] INT,
		[Month] INT,
		ID INT
	)

	---------------------------------------------------
	-- temp table to hold list of production instruments
	---------------------------------------------------
	
	CREATE TABLE #Tmp_Instruments (
		Seq INT IDENTITY(1,1) NOT NULL,
		Instrument varchar(65)
	)

	---------------------------------------------------
	-- accumulate data for all instruments, one at a time
	---------------------------------------------------
	BEGIN TRY 

		---------------------------------------------------
		-- get list of production instruments
		---------------------------------------------------

		INSERT INTO #Tmp_Instruments (Instrument)
		SELECT IN_name
		FROM T_Instrument_Name
		WHERE (IN_status = 'active') AND (IN_operations_role = 'Production')
		
		DECLARE @instrument VARCHAR(64)
		DECLARE @index INT = 0
		DECLARE @done TINYINT = 0
		
		---------------------------------------------------
		-- get usage data for given instrument
		---------------------------------------------------

		WHILE @done = 0
		BEGIN -- <a>
			SET @instrument = NULL 
			SELECT TOP 1 @instrument = Instrument 
			FROM #Tmp_Instruments 
			WHERE Seq > @index
			
			SET @index = @index + 1
			
			IF @instrument IS NULL 
			BEGIN 
				SET @done = 1
			END 
			ELSE 
			BEGIN -- <b>
				INSERT INTO #ZR (Instrument, EMSL_Inst_ID, Start, Type, Minutes, Proposal, Usage, Comment, Year, Month, ID)
				EXEC GetMonthlyInstrumentUsageReport @instrument, @year, @month, 'report', @message output
			END  -- </b>
		END -- </a>
		
		---------------------------------------------------
		-- return accumulated report
		---------------------------------------------------

		SELECT
			EMSL_Inst_ID, 
			Instrument AS DMS_Instrument, 
			[Type], 
			CONVERT(VARCHAR(24), Start, 100) AS Start, 
			Minutes, 
			Proposal, 
			[Usage], 
			Comment
		  FROM #ZR

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
	If @infoOnly <> 0 and @myError <> 0
		Print @message
		
	RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[GetMonthlyEMSLInstrumentUsageReport] TO [DDL_Viewer] AS [dbo]
GO
