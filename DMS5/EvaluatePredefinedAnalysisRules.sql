/****** Object:  StoredProcedure [dbo].[EvaluatePredefinedAnalysisRules] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.EvaluatePredefinedAnalysisRules
/****************************************************
** 
**		Desc: 
**      Evaluate predefined analysis rules for given
**      dataset and generate the specifed ouput type 
**
**		Return values: 0: success, otherwise, error code
** 
**		Parameters:
**
**		Auth:	grk
**		Date:	06/23/2005
**				03/03/2006 mem - Increased size of the AD_datasetNameCriteria and AD_expCommentCriteria fields in temporary table #AD
**			    03/28/2006 grk - added protein collection fields
**			    04/04/2006 grk - increased sized of param file name
**    
*****************************************************/
	@datasetNum varchar(128),
	@outputType varchar(12),  -- 'Show Rules', 'Show Jobs', 'Export Jobs'
	@message varchar(512) output
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	---------------------------------------------------
	-- Rule selection section
	---------------------------------------------------
	---------------------------------------------------

	---------------------------------------------------
	-- get evaluation information for this dataset
	---------------------------------------------------

	declare @Campaign varchar(128) 
	declare @Experiment varchar(128) 
	declare @ExperimentComment varchar(128) 
	declare @ExperimentLabelling varchar(128) 
	declare @Dataset varchar(128) 
	declare @Organism varchar(128) 
	declare @InstrumentName varchar(128) 
	declare @InstrumentClass varchar(128) 
	declare @DatasetComment varchar(128) 
	declare @Rating smallint
	declare @ID int 
	set @ID = 0
	--
	SELECT     
		@Campaign = Campaign,
		@Experiment = Experiment,
		@ExperimentComment = Experiment_Comment,
		@ExperimentLabelling = Experiment_Labelling,
		@Dataset = Dataset,
		@Organism = Organism,
		@InstrumentName = Instrument,
		@InstrumentClass = InstrumentClass,
		@DatasetComment = Dataset_Comment,
		@Rating = Rating,
		@ID = ID
	FROM V_Predefined_Analysis_Dataset_Info
	WHERE
		(Dataset = @datasetNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @ID = 0
	begin
		set @message = 'Could not get instrument name using dataset'
		goto done
	end
	--
	if (@Rating < 2)
	begin
		set @message = 'Dataset rating does not allow creation of jobs'
		goto done
	end

	---------------------------------------------------
	-- create temporary table to hold evaluation criteria
	---------------------------------------------------

	CREATE TABLE #AD (
		AD_level int NOT NULL ,
		AD_sequence int NULL ,
		AD_instrumentClassCriteria varchar (32)  NOT NULL ,
		AD_campaignNameCriteria varchar (128)  NOT NULL ,
		AD_experimentNameCriteria varchar (128)  NOT NULL ,
		AD_instrumentNameCriteria varchar (64)  NOT NULL ,
		AD_organismNameCriteria varchar (64)  NOT NULL ,
		AD_datasetNameCriteria varchar (128)  NOT NULL ,
		AD_expCommentCriteria varchar (128)  NOT NULL ,
		AD_labellingInclCriteria varchar (64)  NOT NULL ,
		AD_labellingExclCriteria varchar (64)  NOT NULL ,
		AD_analysisToolName varchar (64)  NOT NULL ,
		AD_parmFileName varchar (255)  NOT NULL ,
		AD_settingsFileName varchar (255)  NULL ,
		AD_organismName varchar (64)  NOT NULL ,
		AD_organismDBName varchar (64)  NOT NULL ,
		AD_proteinCollectionList varchar(512),
		AD_proteinOptionsList varchar(256), 
		AD_priority int NOT NULL ,
		AD_nextLevel int NULL ,
		AD_ID int  NOT NULL 
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not create temporary criteria table'
		goto done
	end

	---------------------------------------------------
	-- Populate the rule holding table with rules
	-- that target dataset satisfies
	---------------------------------------------------

	INSERT INTO #AD (
		AD_level,
		AD_sequence,
		AD_instrumentClassCriteria,
		AD_campaignNameCriteria,
		AD_experimentNameCriteria,
		AD_instrumentNameCriteria,
		AD_organismNameCriteria,
		AD_datasetNameCriteria,
		AD_expCommentCriteria,
		AD_labellingInclCriteria,
		AD_labellingExclCriteria,
		AD_analysisToolName,
		AD_parmFileName,
		AD_settingsFileName,
		AD_organismName,
		AD_organismDBName,
		AD_proteinCollectionList,
		AD_proteinOptionsList, 
		AD_priority,
		AD_nextLevel,
		AD_ID
	)
	SELECT
		AD_level,
		AD_sequence,
		AD_instrumentClassCriteria,
		AD_campaignNameCriteria,
		AD_experimentNameCriteria,
		AD_instrumentNameCriteria,
		AD_organismNameCriteria,
		AD_datasetNameCriteria,
		AD_expCommentCriteria,
		AD_labellingInclCriteria,
		AD_labellingExclCriteria,
		AD_analysisToolName,
		AD_parmFileName,
		AD_settingsFileName,
		AD_organismName,
		AD_organismDBName,
		AD_proteinCollectionList,
		AD_proteinOptionsList, 
		AD_priority,
		AD_nextLevel,
		AD_ID
FROM T_Predefined_Analysis
WHERE 
	(AD_enabled > 0) 
	AND ((@InstrumentClass LIKE AD_instrumentClassCriteria) OR (AD_instrumentClassCriteria = '')) 
	AND ((@InstrumentName LIKE AD_instrumentNameCriteria) OR (AD_instrumentNameCriteria = '')) 
	AND ((@Campaign LIKE  AD_campaignNameCriteria) OR (AD_campaignNameCriteria = '')) 
	AND ((@Experiment LIKE AD_experimentNameCriteria) OR (AD_experimentNameCriteria = '')) 
	AND ((@Dataset LIKE AD_datasetNameCriteria) OR (AD_datasetNameCriteria = '')) 
	AND ((@ExperimentComment LIKE AD_expCommentCriteria) OR (AD_expCommentCriteria = '')) 
	AND ((@ExperimentLabelling LIKE  AD_labellingInclCriteria) OR (AD_labellingInclCriteria = '')) 
	AND (NOT(@ExperimentLabelling LIKE AD_labellingExclCriteria) OR (AD_labellingExclCriteria = ''))
	AND ((@Organism LIKE AD_organismNameCriteria) OR (AD_organismNameCriteria = '')) /**/
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not load temporary criteria table'
		goto done
	end
	--
	if @myRowCount = 0
	begin
		set @message = 'No rules found'
		goto done
	end

	---------------------------------------------------
	-- if mode is show rules, return list of rules and exit
	---------------------------------------------------
	if @outputType = 'Show Rules'
	begin
		select
			AD_ID AS ID, AD_level AS [Level], AD_Sequence AS [Seq.], AD_nextLevel as [Next Lvl.], AD_instrumentClassCriteria AS [Instrument Class], 
			AD_campaignNameCriteria AS [Campaign Crit.], AD_experimentNameCriteria AS [Experiment Crit.], AD_instrumentNameCriteria AS [Instrument Crit.], 
			AD_organismNameCriteria AS [Organism Crit.], 
			AD_datasetNameCriteria AS [Dataset], AD_expCommentCriteria AS [Exp. Comment],
			AD_labellingInclCriteria AS [Labelling Incl.], AD_labellingExclCriteria AS [Labelling Excl.], 
			AD_analysisToolName AS [Analysis Tool], AD_parmFileName AS [Parm File], 
			AD_settingsFileName AS [Settings File], 
			AD_organismName AS Organism, 
			AD_organismDBName AS [Organism DB], 
			AD_proteinCollectionList AS [Prot. Coll.],
			AD_proteinOptionsList AS [Prot. Opts.], 
			AD_priority AS priority
		from #AD
		ORDER BY AD_level ASC
		--
		goto Done
	end
	
	---------------------------------------------------
	---------------------------------------------------
	-- Job Creation Section
	---------------------------------------------------
	---------------------------------------------------

	---------------------------------------------------
	-- Get current number of jobs for dataset
	---------------------------------------------------
	declare @numJobs int
	--
	SELECT @numJobs = COUNT(*)
	FROM T_Analysis_Job
	WHERE (AJ_datasetID = @ID)
	
	---------------------------------------------------
	-- Get list of jobs to create
	---------------------------------------------------
	
	---------------------------------------------------
	-- temporary table to hold created jobs
	---------------------------------------------------
	
	CREATE TABLE #JB (
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
		numJobs int
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not create temporary job table'
		goto done
	end

	---------------------------------------------------
	-- cycle through all rules in the holding table
	-- in evaluation order applying precedence rules
	-- and creating jobs as appropriate
	---------------------------------------------------
	declare @level int	
	declare @sequence int
	declare @datasetNameCriteria varchar (128)
	declare @expCommentCriteria varchar (128)
	declare @nextLevel int
	
	declare @priority int
	declare @parmFileName varchar(255)
	declare @settingsFileName varchar(255)
	declare @organismDBName varchar(64)
	declare @proteinCollectionList varchar(512)
	declare @proteinOptionsList varchar(256)

	declare @analysisToolName varchar(64)
	declare @organismName varchar(64)
	declare @comment varchar(128)
	declare @assignedProcessor varchar(64)
	declare @paRuleID int

	declare @jobNum varchar(32)
	declare @ownerPRN varchar(32)

	declare @tmpPriority int
	declare @tmpProcessorName varchar(64)
	
	declare @result int
	declare @go int

	declare @jobsCreated int
	set @jobsCreated = 0	

	declare @minLevel int 
	set @minLevel = 0

	---------------------------------------------------
	-- cycle through all the rules in the holding table
	---------------------------------------------------
	set @go = 1
	WHILE @go > 0 and @myError = 0
	BEGIN
		---------------------------------------------------
		-- get next evaluation rule	from holding table
		---------------------------------------------------
		SELECT TOP 1
			@analysisToolName = AD_analysisToolName,
			@parmFileName = AD_parmFileName,
			@settingsFileName = AD_settingsFileName,
			@organismName = AD_organismName,
			@organismDBName = AD_organismDBName,
			@proteinCollectionList = AD_proteinCollectionList,
			@proteinOptionsList = AD_proteinOptionsList, 
			@priority = AD_priority,
			@datasetNameCriteria = AD_datasetNameCriteria,
			@expCommentCriteria = AD_expCommentCriteria,
			@nextLevel = AD_nextLevel,
			@assignedProcessor = '',
			@paRuleID = AD_ID
		FROM #AD
		WHERE AD_level >= @minLevel
		ORDER BY AD_level, AD_Sequence, AD_ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Could not create temporary job table'
			goto done
		end
		
		---------------------------------------------------
		-- remove the rule from the holding table
		---------------------------------------------------
		DELETE FROM #AD WHERE AD_ID = @paRuleID


		---------------------------------------------------
		-- update loop terminator flag 
		-- and skip job creation if no rule was found
		---------------------------------------------------
		set @go = @myRowCount
		if @go = 0
			goto NextRule

		---------------------------------------------------
		-- evaluate rule precedence 
		---------------------------------------------------

		-- if there is a next level value for rule,
		-- set minimum level to it
		--
		if @nextLevel IS NOT NULL
			set @minLevel = @nextLevel
				      		
		---------------------------------------------------
		-- override priority and/or assigned processor
		-- according to first scheduling rule in the evaluation
		-- sequence that applies to job being created
		---------------------------------------------------

		
		SELECT TOP 1
			@tmpPriority = SR_priority, 
			@tmpProcessorName = SR_processorName
		FROM T_Predefined_Analysis_Scheduling_Rules
		WHERE
		(SR_enabled > 0) 
		AND ( (@InstrumentClass LIKE SR_instrumentClass) OR (SR_instrumentClass = '') )
		AND ( (@InstrumentName LIKE SR_instrument_Name)  OR (SR_instrument_Name = '') )
		AND ( (@datasetNum LIKE SR_dataset_Name)  OR (SR_dataset_Name = '') )
		AND ( (@analysisToolName LIKE SR_analysisToolName) OR (SR_analysisToolName = '') )
		ORDER BY SR_evaluationOrder 
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Unable to look up scheduling rule'
			goto done
		end
		--
		if @myRowCount = 1
		begin
			set @priority = @tmpPriority
			set @assignedProcessor = @tmpProcessorName
		end

		---------------------------------------------------
		-- insert job in job holding table
		---------------------------------------------------
		set @comment = 'Auto predefined ' + convert(varchar(10), @paRuleID)
		set @ownerPRN = 'H09090911' -- autouser
		--
		-- FUTURE: evaluate job validity by calling MakeAnalysisJobX
		--
		set @jobsCreated = @jobsCreated + 1 
		--
		INSERT INTO #JB (
			datasetNum,
			priority,
			analysisToolName,
			parmFileName,
			settingsFileName,
			organismDBName,
			organismName,
			proteinCollectionList,
			proteinOptionsList, 
			ownerPRN,
			comment,
			assignedProcessor,
			numJobs
		) VALUES (
			@datasetNum,
			@priority,
			@analysisToolName,
			@parmFileName,
			@settingsFileName,
			@organismDBName,
			@organismName,
			@proteinCollectionList,
			@proteinOptionsList, 
			@ownerPRN,
			@comment,
			@assignedProcessor,
			@numJobs
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Could not insert job'
			goto done
		end

NextRule:
	END

	---------------------------------------------------
	-- if we didn't schedule any jobs, 
	-- but didn't have any errors, return code of 1
	---------------------------------------------------
	
	if @myError = 0 and @jobsCreated = 0 set @myError = 1


	---------------------------------------------------
	-- if mode is 'Show Jobs', return list of jobs
	-- in holding table and exit
	---------------------------------------------------
	if @outputType = 'Show Jobs'
	begin
		select
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
			proteinCollectionList AS Protein_Collections,
			proteinOptionsList AS Protein_Options, 
			ownerPRN as Owner
		from #JB
		--
		goto Done
	end
	
	---------------------------------------------------
	-- if mode is 'Export Jobs', copy jobs to 
	-- caller's job table
	---------------------------------------------------

	if @outputType = 'Export Jobs'
	begin
		INSERT INTO #JX (
			datasetNum,
			priority,
			analysisToolName,
			parmFileName,
			settingsFileName,
			organismDBName,
			organismName,
			proteinCollectionList,
			proteinOptionsList, 
			ownerPRN,
			comment,
			assignedProcessor,
			numJobs
		)
		SELECT 
			datasetNum,
			priority,
			analysisToolName,
			parmFileName,
			settingsFileName,
			organismDBName,
			organismName,
			proteinCollectionList,
			proteinOptionsList, 
			ownerPRN,
			comment,
			assignedProcessor,
			numJobs
		 FROM #JB
	end

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
Done:
	return @myError



GO
GRANT EXECUTE ON [dbo].[EvaluatePredefinedAnalysisRules] TO [DMS_User]
GO
