/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunCopyFactors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateRequestedRunCopyFactors
/****************************************************
**
**	Desc: 
**	Copy factors from source requested run
**  to destination requested run 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date: 	02/24/2010
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			04/25/2012 mem - Now assuring that @callingUser is not blank
**    
*****************************************************/
(
	@srcRequestID INT,
	@destRequestID INT,
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = ''
)
As
	SET NOCOUNT ON 

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	SET @message = ''

	Set @callingUser = IsNull(@callingUser, '(copy factors)')
	
	-----------------------------------------------------------
	-- Temp table to hold factors being copied
	-----------------------------------------------------------
	--
	CREATE TABLE #TMPF (
		Request INT,
		Factor VARCHAR(128),
		Value VARCHAR(128)
	)

	-----------------------------------------------------------
	-- populate temp table
	-----------------------------------------------------------
	--
	INSERT INTO #TMPF
	( Request, Factor, Value )
	SELECT
		TargetID AS Request,
		Name AS Factor,
		Value
	FROM
		T_Factor
	WHERE
		T_Factor.Type = 'Run_Request'
		AND TargetID = @srcRequestID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temp table with source request "' + CONVERT(varchar(12), @srcRequestID) + '"'
		return 51009
	end
	
	-----------------------------------------------------------
	-- clean out old factors for @destRequest
	-----------------------------------------------------------
	--
	DELETE FROM T_Factor
	WHERE T_Factor.TYPE = 'Run_Request' AND TargetID = @destRequestID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error removing existing factors for request "' + CONVERT(varchar(12), @destRequestID) + '"'
		return 51003
	end

	-----------------------------------------------------------
	-- get rid of any blank entries from temp table
	-- (shouldn't be any, but let's be cautious)
	-----------------------------------------------------------
	--
	DELETE FROM #TMPF WHERE ISNULL(Value, '') = ''

	
	-----------------------------------------------------------
	-- anything to copy?
	-----------------------------------------------------------
	--
	IF NOT EXISTS (SELECT * FROM #TMPF)
	BEGIN
		set @message = 'Nothing to copy'
		RETURN 0
	END 

	-----------------------------------------------------------
	-- copy from temp table to factors table for @destRequest
	-----------------------------------------------------------
	--
	INSERT INTO dbo.T_Factor
        ( Type, TargetID, Name, Value )
	SELECT  
		'Run_Request' AS Type, @destRequestID AS TargetID, Factor AS Name, Value 
	FROM #TMPF
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error copying factors to table for new request "' + CONVERT(varchar(12), @destRequestID) + '"'
		return 51003
	end

	-----------------------------------------------------------
	-- convert changed items to XML for logging
	-----------------------------------------------------------
	--
	DECLARE @changeSummary varchar(max)
	set @changeSummary = ''
	--
	SELECT @changeSummary = @changeSummary + '<r i="' + CONVERT(varchar(12), @destRequestID) + '" f="' + Factor + '" v="' + Value + '" />'
	FROM #TMPF
	
	-----------------------------------------------------------
	-- log changes
	-----------------------------------------------------------
	--
	INSERT INTO T_Factor_Log
		(changed_by, changes)
	VALUES
		(@callingUser, @changeSummary)


	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512) = ''
	Set @UsageMessage = 'Source: ' + Convert(varchar(12), @srcRequestID) + '; Target: ' + Convert(varchar(12), @destRequestID)
	Exec PostUsageLogEntry 'UpdateRequestedRunCopyFactors', @UsageMessage

	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunCopyFactors] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunCopyFactors] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunCopyFactors] TO [PNL\D3M580] AS [dbo]
GO
