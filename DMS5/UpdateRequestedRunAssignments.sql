/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunAssignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateRequestedRunAssignments
/****************************************************
**
**	Desc: 
**	Changes assignment properties (priority, instrument)
**	to given new value for given list of requested runs
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/26/2003
**            12/11/2003 - grk: removed LCMS cart modes
**    
*****************************************************/
	@mode varchar(32), -- 'priority', 'instrument', 'delete'
	@newValue varchar(512),
	@reqRunIDList varchar(2048)
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
		execute @done = NextField @reqRunIDList, @delim, @tPos output, @tFld output
		
		if @tFld <> ''
		begin
			set @id = cast(@tFld as int)

			-------------------------------------------------
			if @mode = 'priority'
			begin
				-- get priority numberical value
				--
				declare @pri int
				set @pri = cast(@newValue as int)
				
				-- if priority is being set to non-zero, clear note field also
				--
				if @pri > 0
				begin
					UPDATE T_Requested_Run
					SET	RDS_priority = @pri, RDS_note = ''
					WHERE (ID = @id)	
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
				end
				else
				begin
					UPDATE T_Requested_Run
					SET	RDS_priority = @pri
					WHERE (ID = @id)	
				end
			end

			-------------------------------------------------
			if @mode = 'instrument'
			begin
				UPDATE T_Requested_Run
				SET	RDS_instrument_name = @newValue
				WHERE (ID = @id)	
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end

			-------------------------------------------------
			if @mode = 'delete'
			begin
				declare @message varchar(512)
				exec @myError = DeleteRequestedRun
										@id,
										@message output
			end

			if @myError <> 0
			begin
				RAISERROR ('operation failed: "%s"', 10, 1, @tFld)
				return 51310
			end	
		end
	end

	return 0

GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAssignments] TO [DMS_RunScheduler]
GO
