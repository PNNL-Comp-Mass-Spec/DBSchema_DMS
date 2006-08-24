/****** Object:  StoredProcedure [dbo].[EvaluatePredefinedAnalysisRulesMDS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE EvaluatePredefinedAnalysisRulesMDS
/****************************************************
** 
**		Desc: 
**      Evaluate predefined analysis rules for given
**      list of datasets and generate the specifed 
**      ouput type 
**
**		Return values: 0: success, otherwise, error code
** 
**		Parameters:
**
**		Auth:	grk
**		Date:	6/23/2005
**			   03/28/2006 grk - added protein collection fields
**			   04/04/2006 grk - increased sized of param file name
**    
*****************************************************/
    @datasetList varchar(3500),
	@message varchar(512) output
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- temporary job holding table to receive created jobs
	---------------------------------------------------
	
	CREATE TABLE #JX (
		datasetNum varchar(128),
		priority varchar(8),
		analysisToolName varchar(64),
		parmFileName varchar(255),
		settingsFileName varchar(128),
		organismDBName varchar(128),
		organismName varchar(128),
		proteinCollectionList varchar(512),
		proteinOptionsList varchar(256), 
		ownerPRN varchar(128),
		comment varchar(128),
		assignedProcessor varchar(64),
		numJobs int,
		ID int IDENTITY (1, 1) NOT NULL
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not create temporary table'
		RAISERROR (@message, 10, 1)
		return @myError
	end

	---------------------------------------------------
	---------------------------------------------------
	-- process list into datasets
	-- and make job for each one
	---------------------------------------------------
	---------------------------------------------------

	declare @jobNum varchar(32)
	declare @jobID int
	
	declare @delim char(1)
	set @delim = ','

	declare @done int
	declare @count int

	declare @tPos int
	set @tPos = 1
	declare @tFld varchar(128)

	---------------------------------------------------
	-- process list into datasets and get set of generated jobs
	-- for each one into job holding table
	---------------------------------------------------
	--
	set @count = 0
	set @done = 0
	declare @result int

	while @done = 0 and @myError = 0
	begin
		set @count = @count + 1

		---------------------------------------------------
		-- process the next dataset from the list
		---------------------------------------------------

		set @tFld = ''
		execute @done = NextField @datasetList, @delim, @tPos output, @tFld output
		
		if @tFld <> ''
		begin
			---------------------------------------------------
			-- add jobs created for the dataset to the 
			-- job holding table
			---------------------------------------------------
			set @message = ''
			exec @result = EvaluatePredefinedAnalysisRules 
									@tFld, 
									'Export Jobs', 
									@message output
		end
	end
	
	---------------------------------------------------
	-- Dump contents of job holding table
	---------------------------------------------------

	select
		ID,
		'Entry' as Job,
		datasetNum as Dataset,
		numJobs as Jobs,
		analysisToolName as Tool,
		priority as Pri,
		assignedProcessor as Processor,
		comment as Comment,
		parmFileName as [Param_File],
		settingsFileName as [Settings_File],
		organismDBName as [OrganismDB_File],
		organismName as Organism,
		proteinCollectionList,
		proteinOptionsList, 
		ownerPRN as Owner
	from #JX

	---------------------------------------------------
	--
	---------------------------------------------------
Done:
	return @myError


GO
GRANT EXECUTE ON [dbo].[EvaluatePredefinedAnalysisRulesMDS] TO [DMS_User]
GO
