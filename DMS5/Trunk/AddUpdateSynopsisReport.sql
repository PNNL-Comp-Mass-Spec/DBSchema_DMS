/****** Object:  StoredProcedure [dbo].[AddUpdateSynopsisReport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateSynopsisReport
/****************************************************
**
**	Desc: Adds new or updates existing sysnopsis report requests in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@SynReportName  name for the new Peptide Synopsis Report
**	
**
**		Auth: jds
**		Date: 09/10/2004
**			  07/27/2005 mem - Now skipping some of the validity checks when @mode = 'update' and we're setting the state to State_ID 100 or higher
**							 - Increased size of variables populated using CreateLikeClauseFromSeparatedString
**    
*****************************************************/
(
	@SynReportID varchar(32) output, 
	@SynReportName varchar(32), 
	@SynDescription varchar(255), 
	@SynDSMatchList varchar(2048), 
	@SynInsMatchList varchar(255), 
	@SynParmFileMatchList varchar(255),
	@SynFastaFileMatchList varchar(255),
	@SynCompJobNum varchar(32),
	@SynScrollDSDates varchar(32),
	@SynScrollDSTimeFrame varchar(32),
	@SynDSStartDate varchar(10),
	@SynDSEndDate varchar(10),
	@SynScrollJobDates varchar(32),
	@SynScrollJobTimeFrame varchar(32),
	@SynJobStartDate varchar(10),
	@SynJobEndDate varchar(10),
	@SynUseSynFiles varchar(32),
	@SynReportSort int,
	@SynPrimaryFilterID int,
	@SynSecondaryFilterID int,
	@SynReqPriPepPerProtein int,
	@SynReqPriSecPepPerProtein int,
	@SynReqOlapPepPerOlapProtein int,
	@SynRunInterval int,
	@SynRepeatCount int,
	@SynStateDescription varchar(255),
	@SynOutputForm varchar(64),
	@SynComment varchar(255),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	---------------------------------------------------
	-- Get the State ID using the State Description
	---------------------------------------------------

	declare @SynStateID int
	set @SynStateID = 0
	--
	execute @SynStateID = GetSynReportStateID @SynStateDescription

	---------------------------------------------------
	-- If we're updating an existing entry and setting its
	-- state ID to 100 or higher, then skip some of the validity checks
	---------------------------------------------------
	declare @SkipValidityChecks tinyint
	set @SkipValidityChecks = 0
	
	if @mode = 'update' and @SynStateID >= 100
		set @SkipValidityChecks = 1


	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if LEN(@SynReportName) < 1
	begin
		set @myError = 51000
		RAISERROR ('Peptide Synopsis Report Name was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError

	if LEN(@SynDescription) < 1
	begin
		set @myError = 51000
		RAISERROR ('Peptide Synopsis Report Description was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError


	---------------------------------------------------
	-- Validate Date input fields
	-- If blank, set to null.  If invalid, raise error
	---------------------------------------------------
	if len(@SynDSStartDate) < 1 
	begin
		set @SynDSStartDate = null
	end
	else if (SELECT ISDATE(@SynDSStartDate)) = 0
	begin
		set @myError = 51000
		RAISERROR ('Dataset Start Date is not a valid date.', 10, 1)
	end

	if @myError <> 0
		return @myError


	if len(@SynDSEndDate) < 1 
	begin
		set @SynDSEndDate = null
	end
	else if (SELECT ISDATE(@SynDSEndDate)) = 0
	begin
		set @myError = 51000
		RAISERROR ('Dataset End Date is not a valid date.', 10, 1)
	end

	if @myError <> 0
		return @myError

	if len(@SynJobStartDate) < 1 
	begin
		set @SynJobStartDate = null
	end
	else if (SELECT ISDATE(@SynJobStartDate)) = 0
	begin
		set @myError = 51000
		RAISERROR ('Job Start Date is not a valid date.', 10, 1)
	end

	if @myError <> 0
		return @myError
	
	if len(@SynJobEndDate) < 1 
	begin
		set @SynJobEndDate = null
	end
	else if (SELECT ISDATE(@SynJobEndDate)) = 0
	begin
		set @myError = 51000
		RAISERROR ('Job End Date is not a valid date.', 10, 1)
	end

	if @myError <> 0
		return @myError
	
	---------------------------------------------------
	-- Validate Match List input fields
	-- If blank, set to %
	---------------------------------------------------
	if LEN(@SynDSMatchList) < 1
	begin
		set @SynDSMatchList = '%'
	end
	
	if LEN(@SynInsMatchList) < 1
	begin
		set @SynInsMatchList = '%'
	end

	if LEN(@SynParmFileMatchList) < 1
	begin
		set @SynParmFileMatchList = '%'
	end

	if LEN(@SynFastaFileMatchList) < 1
	begin
		set @SynFastaFileMatchList = '%'
	end

	---------------------------------------------------
	-- Validate scrolling Dates input fields
	-- If <> 0 or 1, raise error
	---------------------------------------------------
	
	If @SkipValidityChecks = 0
	Begin
		if cast(@SynScrollDSDates as int) <> 1 and cast(@SynScrollDSDates as int) <> 0
		begin
			set @myError = 51000
			RAISERROR ('Scrolling Dataset Dates must be either a 0 - non-scrolling OR 1 - scrolling', 10, 1)
		end
		--
		if @myError <> 0
			return @myError

		if cast(@SynScrollDSDates as int) = 1 and cast(@SynScrollDSTimeFrame as int) < 0
		begin
			set @myError = 51000
			RAISERROR ('Scrolling Dataset Time Frame must be positive if Scrolling Dataset Dates = 1', 10, 1)
		end
		--
		if @myError <> 0
			return @myError


		if Cast(@SynScrollJobDates as int) <> 1 and Cast(@SynScrollJobDates as int) <> 0
		begin
			set @myError = 51000
			RAISERROR ('Scrolling Job Dates must be either a 0 - non-scrolling OR 1 - scrolling', 10, 1)
		end
		--
		if @myError <> 0
			return @myError

		if Cast(@SynScrollJobDates as int) = 1 and Cast(@SynScrollJobTimeFrame as int) < 0
		begin
			set @myError = 51000
			RAISERROR ('Scrolling Job Time Frame must be positive if Scrolling Job Dates = 1', 10, 1)
		end
		--
		if @myError <> 0
			return @myError

		if Cast(@SynUseSynFiles as int) <> 1 and Cast(@SynUseSynFiles as int) <> 0
		begin
			set @myError = 51000
			RAISERROR ('Use Synopsis Files must be either a 0 - use first hits files OR 1 - use synopsis files', 10, 1)
		end
		--
		if @myError <> 0
			return @myError

		if (select count(aj_jobId) from t_analysis_job, t_analysis_tool where aj_jobid = @SynCompJobNum 
		and ajt_toolid = aj_analysisToolID and ajt_toolname in ('Sequest', 'AgilentSequest')) = 0
		begin
			set @myError = 51000
			RAISERROR ('The Comparison job entered is not valid.', 10, 1)
		end
		--
		if @myError <> 0
			return @myError


		if (SELECT DISTINCT count(Filter_Set_ID) FROM V_Filter_Sets
		where filter_set_ID = @SynPrimaryFilterID) = 0
		begin
			set @myError = 51000
			RAISERROR ('The Primary Filter ID is not valid.', 10, 1)
		end
		--
		if @myError <> 0
			return @myError

		if (SELECT DISTINCT count(Filter_Set_ID) FROM V_Filter_Sets
		where filter_set_ID = @SynSecondaryFilterID) = 0
		begin
			set @myError = 51000
			RAISERROR ('The Secondary Filter ID is not valid.', 10, 1)
		end
		--
		if @myError <> 0
			return @myError

		if @SynReqPriPepPerProtein < 1
		begin
			set @myError = 51000
			RAISERROR ('The Required Primary Peptide per Protein must be greater than 0.', 10, 1)
		end
		--
		if @myError <> 0
			return @myError

		if (@SynReqPriSecPepPerProtein < 1) OR (@SynReqPriSecPepPerProtein > @SynReqPriPepPerProtein)
		begin
			set @myError = 51000
			RAISERROR ('The Required Primary + Secondary Peptide per Protein must be greater than 0 and less than or equal to Required Primary Peptide per Protein.', 10, 1)
		end
		--
		if @myError <> 0
			return @myError

		if @SynReqOlapPepPerOlapProtein < 1 OR @SynReqOlapPepPerOlapProtein > @SynReqPriPepPerProtein
		begin
			set @myError = 51000
			RAISERROR ('The Required Overlap Peptide per Protein must be greater than 0 and less than or equal to Required Primary Peptide per Protein.', 10, 1)
		end
		--
		if @myError <> 0
			return @myError

		if @SynRunInterval < 1
		begin
			set @myError = 51000
			RAISERROR ('The Run Interval must be greater than 0.', 10, 1)
		end
		--
		if @myError <> 0
			return @myError

		if @SynRepeatCount < 0
		begin
			set @myError = 51000
			RAISERROR ('The Run Interval must be greater than or equal to 0.', 10, 1)
		end
		--
		if @myError <> 0
			return @myError
		
		---------------------------------------------------
		-- Now that all the data has passed, check the count to determine if
		-- too many or too few records are trying to be compared.
		---------------------------------------------------
		declare @datasetRecCount as int
		declare @DatasetStr as varchar(4096)
		declare @InstrumentStr as varchar(1024)
		declare @ParamFileStr as varchar(1024)
		declare @OrganismStr as varchar(1024)
		declare @DSStartDateStr as varchar(200)
		declare @JobStartDateStr as varchar(200)
		declare @SqlA as varchar(6000)
		declare @SqlB as varchar(8000)
		declare	@SynDSStartDateTemp varchar(10)
		declare	@SynDSEndDateTemp varchar(10)
		declare	@SynJobStartDateTemp varchar(10)
		declare	@SynJobEndDateTemp varchar(10)

		set @SynDSStartDateTemp = ISNULL(@SynDSStartDate, '1/1/2000')
		set @SynDSEndDateTemp = ISNULL(@SynDSEndDate, convert(char(10), getdate(), 101))
		if cast(@SynScrollDSDates as int) = 1
		begin
			set @SynDSEndDateTemp = convert(char(10), getdate(), 101)
			set @SynDSStartDateTemp = convert(char(10), DATEADD(day,-Cast(@SynScrollDSTimeFrame as integer), getdate()), 101)
		end
		set @DSStartDateStr = ' AND ([Dataset_Created]>''' + @SynDSStartDateTemp + ''')'
		set @DSStartDateStr = @DSStartDateStr + ' AND ([Dataset_Created]<''' + @SynDSEndDateTemp + ''')'

		set @SynJobStartDateTemp = ISNULL(@SynJobStartDate, '1/1/2000')
		set @SynJobEndDateTemp = ISNULL(@SynJobEndDate, convert(char(10), getdate(), 101))
		if cast(@SynScrollJobDates as int) = 1
		begin
			set @SynJobEndDateTemp = convert(char(10), getdate(), 101)
			set @SynJobStartDateTemp = convert(char(10), DATEADD(day,-Cast(@SynScrollDSTimeFrame as integer), getdate()), 101)
		end
		set @JobStartDateStr = ' AND ([Finished]>''' + @SynJobStartDateTemp + ''')'
		set @JobStartDateStr = @JobStartDateStr + ' AND ([Finished]<''' + @SynJobEndDateTemp + ''')'


		set @DatasetStr = (select dbo.CreateLikeClauseFromSeparatedString(@SynDSMatchList, '[Dataset]', ','))
		set @InstrumentStr = (select dbo.CreateLikeClauseFromSeparatedString(@SynInsMatchList, '[Instrument]', ','))
		set @ParamFileStr = (select dbo.CreateLikeClauseFromSeparatedString(@SynParmFileMatchList, '[Parm File]', ','))
		set @OrganismStr = (select dbo.CreateLikeClauseFromSeparatedString(@SynFastaFileMatchList, '[Organism DB]', ','))
		
		-- Create a temporary stored procedure that returns the count of matching datasets
		--
		Set @SqlA = ''
		Set @SqlB = ''
		
		set @SqlA = @SqlA + ' create proc ##SPTempCountDatasets @datasetRecCount int output as '
		set @SqlA = @SqlA + ' SELECT @datasetRecCount = count(*)'
		set @SqlA = @SqlA + ' FROM (SELECT AJR.*, DDR.Created AS Dataset_Created'
		set @SqlA = @SqlA +			' FROM dbo.V_Analysis_Job_ReportEx AJR INNER JOIN'
		set @SqlA = @SqlA +			' dbo.V_Dataset_Detail_Report DDR ON AJR.Dataset = DDR.Dataset) AS V_JobsForSynopsisReporter'
		set @SqlA = @SqlA + ' WHERE ('
		-- Note: @DatasetStr will be added in to @SqlA and @SqlB below
		set @SqlB = @SqlB +			' AND ' + @InstrumentStr
		set @SqlB = @SqlB +			' AND ' + @ParamFileStr
		set @SqlB = @SqlB +			' AND ' + @OrganismStr
		set @SqlB = @SqlB +			@DSStartDateStr
		set @SqlB = @SqlB +			@JobStartDateStr
		set @SqlB = @SqlB +			' AND ([Finished] IS NOT NULL)'
		set @SqlB = @SqlB +			' AND ([State]=''Complete'')'
		set @SqlB = @SqlB +			' AND ([Tool Name] in (''Sequest'', ''AgilentSequest''))'
		set @SqlB = @SqlB +		  ')'
		set @SqlB = @SqlB +		' OR ([JobNum]=' + @SynCompJobNum + ')'

		exec(@SqlA + @DatasetStr + @SqlB)

		exec ##SPTempCountDatasets @datasetRecCount output

		drop proc ##SPTempCountDatasets

		if @datasetRecCount < 2
		begin
			set @myError = 51000
			set @msg = 'Your criteria returned: ' + convert(varchar(32), @datasetRecCount) + ' Record(s).  Please expand your parameters and try again.'
			RAISERROR (@msg, 10, 1)
		end	  

		if @datasetRecCount > 50
		begin
			set @myError = 51000
			set @msg = 'Your criteria returned: ' + convert(varchar(32), @datasetRecCount) + ' Record(s).  Please narrow your parameters and try again.'
			RAISERROR (@msg, 10, 1)
		end	  

		if @myError <> 0
		begin
			return @myError
			set @msg = 'Error running dynamic sql: ' + @SqlA
			RAISERROR (@msg, 10, 1)
		end
	End
	
	
	---------------------------------------------------
	-- Is entry already in database?
	-- Not sure if we need to check for duplicate names
	---------------------------------------------------

/*	declare @reportName char(32)
	set @reportName = ''
	--
	execute @reportName = GetPepSynReportName @SynReportID

	-- cannot create an entry that already exists
	-- Not sure if we will need this yet

	--
	if @reportID <> '' and @mode = 'add'
	begin
		set @msg = 'Cannot add: Peptide Synopsis Report "' + @pepSynReportName + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end
*/
	---------------------------------------------------
	-- cannot update a non-existent entry
	---------------------------------------------------

	if @SynReportID = 0 and @mode = 'update'
	begin
		set @msg = 'Cannot update: Peptide Synopsis Report "' + @SynReportName + '" is not in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_Peptide_Synopsis_Reports (
			[Name],
			[Description],
			Dataset_Match_List,
			Instrument_Match_List,
			Param_File_Match_List,
			Fasta_File_Match_List,
			Experiment_Match_List,
			Comparison_Job_Number,
			Scrolling_Dataset_Dates,
			Scrolling_Dataset_Time_Frame,
			Dataset_Start_Date,
			Dataset_End_Date,
			Scrolling_Job_Dates,
			Scrolling_Job_Time_Frame,
			Job_Start_Date,
			Job_End_Date,
			Use_Synopsis_Files,
			Report_Sorting,
			Primary_Filter_ID,
			Secondary_Filter_ID,
			Required_Primary_Peptides_per_Protein,
			Required_PrimaryPlusSecondary_Peptides_per_Protein,
			Required_Overlap_Peptides_per_Overlap_Protein,
			Run_Interval,
			Repeat_Count,
			State,
			Task_Type,
			Database_Name,
			Output_Form,
			Comment
		) VALUES (
			@SynReportName, 
			@SynDescription, 
			@SynDSMatchList, 
			@SynInsMatchList, 
			@SynParmFileMatchList,
			@SynFastaFileMatchList,
			'%',
			@SynCompJobNum,
			@SynScrollDSDates,
			@SynScrollDSTimeFrame,
			@SynDSStartDate,
			@SynDSEndDate,
			@SynScrollJobDates,
			@SynScrollJobTimeFrame,
			@SynJobStartDate,
			@SynJobEndDate,
			@SynUseSynFiles,
			@SynReportSort,
			@SynPrimaryFilterID,
			@SynSecondaryFilterID,
			@SynReqPriPepPerProtein,
			@SynReqPriSecPepPerProtein,
			@SynReqOlapPepPerOlapProtein,
			@SynRunInterval,
			@SynRepeatCount,
			@SynStateID,
			'Synopsis',
			'na',
			@SynOutputForm,
			@SynComment
		)

		-- return Report ID of newly created Synopsis Report
		--
		set @SynReportID = IDENT_CURRENT('T_Peptide_Synopsis_Reports')

		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @SynReportName + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end -- add mode


	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Peptide_Synopsis_Reports
		SET 
			[Description] = @SynDescription, 
			Dataset_Match_List = @SynDSMatchList, 
			Instrument_Match_List = @SynInsMatchList, 
			Param_File_Match_List = @SynParmFileMatchList,
			Fasta_File_Match_List = @SynFastaFileMatchList,
			Experiment_Match_List = '%',
			Comparison_Job_Number = @SynCompJobNum,
			Scrolling_Dataset_Dates = @SynScrollDSDates,
			Scrolling_Dataset_Time_Frame = @SynScrollDSTimeFrame,
			Dataset_Start_Date = @SynDSStartDate,
			Dataset_End_Date = @SynDSEndDate,
			Scrolling_Job_Dates= @SynScrollJobDates,
			Scrolling_Job_Time_Frame = @SynScrollJobTimeFrame,
			Job_Start_Date = @SynJobStartDate,
			Job_End_Date = @SynJobEndDate,
			Use_Synopsis_Files = @SynUseSynFiles,
			Report_Sorting = @SynReportSort,
			Primary_Filter_ID = @SynPrimaryFilterID,
			Secondary_Filter_ID = @SynSecondaryFilterID,
			Required_Primary_Peptides_per_Protein = @SynReqPriPepPerProtein,
			Required_PrimaryPlusSecondary_Peptides_per_Protein = @SynReqPriSecPepPerProtein,
			Required_Overlap_Peptides_per_Overlap_Protein = @SynReqOlapPepPerOlapProtein,
			Run_Interval = @SynRunInterval,
			Repeat_Count = @SynRepeatCount,
			State = @SynStateID,
			Task_Type = 'Synopsis',
			Database_Name = 'na',
			Output_Form = @SynOutputForm,
			Comment = @SynComment
		WHERE ([Report_ID] = @SynReportID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @SynReportName + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- update mode


	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateSynopsisReport] TO [DMS_User]
GO
GRANT EXECUTE ON [dbo].[AddUpdateSynopsisReport] TO [DMS2_SP_User]
GO
