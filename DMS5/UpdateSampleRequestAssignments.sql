/****** Object:  StoredProcedure [dbo].[UpdateSampleRequestAssignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateSampleRequestAssignments
/****************************************************
**
**	Desc: 
**	Changes assignment properties to given new value
**	for given list of requested sample preps
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: grk
**	Date: 	06/14/2005
**			07/26/2005 grk - added 'req_assignment'
**			08/02/2005 grk - assignement also sets state to "open"
**			08/14/2005 grk - update state changed date
**			03/14/2006 grk - added stuff for estimated completion date
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			02/20/2012 mem - Now using a temporary table to track the requests to update
**			02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**			06/18/2014 mem - Now passing default to udfParseDelimitedIntegerList
**    
*****************************************************/
(
	@mode varchar(32),		-- 'priority', 'state', 'assignment', 'delete', 'req_assignment', 'est_completion'
	@newValue varchar(512),
	@reqIDList varchar(2048)
)
As
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @dt datetime

	declare @done int = 0
	declare @count int = 0
	declare @id int = 0
	declare @RequestIDNum varchar(12)
	
	---------------------------------------------------
	-- Populate a temorary table with the requests to process
	---------------------------------------------------
	
	Declare @tblRequestsToProcess Table
	(
		RequestID int
	)

	INSERT INTO @tblRequestsToProcess (RequestID)
	SELECT Value
	FROM dbo.udfParseDelimitedIntegerList(@reqIDList, default)
	ORDER BY Value
	
	-- Process each request in @tblRequestsToProcess
	--
	while @done = 0
	begin
		SELECT TOP 1 @id = RequestID
		FROM @tblRequestsToProcess
		WHERE RequestID > @id
		ORDER BY RequestID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
			Set @Done = 1
		Else
		Begin
			set @count = @count + 1
			Set @RequestIDNum = Convert(varchar(12), @id)
		
			-------------------------------------------------
			if @mode = 'est_completion'
			begin
				set @dt = CONVERT(datetime, @newValue)
				--
				UPDATE T_Sample_Prep_Request
				SET	[Estimated_Completion] = @dt
				WHERE (ID = @id)	
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end

			-------------------------------------------------
			if @mode = 'priority'
			begin
				-- get priority numberical value
				--
				declare @pri int
				set @pri = cast(@newValue as int)
				
				-- set priority
				--
				UPDATE T_Sample_Prep_Request
				SET	[Priority] = @pri
				WHERE (ID = @id)	
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end

			-------------------------------------------------
			-- This mode is used for web page option "Assign selected requests to preparer(s)"
			if @mode = 'assignment'
			begin
				UPDATE T_Sample_Prep_Request
				SET	Assigned_Personnel = @newValue,
				    StateChanged = getdate(),
				    [State] = 2 -- "open"
				WHERE (ID = @id)	
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end


			-------------------------------------------------
			-- This mode is used for web page option "Assign selected requests to requested personnel"
			if @mode = 'req_assignment'
			begin
				UPDATE T_Sample_Prep_Request
				SET	Assigned_Personnel = Requested_Personnel,
				    StateChanged = getdate(),
				    [State] = 2 -- "open"
				WHERE (ID = @id)	
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end

			-------------------------------------------------
			if @mode = 'state'
			begin
				-- get state ID
				declare @stID int
				set @stID = 0
				--
				SELECT @stID = State_ID
				FROM T_Sample_Prep_Request_State_Name
				WHERE (State_Name = @newValue)				
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					RAISERROR ('lookup state failed: "%s"', 10, 1, @RequestIDNum)
					return 51310
				end	
				--
				UPDATE T_Sample_Prep_Request
				SET	[State] = @stID,
					StateChanged = getdate()
				WHERE (ID = @id)	
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end

			-------------------------------------------------
			if @mode = 'delete'
			begin
				-- Deletes are ignored by this procedure
				-- Use DeleteSamplePrepRequest instead
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end

			-------------------------------------------------
			if @myError <> 0
			begin
				RAISERROR ('operation failed for: "%s"', 10, 1, @RequestIDNum)
				return 51310
			end	
		end
	end

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512) = ''
	Set @UsageMessage = 'Updated ' + Convert(varchar(12), @count) + ' prep request'
	If @count <> 0
		Set @UsageMessage = @UsageMessage + 's'
	Exec PostUsageLogEntry 'UpdateSampleRequestAssignments', @UsageMessage

	return 0


GO
GRANT EXECUTE ON [dbo].[UpdateSampleRequestAssignments] TO [DMS_Sample_Prep_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateSampleRequestAssignments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateSampleRequestAssignments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateSampleRequestAssignments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateSampleRequestAssignments] TO [PNL\D3M578] AS [dbo]
GO
