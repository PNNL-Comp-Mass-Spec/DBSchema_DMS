/****** Object:  StoredProcedure [dbo].[EvaluatePredefinedAnalysisRules] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.EvaluatePredefinedAnalysisRules
/****************************************************
** 
**	Desc: 
**     Evaluate predefined analysis rules for given
**     dataset and generate the specifed ouput type 
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	grk
**	Date:	06/23/2005
**			03/03/2006 mem - Increased size of the AD_datasetNameCriteria and AD_expCommentCriteria fields in temporary table #AD
**		    03/28/2006 grk - added protein collection fields
**		    04/04/2006 grk - increased sized of param file name
**			11/30/2006 mem - Now evaluating dataset type for each analysis tool (Ticket #335)
**			12/21/2006 mem - Updated 'Show Rules' to include explanations for why a rule was used, altered, or skipped (Ticket #339)
**			01/26/2007 mem - Now getting organism name from T_Organisms (Ticket #368)
**			03/15/2007 mem - Replaced processor name with associated processor group (Ticket #388)
**			03/16/2007 mem - Updated to use processor group ID (Ticket #419)
**		    09/04/2007 grk - corrected bug in "@RuleEvalNotes" update.
**			12/28/2007 mem - Updated to allow preview of jobs for datasets with rating -10 (unreviewed)
**			01/04/2007 mem - Fixed bug that incorrectly allowed rules to be evaluated when rating = -10 and @outputType = 'Export Jobs'
**
*****************************************************/
(
	@datasetNum varchar(128),
	@outputType varchar(12),  -- 'Show Rules', 'Show Jobs', 'Export Jobs'
	@message varchar(512) output
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- Validate @outputType
	---------------------------------------------------
	Set @outputType = IsNull(@outputType, '')
	
	If NOT @outputType IN ('Show Rules', 'Show Jobs', 'Export Jobs')
	Begin
		set @message = 'Unknown value for @outputType (' + @outputType + '); should be "Show Rules", "Show Jobs", or "Export Jobs"'
		RAISERROR (@message, 10, 1)
		return 51001
	End
	
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
	declare @DatasetType varchar(128)
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
		@DatasetType = Dataset_Type,
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
		if @Rating <> -10 OR @outputType = 'Export Jobs'
		begin
			set @message = 'Dataset rating does not allow creation of jobs'
			goto done
		end
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


	if @outputType = 'Show Rules'
	Begin
		CREATE TABLE #RuleEval (
			[Step] int IDENTITY(1,1),
			[Level] int, 
			[Seq.] int, 
			Rule_ID int, 
			[Next Lvl.] int, 
			[Action] varchar(64), 
			[Reason] varchar(256),
			[Notes] varchar(256),
			[Analysis Tool] varchar(64), 
			[Instrument Class Crit.] varchar(32), 
			[Instrument Crit.] varchar(128), 
			[Campaign Crit.] varchar(128), 
			[Experiment Crit.] varchar(128), 
			[Organism Crit.] varchar(64), 
			[Dataset Crit.] varchar(128), 
			[Exp. Comment Crit.] varchar(128),
			[Labelling Incl.] varchar(64), 
			[Labelling Excl.] varchar(64),
			[Parm File] varchar(255), 
			[Settings File] varchar(255),
			Organism varchar(64), 
			[Organism DB] varchar(64), 
			[Prot. Coll.] varchar(512), 
			[Prot. Opts.] varchar(256),
			Priority int, 
			[Processor Group] varchar(64)
		)
	End
	
					
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
		PA.AD_level,
		PA.AD_sequence,
		PA.AD_instrumentClassCriteria,
		PA.AD_campaignNameCriteria,
		PA.AD_experimentNameCriteria,
		PA.AD_instrumentNameCriteria,
		PA.AD_organismNameCriteria,
		PA.AD_datasetNameCriteria,
		PA.AD_expCommentCriteria,
		PA.AD_labellingInclCriteria,
		PA.AD_labellingExclCriteria,
		PA.AD_analysisToolName,
		PA.AD_parmFileName,
		PA.AD_settingsFileName,
		Org.OG_Name,
		PA.AD_organismDBName,
		PA.AD_proteinCollectionList,
		PA.AD_proteinOptionsList, 
		PA.AD_priority,
		PA.AD_nextLevel,
		PA.AD_ID
	FROM T_Predefined_Analysis PA INNER JOIN
		 T_Organisms Org ON PA.AD_organism_ID = Org.Organism_ID
	WHERE (PA.AD_enabled > 0) 
		AND ((@InstrumentClass LIKE PA.AD_instrumentClassCriteria) OR (PA.AD_instrumentClassCriteria = '')) 
		AND ((@InstrumentName LIKE PA.AD_instrumentNameCriteria) OR (PA.AD_instrumentNameCriteria = '')) 
		AND ((@Campaign LIKE PA.AD_campaignNameCriteria) OR (PA.AD_campaignNameCriteria = '')) 
		AND ((@Experiment LIKE PA.AD_experimentNameCriteria) OR (PA.AD_experimentNameCriteria = '')) 
		AND ((@Dataset LIKE PA.AD_datasetNameCriteria) OR (PA.AD_datasetNameCriteria = '')) 
		AND ((@ExperimentComment LIKE PA.AD_expCommentCriteria) OR (PA.AD_expCommentCriteria = '')) 
		AND ((@ExperimentLabelling LIKE PA.AD_labellingInclCriteria) OR (PA.AD_labellingInclCriteria = '')) 
		AND (NOT(@ExperimentLabelling LIKE PA.AD_labellingExclCriteria) OR (PA.AD_labellingExclCriteria = ''))
		AND ((@Organism LIKE PA.AD_organismNameCriteria) OR (PA.AD_organismNameCriteria = ''))
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

	if @outputType = 'Show Rules'
	Begin
		INSERT INTO #RuleEval (
			[Level], [Seq.], Rule_ID, [Next Lvl.], 
			[Action], [Reason], 
			[Notes], [Analysis Tool],
			[Instrument Class Crit.], [Instrument Crit.], 
			[Campaign Crit.], [Experiment Crit.], 
			[Organism Crit.], [Dataset Crit.], [Exp. Comment Crit.],
			[Labelling Incl.], [Labelling Excl.],
			[Parm File], [Settings File],
			Organism, [Organism DB], [Prot. Coll.], [Prot. Opts.],
			Priority, [Processor Group])
		SELECT	AD_level, AD_sequence, AD_ID, AD_nextLevel,
				'Skip' AS [Action], 'Level skip' AS [Reason], 
				'' AS [Notes], AD_analysisToolName,
				AD_instrumentClassCriteria, AD_instrumentNameCriteria,
				AD_campaignNameCriteria, AD_experimentNameCriteria,
				AD_organismNameCriteria, AD_datasetNameCriteria, AD_expCommentCriteria,
				AD_labellingInclCriteria, AD_labellingExclCriteria,
				AD_parmFileName, AD_settingsFileName,
				AD_organismName, AD_organismDBName, 
				AD_proteinCollectionList, AD_proteinOptionsList, 
				AD_priority, '' AS [Processor Group]
		FROM #AD
		ORDER BY AD_level, AD_Sequence, AD_ID
	
	End
	
	---------------------------------------------------
	---------------------------------------------------
	-- Job Creation / Rule Evaluation Section
	---------------------------------------------------
	---------------------------------------------------

	---------------------------------------------------
	-- Get current number of jobs for dataset
	---------------------------------------------------
	declare @numJobs int
	set @numJobs = 0
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
		associatedProcessorGroup varchar(64),
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
	declare @RuleNextLevel int
	
	declare @priority int
	declare @parmFileName varchar(255)
	declare @settingsFileName varchar(255)
	declare @organismDBName varchar(64)
	declare @proteinCollectionList varchar(512)
	declare @proteinOptionsList varchar(256)

	declare @analysisToolName varchar(64)
	declare @organismName varchar(64)
	declare @comment varchar(128)
	declare @associatedProcessorGroup varchar(64)
	declare @paRuleID int

	declare @jobNum varchar(32)
	declare @ownerPRN varchar(32)

	declare @tmpPriority int
	declare @tmpProcessorGroupID int
	declare @SchedulingRulesID int

	declare @allowedDatasetTypes varchar(255)
	
	declare @result int
	declare @Continue int

	declare @jobsCreated int
	set @jobsCreated = 0	

	declare @minLevel int 
	set @minLevel = 0

	declare @UseRule tinyint
	declare @RuleAction varchar(64)
	declare @RuleActionReason varchar(256)
	declare @RuleEvalNotes varchar(256)

	---------------------------------------------------
	-- cycle through all the rules in the holding table
	---------------------------------------------------
	Set @Continue = 1
	While @Continue > 0 and @myError = 0
	Begin -- <a>
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
			@RuleNextLevel = AD_nextLevel,
			@associatedProcessorGroup = '',
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

		set @Continue = @myRowCount
		
		---------------------------------------------------
		-- remove the rule from the holding table
		---------------------------------------------------
		DELETE FROM #AD WHERE AD_ID = @paRuleID

		If @Continue <> 0
		Begin -- <b>
			
			Set @UseRule = 1
			Set @RuleAction = 'Use'
			Set @RuleActionReason = 'Pass filters'
			Set @RuleEvalNotes = ''

			---------------------------------------------------
			-- Validate that @DatasetType is appropriate for this analysis tool
			---------------------------------------------------
			--
			SELECT  @allowedDatasetTypes = AJT_allowedDatasetTypes
			FROM    T_Analysis_Tool
			WHERE   (AJT_toolName = @analysisToolName)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error looking for allowed dataset types for tool'
				return 51007
			end
			
			If Not Exists (SELECT * FROM MakeTableFromList(@allowedDatasetTypes) WHERE Item = @DatasetType)
			Begin
				-- Dataset type is not allowed for this tool
				Set @UseRule = 0
				Set @RuleAction = 'Skip'
				Set @RuleActionReason = 'Dataset type "' + @DatasetType + '" is not allowed for analysis tool'
			End
			
			If @UseRule = 1
			Begin -- <c>
				---------------------------------------------------
				-- evaluate rule precedence 
				---------------------------------------------------

				-- if there is a next level value for rule,
				-- set minimum level to it
				--
				If @RuleNextLevel IS NOT NULL
				Begin
					Set @minLevel = @RuleNextLevel
					If Len(@RuleEvalNotes) > 0
						Set @RuleEvalNotes = @RuleEvalNotes + '; '
					Set @RuleEvalNotes = @RuleEvalNotes + 'Next rule must have level >= ' + Convert(varchar(12), @RuleNextLevel)
				End
						    		
				---------------------------------------------------
				-- override priority and/or assigned processor
				-- according to first scheduling rule in the evaluation
				-- sequence that applies to job being created
				---------------------------------------------------
				
				Set @SchedulingRulesID = 0
				SELECT TOP 1
					@tmpPriority = SR_priority, 
					@tmpProcessorGroupID = SR_processorGroupID,
					@SchedulingRulesID = ID
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
				begin -- <d>
					set @priority = @tmpPriority
					If IsNull(@tmpProcessorGroupID, 0) > 0
					Begin
						SELECT @associatedProcessorGroup = Group_Name
						FROM dbo.T_Analysis_Job_Processor_Group
						WHERE (ID = @tmpProcessorGroupID)
						
						Set @associatedProcessorGroup = IsNull(@associatedProcessorGroup, '')
					End
					Else
						Set @associatedProcessorGroup = ''
			
					If Len(@RuleEvalNotes) > 0
						Set @RuleEvalNotes = @RuleEvalNotes + '; '
					Set @RuleEvalNotes = @RuleEvalNotes + 'Priority set to ' + Convert(varchar(12), @priority) 
					
					If Len(@associatedProcessorGroup) > 0
						Set @RuleEvalNotes = @RuleEvalNotes + ' and processor group set to "' + @associatedProcessorGroup + '"'
					
					Set @RuleEvalNotes = @RuleEvalNotes + ' due to ID ' + Convert(varchar(12), @SchedulingRulesID) + ' in T_Predefined_Analysis_Scheduling_Rules'
				end -- </d>

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
					associatedProcessorGroup,
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
					@associatedProcessorGroup,
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
			End -- </c>

			if @outputType = 'Show Rules'
			Begin
				UPDATE #RuleEval
				SET [Action] = @RuleAction, 
					[Reason] = @RuleActionReason, 
					[Notes] = @RuleEvalNotes,
					Priority = @priority, 
					[Processor Group] = @associatedProcessorGroup
				WHERE Rule_ID  = @paRuleID
			End
		End -- </b>

	End -- </a>

	---------------------------------------------------
	-- if we didn't schedule any jobs, 
	-- but didn't have any errors, return code of 1
	---------------------------------------------------
	
	if @myError = 0 and @jobsCreated = 0 
		set @myError = 1

	---------------------------------------------------
	-- if mode is show rules, return list of rules and exit
	---------------------------------------------------
	if @outputType = 'Show Rules'
	begin
		SELECT *
		FROM #RuleEval
		ORDER BY [Step]
		--
		goto Done
	end

	---------------------------------------------------
	-- if mode is 'Show Jobs', return list of jobs
	-- in holding table and exit
	---------------------------------------------------
	if @outputType = 'Show Jobs'
	begin
		SELECT
			'Entry' as Job,
			datasetNum as Dataset,
			numJobs as Jobs,
			analysisToolName as Tool,
			priority as Pri,
			associatedProcessorGroup as Processor_Group,
			comment as Comment,
			parmFileName as [Param_File],
			settingsFileName as [Settings_File],
			organismDBName as [OrganismDB_File],
			organismName as Organism,
			proteinCollectionList AS Protein_Collections,
			proteinOptionsList AS Protein_Options, 
			ownerPRN as Owner
		FROM #JB
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
			associatedProcessorGroup,
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
			associatedProcessorGroup,
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
