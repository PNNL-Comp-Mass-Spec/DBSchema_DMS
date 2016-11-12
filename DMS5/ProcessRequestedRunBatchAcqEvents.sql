/****** Object:  StoredProcedure [dbo].[ProcessRequestedRunBatchAcqEvents] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.ProcessRequestedRunBatchAcqEvents
/****************************************************
**
**	Desc: 
**	Process 'Requested Run Batch Acq Time Ready' events
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Dte:	03/29/2010 grk - Initial release
**			11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**			11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**    
*****************************************************/
(
	@interval int = 24 -- hours since last run
)
As
	SET NOCOUNT ON 

	declare @myError int
	set @myError = 0

	DECLARE @callingUser varchar(128) = dbo.GetUserLoginWithoutDomain('')

	DECLARE @message varchar(512)
	SET @message = ''

	---------------------------------------------------
	-- last time we did this
	---------------------------------------------------
	--
	DECLARE @threshold DATETIME
	SET @threshold = DATEADD(Hour, -1 * @interval, GETDATE())

	---------------------------------------------------
	-- temporary list of batches to calculate
	-- automatic factors for
	---------------------------------------------------
	--
	CREATE TABLE #BL (
		BatchID int
	)

	---------------------------------------------------
	-- event 'Requested Run Batch Acq Time Ready'
	-- since last time we did this
	---------------------------------------------------
	--
	INSERT INTO #BL
			( BatchID )
	SELECT
	  Target_ID
	FROM
	  T_Notification_Event
	WHERE
	  ( Event_Type = 3 ) AND Entered > @threshold


	---------------------------------------------------
	-- loop through list and make factors
	---------------------------------------------------
	--
	DECLARE @done TINYINT
	SET @done = 0
	--
	DECLARE @batchID INT
	--
	WHILE @done = 0
	BEGIN --<1>
		SET @batchID = 0
		SELECT TOP 1 @batchID = BatchID FROM #BL
		--
		IF @batchID = 0
		BEGIN
			SET @done = 1
		END
		ELSE 
		BEGIN 
			DELETE FROM #BL WHERE BatchID = @batchID
			--
			EXEC @myError = MakeAutomaticRequestedRunFactors @batchID, 'actual_run_order', @message OUTPUT, @callingUser	
			IF @myError <> 0
				SET @done = 1
		END 
	END --<1>

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	RETURN @myError
GO
GRANT VIEW DEFINITION ON [dbo].[ProcessRequestedRunBatchAcqEvents] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ProcessRequestedRunBatchAcqEvents] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ProcessRequestedRunBatchAcqEvents] TO [PNL\D3M580] AS [dbo]
GO
