/****** Object:  StoredProcedure [dbo].[AddBOMTrackingDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.AddBOMTrackingDatasets
/****************************************************
**
**  Desc: 
**    Adds new tracking dataset for the first of the month
**    for all actively tracked instruments
**    for the given year, month (or current year/month if blank)
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 12/16/2012 
**			12/16/2012 grk - initial release
**			02/23/2016 mem - Add set XACT_ABORT on
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2012, Battelle Memorial Institute
*****************************************************/
(
	@month VARCHAR(16) = '', -- current month, if blank
	@year VARCHAR(16) = '', -- current year, if blank
	@mode VARCHAR(12) = 'add', -- 'info', 'debug'
   	@callingUser VARCHAR(128)  = 'D3E154' -- Ron Moore
)
As
	Set XACT_ABORT, nocount on

	DECLARE   	               
		@myError INT = 0,
		@message VARCHAR(512) = ''
	
	---------------------------------------------------
	-- temp table to hold list of tracked instruments
	---------------------------------------------------

	CREATE TABLE #TI (
		seq int IDENTITY(1,1) NOT NULL,
		inst VARCHAR(64),
		result INT NULL,
		msg VARCHAR(512) NULL
	)

	BEGIN TRY 

		---------------------------------------------------
		-- get list of tracked instruments
		---------------------------------------------------
		
		INSERT INTO #TI (inst)	                
		SELECT VT.Name FROM dbo.V_Instrument_Tracked VT
				                                             
		---------------------------------------------------
		-- loop through tracked instruments
		-- and try to make BOM tracking dataset for each
		---------------------------------------------------

		DECLARE 
			@done TINYINT = 0,
			@seq INT = 0,
			@instrumentName VARCHAR(64),
			@msg VARCHAR(512) = '',
			@err VARCHAR(16) = ''										

		WHILE NOT @done = 1
		BEGIN --<loop>
			SET @instrumentName = ''
								
			SELECT TOP 1 
				@instrumentName = inst,
				@seq = seq		
			FROM #TI
			WHERE seq > @seq 
			ORDER BY seq ASC 
		
			IF @instrumentName = ''
				SET @done = 1
			ELSE
			BEGIN --<a>
				IF @mode in ('debug', 'info') PRINT '->' + @instrumentName
		
				IF @mode in ('add', 'debug')
				BEGIN --<b>
					EXEC @myError = AddBOMTrackingDataset
											@month  ,
											@year  ,
											@instrumentName ,
											@mode  ,
											@msg  OUTPUT,
											@callingUser											                                     
				END --<b>
				
				UPDATE #TI
				SET
					result = @myError, 
					msg = @msg
				WHERE seq = @seq												
			END --<a>																								            
		END --<loop>
		
		IF @mode in ('debug', 'info') SELECT * FROM #TI

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message OUTPUT, @myError OUTPUT
	END CATCH
	RETURN @myError

GO
GRANT EXECUTE ON [dbo].[AddBOMTrackingDatasets] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddBOMTrackingDatasets] TO [PNL\D3M578] AS [dbo]
GO
