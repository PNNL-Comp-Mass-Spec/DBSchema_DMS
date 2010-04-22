/****** Object:  StoredProcedure [dbo].[UpdateSampleRequestAssignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateSampleRequestAssignments
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
**		Auth: grk
**		Date: 6/14/2005
**		Date: 7/26/2005 grk -- added 'req_assignment'
**		Date: 8/2/2005  grk -- assignement also sets state to "open"
**		Date: 8/14/2005  grk -- update state changed date
**		Date: 3/14/2006  grk -- added stuff for estimated completion date
**    
*****************************************************/
	@mode varchar(32), -- 'priority', 'state', 'assignment', 'delete', 'req_assignment', 'est_completion'
	@newValue varchar(512),
	@reqIDList varchar(2048)
As
	declare @delim char(1)
	set @delim = ','

	declare @done int
	declare @count int

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	--
	declare @id int
	declare @dt datetime
	--
	declare @tPos int
	set @tPos = 1
	declare @tFld varchar(128)

	-- process lists into rows
	-- and insert into DB table
	--
	set @count = 0
	set @done = 0

	while @done = 0
	begin
		set @count = @count + 1

		-- process the  next field from the ID list
		--
		set @tFld = ''
		execute @done = NextField @reqIDList, @delim, @tPos output, @tFld output
		
		if @tFld <> ''
		begin
			set @id = cast(@tFld as int)

			-------------------------------------------------
			if @mode = 'est_completion'
			begin
				set @dt =  CONVERT(datetime, @newValue)
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
					RAISERROR ('lookup state failed: "%s"', 10, 1, @tFld)
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
--				DELETE FROM T_Sample_Prep_Request
--				WHERE (ID = @id)
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end

			-------------------------------------------------
			if @myError <> 0
			begin
				RAISERROR ('operation failed: "%s"', 10, 1, @tFld)
				return 51310
			end	
		end
	end

	return 0

GO
GRANT EXECUTE ON [dbo].[UpdateSampleRequestAssignments] TO [DMS_Sample_Prep_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateSampleRequestAssignments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateSampleRequestAssignments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateSampleRequestAssignments] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateSampleRequestAssignments] TO [PNL\D3M580] AS [dbo]
GO
