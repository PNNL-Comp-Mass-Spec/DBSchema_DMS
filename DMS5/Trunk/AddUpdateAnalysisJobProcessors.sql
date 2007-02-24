/****** Object:  StoredProcedure [dbo].[AddUpdateAnalysisJobProcessors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateAnalysisJobProcessors
/****************************************************
**
**  Desc: Adds new or edits existing T_Analysis_Job_Processors
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 02/15/2007 (ticket 389)
**          02/23/2007 grk - added @AnalysisToolsList stuff
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
	@ID int output,
	@State char(1),
	@ProcessorName varchar(64),
	@Machine varchar(64),
	@Notes varchar(512),
	@AnalysisToolsList varchar(1024),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''


	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future: this could get more complicated

	---------------------------------------------------
	-- Create temporary table to hold list of analysis tools
	---------------------------------------------------

	CREATE TABLE #TD (
		ToolName varchar(128),
		ToolID int null
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary table'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	---------------------------------------------------
	-- Populate table from dataset list  
	---------------------------------------------------
	--
	INSERT INTO #TD
		(ToolName)
	SELECT
		Item
	FROM
		MakeTableFromList(@AnalysisToolsList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary table'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	---------------------------------------------------
	-- Get tool ID for each tool in temp table  
	---------------------------------------------------
	--
	UPDATE T  
	SET T.ToolID = AJT_toolID
	FROM #TD T INNER JOIN T_Analysis_Tool ON T.ToolName = AJT_toolName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating temporary table'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	---------------------------------------------------
	-- Any invalid tool names?
	---------------------------------------------------
	--
	declare @tmp int
	set @tmp = -1
	--
	SELECT @tmp = count(*)
	FROM #TD
	WHERE ToolID is null
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking for invalid tool names'
		RAISERROR (@message, 10, 1)
		return 51007
	end
	--
	if @tmp <> 0
	begin
		set @message = 'Invalid tool name'
		RAISERROR (@message, 10, 1)
		return 51008
	end

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		set @tmp = 0
		--
		SELECT @tmp = ID
			FROM  T_Analysis_Job_Processors
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
		begin
			set @message = 'No entry could be found in database for update'
			RAISERROR (@message, 10, 1)
			return 51007
		end
	end

	---------------------------------------------------
	-- set up transaction name
	---------------------------------------------------
	declare @transName varchar(32)
	set @transName = 'AddUpdateAnalysisJobProcessors'

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
		---------------------------------------------------
		-- start transaction
		--
		begin transaction @transName

		INSERT INTO T_Analysis_Job_Processors (
		ID, 
		State, 
		Processor_Name, 
		Machine, 
		Notes
		) VALUES (
		@ID, 
		@State, 
		@ProcessorName, 
		@Machine, 
		@Notes
		)
		/**/
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			return 51007
		end

		-- return IDof newly created entry
		--
		set @ID = IDENT_CURRENT('T_Analysis_Job_Processors')

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0

		---------------------------------------------------
		-- start transaction
		--
		begin transaction @transName

		UPDATE T_Analysis_Job_Processors 
		SET 
			State = @State, 
			Processor_Name = @ProcessorName, 
			Machine = @Machine, 
			Notes = @Notes
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@message, 10, 1)
			return 51004
		end
	end -- update mode

	---------------------------------------------------
	-- action for both modes
	---------------------------------------------------

	if @Mode = 'add' or @Mode = 'update' 
	begin
		---------------------------------------------------
		-- remove any references to tools that are not in the list
		--
		DELETE FROM T_Analysis_Job_Processor_Tools
		WHERE Processor_ID = @ID AND Tool_ID not in (SELECT ToolID FROM #TD)		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Remove tool reference operation failed'
			RAISERROR (@message, 10, 1)
			return 51004
		end

		---------------------------------------------------
		-- add references to tools that are in the list, but not in the table
		--
		INSERT INTO T_Analysis_Job_Processor_Tools
			(Tool_ID, Processor_ID)
		SELECT	ToolID, @ID
		FROM #TD	
		WHERE NOT ToolID IN
			(
				SELECT Tool_ID
				FROM T_Analysis_Job_Processor_Tools
				WHERE (Processor_ID = @ID)	
			)	
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Add tool reference operation failed'
			RAISERROR (@message, 10, 1)
			return 51004
		end
		commit transaction @transName
	end -- add or update mode

	return @myError


GO
