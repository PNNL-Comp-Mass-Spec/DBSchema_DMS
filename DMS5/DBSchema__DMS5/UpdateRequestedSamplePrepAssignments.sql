/****** Object:  StoredProcedure [dbo].[UpdateRequestedSamplePrepAssignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE  UpdateRequestedSamplePrepAssignments
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
**    
*****************************************************/
	@mode varchar(32), -- 'priority', 'state', 'personnel', 'delete'
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
			if @mode = 'personnel'
			begin
				UPDATE T_Sample_Prep_Request
				SET	Assigned_Personnel = @newValue
				WHERE (ID = @id)	
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end

			-------------------------------------------------
			if @mode = 'state'
			begin
				UPDATE T_Sample_Prep_Request
				SET	[State] = @newValue
				WHERE (ID = @id)	
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
			end

			-------------------------------------------------
			if @mode = 'delete'
			begin
				DELETE FROM T_Sample_Prep_Request
				WHERE (ID = @id)
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
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
GRANT EXECUTE ON [dbo].[UpdateRequestedSamplePrepAssignments] TO [DMS_Sample_Prep_Admin]
GO
