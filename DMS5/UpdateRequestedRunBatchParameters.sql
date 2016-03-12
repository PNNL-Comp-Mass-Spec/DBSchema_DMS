/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunBatchParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateRequestedRunBatchParameters]
/****************************************************
**
**	Desc: 
**	Change run blocking parameters 
**	given by lists
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date: 	02/09/2010
**			02/16/2010 grk - eliminated batchID from arg list
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			12/15/2011 mem - Now updating @callingUser to SUSER_SNAME() if empty
**			03/28/2013 grk - added handling for cart, instrument
**    
*****************************************************/
(
	@blockingList text,
	@mode varchar(32),			-- 'update'
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = ''
)
As
	SET NOCOUNT ON 

	DECLARE @myError INT
	SET @myError = 0

	DECLARE @myRowCount INT
	SET @myRowCount = 0

	DECLARE @xml AS XML
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	-----------------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------------
	
	SET @message = ''

	If IsNull(@callingUser, '') = ''
		SET @callingUser = REPLACE(SUSER_SNAME(), 'PNL\', '')
		
	DECLARE @batchID int = 0

	-----------------------------------------------------------
	-----------------------------------------------------------
	BEGIN TRY 
		-----------------------------------------------------------
		-- temp table to hold new parameters
		-----------------------------------------------------------
		--
		CREATE TABLE #TMP (
			Parameter VARCHAR(32),
			Request INT,
			Value VARCHAR(128),
			ExistingValue VARCHAR(128) NULL
		)

		IF @mode = 'update' OR @mode = 'debug'
		BEGIN --<a>
			-----------------------------------------------------------
			-- populate temp table with new parameters
			-----------------------------------------------------------
			--
			SET @xml = @blockingList
			--
			INSERT INTO #TMP
				( Parameter, Request, Value )
			SELECT
				xmlNode.value('@t', 'nvarchar(256)') Parameter,		-- may be 'BK', or 'RO'
				xmlNode.value('@i', 'nvarchar(256)') Request,		-- Request ID
				xmlNode.value('@v', 'nvarchar(256)') Value
			FROM @xml.nodes('//r') AS R(xmlNode)

			-----------------------------------------------------------
			-- normalize parameter names
			-----------------------------------------------------------
			--
			UPDATE #TMP SET Parameter = 'Block' WHERE Parameter = 'BK'
			UPDATE #TMP SET Parameter = 'Run Order' WHERE Parameter ='RO'
			UPDATE #TMP SET Parameter = 'Run Order' WHERE Parameter ='Run_Order'

			IF @mode = 'debug'
			BEGIN 
				SELECT * FROM #TMP
			END 

			-----------------------------------------------------------
			-- add current values for parameters to temp table
			-----------------------------------------------------------
			--
			UPDATE #TMP
			SET ExistingValue = CASE 
								WHEN #tmp.Parameter = 'Block' THEN CONVERT(VARCHAR(128), RDS_Block)
								WHEN #tmp.Parameter = 'Run Order' THEN CONVERT(VARCHAR(128), RDS_Run_Order)
								WHEN #tmp.Parameter = 'Block' THEN CONVERT(VARCHAR(128), RDS_Block)
								WHEN #tmp.Parameter = 'Run Order' THEN CONVERT(VARCHAR(128), RDS_Run_Order)
								WHEN #tmp.Parameter = 'Status' THEN CONVERT(VARCHAR(128), RDS_Status)
								WHEN #tmp.Parameter = 'Instrument' THEN RDS_instrument_name
								ELSE ''
								END 
			FROM #TMP INNER JOIN T_Requested_Run ON #TMP.Request = dbo.T_Requested_Run.ID

			-- LC cart (requires a join)
			UPDATE #TMP
			SET ExistingValue = dbo.T_LC_Cart.Cart_Name
			FROM 
				#TMP INNER JOIN
				T_Requested_Run ON #TMP.Request = dbo.T_Requested_Run.ID INNER JOIN 
				T_LC_Cart ON T_Requested_Run.RDS_Cart_ID = dbo.T_LC_Cart.ID
			WHERE 
				#TMP.Parameter = 'Cart'


			IF @mode = 'debug'
			BEGIN 
				SELECT * FROM #TMP
			END 

			-----------------------------------------------------------
			-- and remove entries that are unchanged
			-----------------------------------------------------------
			--
			DELETE FROM #TMP WHERE (#TMP.Value = #TMP.ExistingValue)


			-----------------------------------------------------------
			-- validate
			-----------------------------------------------------------

			DECLARE @misnamedCarts VARCHAR(4096) = ''
			SELECT 
				@misnamedCarts = @misnamedCarts + #TMP.Value + ', ' 
			FROM 
				#TMP 
			WHERE 
				#TMP.Parameter = 'Cart' 
				AND NOT (#TMP.Value IN (SELECT Cart_Name FROM dbo.T_LC_Cart ))
			--
			IF @misnamedCarts != ''
				RAISERROR ('Cart(s) %s are incorrect', 11, 20, @misnamedCarts)

		END --<a>

		IF @mode = 'debug'
		BEGIN 
			SELECT * FROM #TMP
		END 
		
		-----------------------------------------------------------
		-- anything left to update?
		-----------------------------------------------------------
		--
		IF NOT EXISTS (SELECT * FROM #TMP)
		BEGIN
			SET @message = 'No run parameters to update'
			RETURN 0	
		END

		-----------------------------------------------------------
		--
		-----------------------------------------------------------

		-----------------------------------------------------------
		-- actually do update
		-----------------------------------------------------------
		--
		IF @mode = 'update'
		BEGIN --<c>
			DECLARE @transName VARCHAR(32)
			SET @transName = 'UpdateRequestedRunBatchParameters'
			BEGIN TRANSACTION @transName

			UPDATE T_Requested_Run
			SET RDS_Block = #TMP.Value
			FROM 
				T_Requested_Run INNER JOIN
				#TMP ON #TMP.Request = dbo.T_Requested_Run.ID
			WHERE 
				#TMP.Parameter = 'Block'
			
			UPDATE T_Requested_Run
			SET RDS_Run_Order = #TMP.Value
			FROM 
				T_Requested_Run INNER JOIN
				#TMP ON #TMP.Request = dbo.T_Requested_Run.ID
			WHERE 
				#TMP.Parameter = 'Run Order'

			UPDATE T_Requested_Run
			SET RDS_Status = #TMP.Value
			FROM 
				T_Requested_Run INNER JOIN
				#TMP ON #TMP.Request = dbo.T_Requested_Run.ID
			WHERE 
				#TMP.Parameter = 'Status'

			UPDATE T_Requested_Run
			SET RDS_Cart_ID = dbo.T_LC_Cart.ID
			FROM 
				T_Requested_Run INNER JOIN
				#TMP ON #TMP.Request = dbo.T_Requested_Run.ID INNER JOIN 
				dbo.T_LC_Cart ON #TMP.Value = dbo.T_LC_Cart.Cart_Name
			WHERE 
				#TMP.Parameter = 'Cart'

			UPDATE T_Requested_Run
			SET RDS_instrument_name = #TMP.Value
			FROM 
				T_Requested_Run INNER JOIN
				#TMP ON #TMP.Request = dbo.T_Requested_Run.ID
			WHERE 
				#TMP.Parameter = 'Instrument'

			COMMIT TRANSACTION @transName

			-----------------------------------------------------------
			-- convert changed items to XML for logging
			-----------------------------------------------------------
			--
			DECLARE @changeSummary VARCHAR(max)
			SET @changeSummary = ''
			--
			SELECT @changeSummary = @changeSummary + '<r i="' + CONVERT(varchar(12), Request) + '" t="' + Parameter + '" v="' + Value + '" />'
			FROM #TMP
			
			-----------------------------------------------------------
			-- log changes
			-----------------------------------------------------------
			--
			IF @changeSummary <> ''
			BEGIN
				INSERT INTO T_Factor_Log
					(changed_by, changes)
				VALUES
					(@callingUser, @changeSummary)
			END

			---------------------------------------------------
			-- Log SP usage
			---------------------------------------------------

			DECLARE @UsageMessage VARCHAR(512) = ''
			SET @UsageMessage = 'Batch: ' + Convert(varchar(12), @batchID)
			EXEC PostUsageLogEntry 'UpdateRequestedRunBatchParameters', @UsageMessage
		END --<c>

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message OUTPUT, @myError OUTPUT                           
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	RETURN @myError
                


GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunBatchParameters] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBatchParameters] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBatchParameters] TO [PNL\D3M578] AS [dbo]
GO
