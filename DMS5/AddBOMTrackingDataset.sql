/****** Object:  StoredProcedure [dbo].[AddBOMTrackingDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE dbo.AddBOMTrackingDataset 
/****************************************************
**
**  Desc: 
**    Adds new tracking dataset for the first of the month
**    for the given year, month, and instrument
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 12/14/2012 
**    12/14/2012 grk - initial release
**    12/16/2012 grk - added concept of 'next' month
**    02/01/2013 grk - fixed broken logic for specifying year/month
**    02/23/2016 mem - Add set XACT_ABORT on
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2012, Battelle Memorial Institute
*****************************************************/
(
	@month VARCHAR(16) = '',
	@year VARCHAR(16) = '',
	@instrumentName VARCHAR(64),
	@mode VARCHAR(12) = 'add',
	@message VARCHAR(512) OUTPUT,
   	@callingUser VARCHAR(128)  = 'D3E154'
)
As
	Set XACT_ABORT, nocount on

	DECLARE @myError INT = 0
	
	---------------------------------------------------
	-- validate input arguments
	---------------------------------------------------
	IF ISNULL(@instrumentName, '') = ''
		RAISERROR ('Instrument name cannot be empty', 11, 10)

	---------------------------------------------------
	-- declare parameters for making BOM tracking dataset
	---------------------------------------------------
	
	DECLARE 
	@datasetNum VARCHAR(128) ,
	@runStart VARCHAR(32),
	@experimentNum VARCHAR(64) = 'Tracking',
	@operPRN VARCHAR(64) = @callingUser,
	@runDuration VARCHAR(16) = '10',
	@comment VARCHAR(512) = '',
	@eusProposalID VARCHAR(10) = '',
	@eusUsageType VARCHAR(50) = 'MAINTENANCE',
	@eusUsersList VARCHAR(1024) = ''

	---------------------------------------------------
	-- 
	---------------------------------------------------

	BEGIN TRY 
		set @message = ''

		---------------------------------------------------
		-- get correct BOM dates
		---------------------------------------------------
	
		DECLARE 
			@now DATETIME = GETDATE(),
			@mn VARCHAR(24) = @month,
			@yr varchar(24) = @year	

		IF @month = '' OR @month = 'next'
			SET @mn = CONVERT(VARCHAR(12), DATEPART(MONTH, @now))

		IF @year = '' OR @month = 'next'
			SET @yr = CONVERT(VARCHAR(12), DATEPART(YEAR, @now))

		declare @bom DATETIME = @mn + '/1/' + @yr + ' 12:00:00:000AM'
		
		IF @month = 'next'
			SET @bom = DATEADD(MONTH, 1, @bom)		-- Beginning of the next month after @bom

		SET @runStart = @bom

		DECLARE @dateLabel VARCHAR(24) = REPLACE(CONVERT(VARCHAR(15), @bom, 6), ' ', '')
	 
		SET @datasetNum = @instrumentName + '_' + @dateLabel

		---------------------------------------------------
		-- is it OK to make the dataset?
		---------------------------------------------------

		DECLARE @instID INT = 0
		SELECT @instID = Instrument_ID FROM dbo.T_Instrument_Name WHERE IN_name	= @instrumentName
		IF @instID = 0				
			RAISERROR ('Instrument "%s" cannot be found', 11, 20, @instrumentName)
		
		IF EXISTS (SELECT * FROM dbo.T_Dataset WHERE Dataset_Num = @datasetNum)
			RAISERROR ('Dataset "%s" already exists', 11, 21, @datasetNum)

		DECLARE @dsm VARCHAR(128) = ''                                               
		SELECT @dsm = Dataset_Num FROM dbo.T_Dataset WHERE Acq_Time_Start = @bom AND DS_instrument_name_ID = @instID
		IF(@dsm <> '')							
			RAISERROR ('Dataset "%s" has same start time', 11, 22, @datasetNum)

		SET @dsm = ''
		SELECT  @dsm =  Dataset_Num
		FROM    T_Dataset
		WHERE   ( NOT ( Acq_Time_Start IS NULL ))AND ( NOT ( Acq_Time_End IS NULL ))
				AND @bom BETWEEN Acq_Time_Start AND Acq_Time_End
				AND DS_instrument_name_ID = @instID
		IF(@dsm <> '')							
			RAISERROR ('Tracking dataset would overlap existing dataset "%s"', 11, 23, @datasetNum)
				
				                                             
		---------------------------------------------------
		-- 
		---------------------------------------------------
		IF @mode = 'debug'
		BEGIN
			PRINT 'datasetNum ' + @datasetNum 
			PRINT 'runStart ' + @runStart 
			PRINT 'experimentNum ' + @experimentNum 
			PRINT 'operPRN ' + @operPRN 
			PRINT 'runDuration ' + @runDuration 
			PRINT 'comment ' + @comment 
			PRINT 'eusProposalID ' + @eusProposalID 
			PRINT 'eusUsageType ' + @eusUsageType 
			PRINT 'eusUsersList ' + @eusUsersList 
			PRINT 'mode ' + @mode 		
		END 
	
		---------------------------------------------------
		-- 
		---------------------------------------------------
		IF @mode = 'add'
		BEGIN
			EXEC @myError = AddUpdateTrackingDataset
								@datasetNum  ,
								@experimentNum  ,
								@operPRN  ,
								@instrumentName ,
								@runStart  ,
								@runDuration  ,
								@comment  ,
								@eusProposalID  ,
								@eusUsageType  ,
								@eusUsersList  ,
								@mode  ,
								@message  output,
   								@callingUser		
		END 


	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message OUTPUT, @myError OUTPUT
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	RETURN @myError



GO
GRANT EXECUTE ON [dbo].[AddBOMTrackingDataset] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddBOMTrackingDataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddBOMTrackingDataset] TO [PNL\D3M580] AS [dbo]
GO
