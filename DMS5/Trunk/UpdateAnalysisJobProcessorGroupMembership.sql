/****** Object:  StoredProcedure [dbo].[UpdateAnalysisJobProcessorGroupMembership] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateAnalysisJobProcessorGroupMembership
/****************************************************
**
**	Desc:
**   Sets analaysis job group membership for the specified group
**   for the processors in the list according to the mode



processors in the processor list to be associated with the given 
**   analysis job processor group
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**		Auth: grk
**		Date: 02/13/2007 (Ticket #384)
**            02/20/2007 grk - Fixed reference to group ID
**    
*****************************************************/
    @processorNameList varchar(6000),
    @processorGroupID varchar(32),
    @newValue varchar(64),
    @mode varchar(32) = '', -- 'set_membership_enabled', 'add_processors', 'remove_processors', 
    @message varchar(512) output
AS
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
	declare @list varchar(1024)

 	---------------------------------------------------
	--  
	---------------------------------------------------
	--
	if @processorNameList = '' and @mode <> 'add_processors'
	begin
		set @message = 'Processor name list was empty'
		RAISERROR (@message, 10, 1)
		return 51001	
	end

 	---------------------------------------------------
	--  
	---------------------------------------------------
	--
	if @processorGroupID = ''
	begin
		set @message = 'Processor group name was empty'
		RAISERROR (@message, 10, 1)
		return 51001	
	end

	---------------------------------------------------
	--  Create temporary table to hold list of processors
	---------------------------------------------------
 
 	CREATE TABLE #TP (
		ID int,
		Processor_Name varchar(64)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary processor table'
		RAISERROR (@message, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- Populate table from processor list  
	---------------------------------------------------

	INSERT INTO #TP
	(Processor_Name)
	SELECT Item
	FROM MakeTableFromList(@processorNameList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary processor table'
		RAISERROR (@message, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- resolve processor names to IDs 
	---------------------------------------------------

	update T
	set T.ID = T_Analysis_Job_Processors.ID
	FROM #TP as T INNER JOIN T_Analysis_Job_Processors ON
	T.Processor_Name = T_Analysis_Job_Processors.Processor_Name
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error resolving processor names to IDs'
		return 51007
	end

 	---------------------------------------------------
	-- Verify that all processors exist 
	---------------------------------------------------
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN Processor_Name
		ELSE ', ' + Processor_Name
		END
	FROM
		#TP
	WHERE 
		ID is null
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking processor existence'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following processors from list were not in database:"' + @list + '"'
		return 51007
	end
	
	declare @pgid int
	set @pgid = CAST(@processorGroupID as int)

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	if @mode like 'set_membership_enabled_%'
	begin
		-- get membership enabled value for this group
		--
		declare @localMembership char(1)
		set @localMembership = REPLACE (@mode, 'set_membership_enabled_' , '' )

		-- get membership enabled value for groups other than this group
		--
		declare @nonLocalMembership char(1)
		set @nonLocalMembership = @newValue

		-- set memebership enabled value in this group
		--
		UPDATE
			T_Analysis_Job_Processor_Group_Membership
		SET	
			Membership_Enabled = @localMembership
		WHERE
			(Group_ID = @pgid) AND (Processor_ID IN (SELECT ID FROM #TP))	
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update local group membership failed'
			return 51007
		end
		
		if @nonLocalMembership <> ''
		begin
		-- set membership enabled value in groups other than this group
		--
			UPDATE
				T_Analysis_Job_Processor_Group_Membership
			SET	
				Membership_Enabled = @nonLocalMembership
			WHERE
				(Group_ID <> @pgid) AND (Processor_ID IN (SELECT ID FROM #TP))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Update non-local group membershipo failed'
				return 51007
			end
		end	
	end

/*
	---------------------------------------------------
	-- 
	---------------------------------------------------
	-- if mode = 'set_membership_enabled', set Membership_Enabled 
	-- column for member processors in @processorNameList
	-- the the value of @newValue
	if @mode = 'set_membership_enabled'
	begin
		UPDATE
			T_Analysis_Job_Processor_Group_Membership
		SET	
			Membership_Enabled = @newValue
		WHERE
			(Group_ID = @pgid) AND (Processor_ID IN (SELECT ID FROM #TP))	
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update failed'
			return 51007
		end
	end
*/
	---------------------------------------------------
	-- 
	---------------------------------------------------
	-- if mode = 'add_processors', add processors in 
	-- @processorNameList to existing membership of 
	-- group (be careful not to make duplicates)
	--
	if @mode = 'add_processors'
	begin
		INSERT INTO T_Analysis_Job_Processor_Group_Membership
			(Processor_ID, Group_ID)
		SELECT ID, @pgid
		FROM #TP
		WHERE 
		(NOT (#TP.ID IN 
			(
				SELECT Processor_ID
				FROM  T_Analysis_Job_Processor_Group_Membership
				WHERE Group_ID = @pgid
			)
		))
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update failed'
			return 51007
		end
	end
	
	---------------------------------------------------
	-- 
	---------------------------------------------------
	-- if mode = 'remove_processors', remove processors in 
	-- @processorNameList from existing membership of 
	-- group
	if @mode = 'remove_processors'
	begin
		DELETE FROM T_Analysis_Job_Processor_Group_Membership
		WHERE 
			Group_ID = @pgid AND
			(Processor_ID IN (SELECT ID FROM  #TP))
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update failed'
			return 51007
		end
	end

	return @myError
GO
