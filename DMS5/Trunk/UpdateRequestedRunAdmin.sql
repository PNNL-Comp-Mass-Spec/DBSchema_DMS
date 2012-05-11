/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunAdmin] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateRequestedRunAdmin
/****************************************************
**
**	Desc: 
**	Requested run admin operations 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date: 	03/09/2010
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			12/12/2011 mem - Now calling AlterEventLogEntryUserMultiID
**    
*****************************************************/
(
	@requestList text,
	@mode varchar(32),				-- 'Active', 'Inactive', or 'delete'
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = ''
)
As
	SET NOCOUNT ON 

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	DECLARE @xml AS xml
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	SET @message = ''

	Declare @UsageMessage varchar(512) = ''
	Declare @stateID int = 0

	-----------------------------------------------------------
	-- temp table to hold list of requests
	-----------------------------------------------------------
	--
	CREATE TABLE #TMP (
		Item VARCHAR(128),
		Status VARCHAR(32) NULL,
		Origin VARCHAR(32) NULL,
		ItemID int NULL
	)
	SET @xml = @requestList
	--
	INSERT INTO #TMP
		( Item )
	select
		xmlNode.value('@i', 'nvarchar(256)') Item
	FROM @xml.nodes('//r') AS R(xmlNode)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to convert list'
		GOTO DoneNoLog
	end

	-----------------------------------------------------------
	-- validate request list
	-----------------------------------------------------------
	--
	 UPDATE
		#TMP
	 SET
		Status = RDS_Status,
		Origin = RDS_Origin
	 FROM
		#TMP
		INNER JOIN dbo.T_Requested_Run ON Item = CONVERT(VARCHAR(12), dbo.T_Requested_Run.ID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to get status'
		GOTO DoneNoLog
	end
	
	IF EXISTS (SELECT * FROM #TMP WHERE Status IS NULL)
	BEGIN
		SET @myError = 51012
		set @message = 'There were invalid request IDs'
		GOTO DoneNoLog
	end

	IF EXISTS (SELECT * FROM #TMP WHERE not Status IN ('Active', 'Inactive'))
	BEGIN
		SET @myError = 51013
		set @message = 'Cannot change requests that are in status other than "Active" or "Inactive"'
		GOTO DoneNoLog
	end

	IF EXISTS (SELECT * FROM #TMP WHERE not Origin = 'user')
	BEGIN
		SET @myError = 51013
		set @message = 'Cannot change requests that were not entered by user'
		GOTO DoneNoLog
	end


	-----------------------------------------------------------
	-- Populate column ItemID in #TMP
	-----------------------------------------------------------
	--
	UPDATE #TMP
	SET ItemID = CONVERT(INT, Item) 
	
	-----------------------------------------------------------
	-- Populate a temporary table with the list of Requested Run IDs to be updated or deleted
	-----------------------------------------------------------
	--
	CREATE TABLE #TmpIDUpdateList (
		TargetID int NOT NULL
	)
	
	CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)
	
	INSERT INTO #TmpIDUpdateList (TargetID)
	SELECT DISTINCT ItemID
	FROM #TMP
	ORDER BY ItemID

	-----------------------------------------------------------
	--  Update status
	-----------------------------------------------------------
	--
	IF @mode = 'Active' OR @mode = 'Inactive'
	BEGIN
		UPDATE 
			T_Requested_Run
		SET 
			RDS_Status = @mode
		WHERE 
			ID IN (SELECT ItemID FROM #TMP)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to update status'
			GOTO done
		end

		Set @UsageMessage = 'Updated ' + Convert(varchar(12), @myRowCount) + ' requests'

		If Len(@callingUser) > 0
		Begin
			-- @callingUser is defined; call AlterEventLogEntryUserMultiID
			-- to alter the Entered_By field in T_Event_Log
			-- This procedure uses #TmpIDUpdateList
			--
			SELECT @stateID = State_ID
			FROM T_Requested_Run_State_Name
			WHERE (State_Name = @mode)
			
			Exec AlterEventLogEntryUserMultiID 11, @stateID, @callingUser

		End
		
		GOTO Done
	END

	-----------------------------------------------------------
	-- Delete requests
	-----------------------------------------------------------
	--
	IF @mode = 'delete'
	BEGIN
		DELETE FROM  
			T_Requested_Run
		WHERE 
			ID IN (SELECT ItemID FROM #TMP)		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to delete requests'
			GOTO done
		end

		Set @UsageMessage = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' requests'

		If Len(@callingUser) > 0
		Begin
			-- @callingUser is defined; call AlterEventLogEntryUserMultiID
			-- to alter the Entered_By field in T_Event_Log
			-- This procedure uses #TmpIDUpdateList
			--
			set @stateID = 0
			
			Exec AlterEventLogEntryUserMultiID 11, @stateID, @callingUser

		End
		
		GOTO Done
	END
	
Done:
	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------
	
	Exec PostUsageLogEntry 'UpdateRequestedRunAdmin', @UsageMessage

DoneNoLog:
	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAdmin] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunAdmin] TO [Limited_Table_Write] AS [dbo]
GO
