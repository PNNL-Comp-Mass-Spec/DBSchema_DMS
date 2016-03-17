/****** Object:  StoredProcedure [dbo].[UpdateAnalysisJobProcessorGroupAssociations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateAnalysisJobProcessorGroupAssociations
/****************************************************
**
**	Desc:
**   Sets jobs in the job list to be associated with the given 
**   analysis job processor group
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	02/15/2007 Ticket #386
**			02/20/2007 grk - fixed references to "Group" column in associations table
**						   - 'add' mode now removes association with any other groups
**			03/28/2008 mem - Added optional parameter @callingUser; if provided, then will populate field Entered_By with this name
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			01/24/2014 mem - Added default values to three of the parameters
**			03/30/2015 mem - Tweak warning message grammar
**    
*****************************************************/
(
    @JobList varchar(6000),
    @processorGroupID varchar(32),
    @newValue varchar(64)='',			-- ignore for now, may need in future
    @mode varchar(12) = 'add',			-- 'add', 'replace', 'remove'
    @message varchar(512)='' output,
	@callingUser varchar(128) = ''
)
AS
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	declare @list varchar(1024)

	declare @AlterEnteredByRequired tinyint
	set @AlterEnteredByRequired = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	if @JobList = ''
	begin
		set @message = 'Job list is empty'
		RAISERROR (@message, 10, 1)
		return 51001
	end

	---------------------------------------------------
	-- resolve processor group ID
	---------------------------------------------------
	declare @gid int
	set @gid = CAST(@processorGroupID as int)
	--
/*
	SELECT @gid = ID
	FROM T_Analysis_Job_Processor_Group
	WHERE (Group_Name = @processorGroupName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking up processor group name'
		return @myError
	end
	--
	if @gid = 0
	begin
		set @myError = 5
		set @message = 'Processor group could not be found'
		return @myError
	end
*/
	---------------------------------------------------
	--  Create temporary table to hold list of jobs
	---------------------------------------------------
 
 	CREATE TABLE #TAJ (
		Job int
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary job table'
		RAISERROR (@message, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- Populate table from job list  
	---------------------------------------------------

	INSERT INTO #TAJ
	(Job)
	SELECT DISTINCT Item
	FROM MakeTableFromList(@JobList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary job table'
		RAISERROR (@message, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- Verify that all jobs exist 
	---------------------------------------------------
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN cast(Job as varchar(12))
		ELSE ', ' + cast(Job as varchar(12))
		END
	FROM
		#TAJ
	WHERE 
		NOT Job IN (SELECT AJ_jobID FROM T_Analysis_Job)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking job existence'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following jobs were not in the database: "' + @list + '"'
		return 51007
	end
	
	declare @jobCount int
	set @jobCount = 0
	
	SELECT @jobCount = COUNT(*) 
	FROM #TAJ
	
	set @message = 'Number of affected jobs: ' + cast(@jobCount as varchar(12))

	---------------------------------------------------
	-- get rid of existing associations if we are
	-- replacing them with jobs in list
	---------------------------------------------------
	--
	if @mode = 'replace'
	begin
		DELETE FROM T_Analysis_Job_Processor_Group_Associations
		WHERE (Group_ID = @gid)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error deleting existing group associations'
			return @myError
		end
	end

	---------------------------------------------------
	-- remove selected jobs from associations
	---------------------------------------------------
	if @mode = 'remove' or @mode = 'add'
	begin
		DELETE FROM T_Analysis_Job_Processor_Group_Associations
		WHERE Job_ID IN (SELECT Job FROM #TAJ) 
			-- AND Group_ID = @gid  -- will need this in future if multiple associations allowed per job
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error removing selected jobs from association'
			return @myError
		end
	end

	---------------------------------------------------
	-- add associations for new jobs to list
	---------------------------------------------------
	--
	if @mode = 'replace' or @mode = 'add'
	begin
		INSERT INTO T_Analysis_Job_Processor_Group_Associations
			(Job_ID, Group_ID)
		SELECT Job, @gid
		FROM #TAJ
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error adding new associations'
			return @myError
		end

		Set @AlterEnteredByRequired = 1		
	end

	-- If @callingUser is defined, then update Entered_By in T_Analysis_Job_Processor_Group_Associations
	If Len(@callingUser) > 0 And @AlterEnteredByRequired <> 0
	Begin
		-- Call AlterEnteredByUser for each processor job in #TAJ

		CREATE TABLE #TmpIDUpdateList (
			TargetID int NOT NULL
		)
		
		CREATE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)

		INSERT INTO #TmpIDUpdateList (TargetID)
		SELECT Job
		FROM #TAJ
		
		Exec AlterEnteredByUserMultiID 'T_Analysis_Job_Processor_Group_Associations', 'Job_ID', @CallingUser
		
	End

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = Convert(varchar(12), @jobCount) + ' jobs updated'
	Exec PostUsageLogEntry 'UpdateAnalysisJobProcessorGroupAssociations', @UsageMessage

	return @myError


GO
GRANT EXECUTE ON [dbo].[UpdateAnalysisJobProcessorGroupAssociations] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateAnalysisJobProcessorGroupAssociations] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobProcessorGroupAssociations] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobProcessorGroupAssociations] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobProcessorGroupAssociations] TO [PNL\D3M580] AS [dbo]
GO
