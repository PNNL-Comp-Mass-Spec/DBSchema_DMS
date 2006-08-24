/****** Object:  StoredProcedure [dbo].[AddUpdateQRollupReport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create     Procedure AddUpdateQRollupReport
/****************************************************
**
**	Desc: Adds new or updates existing QRollup report requests in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@QRollReportName  name for the new QRollup Report
**	
**
**		Auth: jds
**		Date: 1/7/2005
**    
*****************************************************/
(
	@QRollReportID varchar(32) output, 
	@QRollReportName varchar(32), 
	@QRollDescription varchar(255), 
	@QRollDSMatchList varchar(255),
	@QRollExperimentMatchList varchar(255),
	@QRollCompJobNum varchar(32),
	@QRollServerName varchar(50),
	@QRollDatabaseName varchar(50),
	@QRollReportSort int,
	@QRollPrimaryFilterID int,
	@QRollSecondaryFilterID int,
	@QRollReqPriPepPerProtein int,
	@QRollReqPriSecPepPerProtein int,
	@QRollReqOlapPepPerOlapProtein int,
	@QRollRunInterval int,
	@QRollRepeatCount int,
	@QRollStateDescription varchar(255),
	@QRollOutputForm varchar(64),
	@QRollComment varchar(255),
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
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if LEN(@QRollReportName) < 1
	begin
		set @myError = 51000
		set @message = 'QRollup Report Name was blank'
		RAISERROR (@message, 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	if LEN(@QRollDescription) < 1
	begin
		set @myError = 51010
		set @message = 'QRollup Report Description was blank'
		RAISERROR (@message, 10, 1)
	end
	--
	if @myError <> 0
		return @myError


	---------------------------------------------------
	-- Validate Match List input fields
	-- If blank, set to %
	---------------------------------------------------
	if LEN(@QRollExperimentMatchList) < 1
	begin
		set @QRollExperimentMatchList = '%'
	end

	if LEN(@QRollDSMatchList) < 1
	begin
		set @QRollDSMatchList = '%'
	end
	
	---------------------------------------------------
	-- Validate Job Number
	-- If not found, raise error
	---------------------------------------------------
	declare @tmpCount int
	declare @tmpStr nvarchar(500)
	set @tmpStr = 'Exec ' + @QRollServerName + '.PRISM_IFC.dbo.WebQRRetrievePeptidesMultiQID ''' + @QRollDatabaseName + ''', ''' + @QRollCompJobNum + ''', 0, '''', 1, '''''
	exec(@tmpStr)
	set @tmpCount = @@RowCount
	if @tmpCount = 0
	begin
		set @myError = 51020
		set @message = 'The Comparison job entered is not valid'
		RAISERROR (@message, 10, 1)
	end
	--
	if @myError <> 0
		return @myError


	if (SELECT DISTINCT count(Filter_Set_ID) FROM V_Filter_Sets
	where filter_set_ID = @QRollPrimaryFilterID) = 0
	begin
		set @myError = 51030
		set @message = 'The Primary Filter ID is not valid.'
		RAISERROR (@message, 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	if (SELECT DISTINCT count(Filter_Set_ID) FROM V_Filter_Sets
	where filter_set_ID = @QRollSecondaryFilterID) = 0
	begin
		set @myError = 51040
		set @message = 'The Secondary Filter ID is not valid.'
		RAISERROR (@message, 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	if @QRollReqPriPepPerProtein < 1
	begin
		set @myError = 51050
		set @message = 'The Required Primary Peptide per Protein must be greater than 0.'
		RAISERROR (@message, 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	if (@QRollReqPriSecPepPerProtein < 1) OR (@QRollReqPriSecPepPerProtein > @QRollReqPriPepPerProtein)
	begin
		set @myError = 51060
		set @message = 'The Required Primary + Secondary Peptide per Protein must be greater than 0 and less than or equal to Required Primary Peptide per Protein.'
		RAISERROR (@message, 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	if @QRollReqOlapPepPerOlapProtein < 1 OR @QRollReqOlapPepPerOlapProtein > @QRollReqPriPepPerProtein
	begin
		set @myError = 51070
		set @message = 'The Required Overlap Peptide per Protein must be greater than 0 and less than or equal to Required Primary Peptide per Protein.'
		RAISERROR (@message, 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	if @QRollRunInterval < 1
	begin
		set @myError = 51080
		set @message = 'The Run Interval must be greater than 0.'
		RAISERROR (@message, 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	if @QRollRepeatCount < 0
	begin
		set @myError = 51090
		set @message = 'The Run Interval must be greater than or equal to 0.'
		RAISERROR (@message, 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- Now that all the data has passed, check the count to determine if
	-- too many records are trying to be compared.
	---------------------------------------------------
	set @tmpCount = 0
	declare @sql nvarchar(1024)
	set @sql = 'EXEC ' + @QRollServerName + '.PRISM_IFC.dbo.GetQRollupsForEntityFilter '''+ @QRollDatabaseName + ''', ''' + @QRollDSMatchList + ''', '''+ @QRollExperimentMatchList + ''', ' + @QRollCompJobNum --+ ' @datasetRecCount output'

	exec(@Sql)
	set @tmpCount = @@ROWCOUNT
	if @tmpCount > 50 
	  begin
		set @myError = 51100
		set @message = 'Your criteria returned: ' + convert(varchar(32), @tmpCount) + ' Record(s).  Please narrow your parameters and try again.'
		RAISERROR (@message, 10, 1)
	  end	  

	if @tmpCount < 2
	  begin
		set @myError = 51110
		set @message = 'Your criteria returned: ' + convert(varchar(32), @tmpCount) + ' Record(s).  Please expand your parameters and try again.'
		RAISERROR (@message, 10, 1)
	  end	  

	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- Is entry already in database?
	-- Not sure if we need to check for duplicate names
	---------------------------------------------------
/*	declare @reportName char(32)
	set @reportName = ''
	--
	execute @reportName = GetPepSynReportName @QRollReportID

	-- cannot create an entry that already exists
	-- Not sure if we will need this yet
	--
	if @reportID <> '' and @mode = 'add'
	begin
		set @msg = 'Cannot add: Peptide Synopsis Report "' + @pepQRollReportName + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end
*/
	---------------------------------------------------
	-- cannot update a non-existent entry
	---------------------------------------------------

	if @QRollReportID = 0 and @mode = 'update'
	begin
		set @myError = 51120
		set @message = 'Cannot update: QRollup Report "' + @QRollReportName + '" is not in database '
		RAISERROR (@message, 10, 1)
	end

	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- Get the State ID using the State Description
	---------------------------------------------------

	declare @QRollStateID int
	set @QRollStateID = 0
	--
	execute @QRollStateID = GetSynReportStateID @QRollStateDescription

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
			Server_Name,
			Output_Form,
			Comment
		) VALUES (
			@QRollReportName, 
			@QRollDescription, 
			@QRollDSMatchList, 
			'%', 
			'%',
			'%',
			@QRollExperimentMatchList,
			@QRollCompJobNum,
			0, 
			0,   
			null, 
			null, 
			0,    
			7,    
			null, 
			null, 
			0,    
			@QRollReportSort,
			@QRollPrimaryFilterID,
			@QRollSecondaryFilterID,
			@QRollReqPriPepPerProtein,
			@QRollReqPriSecPepPerProtein,
			@QRollReqOlapPepPerOlapProtein,
			@QRollRunInterval,
			@QRollRepeatCount,
			@QRollStateID,
			'QRollup',
			@QRollDatabaseName,
			@QRollServerName,
			@QRollOutputForm,
			@QRollComment
		)

		-- return Report ID of newly created Synopsis Report
		--
		set @QRollReportID = IDENT_CURRENT('T_Peptide_Synopsis_Reports')

		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Insert operation failed: "' + @QRollReportName + '"'
			RAISERROR (@message, 10, 1)
			return 51130
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
			[Description] = @QRollDescription, 
			Dataset_Match_List = @QRollDSMatchList,
			Instrument_Match_List = '%',
			Param_File_Match_List = '%',
			Fasta_File_Match_List = '%',
			Experiment_Match_List = @QRollExperimentMatchList,
			Comparison_Job_Number = @QRollCompJobNum,
			Scrolling_Dataset_Dates = 0,
			Scrolling_Dataset_Time_Frame = 365,
			Dataset_Start_Date = null, 
			Dataset_End_Date = null, 
			Scrolling_Job_Dates= 0, 
			Scrolling_Job_Time_Frame = 7, 
			Job_Start_Date = null, 
			Job_End_Date = null, 
			Use_Synopsis_Files = 0, 
			Report_Sorting = @QRollReportSort,
			Primary_Filter_ID = @QRollPrimaryFilterID,
			Secondary_Filter_ID = @QRollSecondaryFilterID,
			Required_Primary_Peptides_per_Protein = @QRollReqPriPepPerProtein,
			Required_PrimaryPlusSecondary_Peptides_per_Protein = @QRollReqPriSecPepPerProtein,
			Required_Overlap_Peptides_per_Overlap_Protein = @QRollReqOlapPepPerOlapProtein,
			Run_Interval = @QRollRunInterval,
			Repeat_Count = @QRollRepeatCount,
			State = @QRollStateID,
			Task_Type = 'QRollup',
			Database_Name = @QRollDatabaseName,
			Server_Name = @QRollServerName,
			Output_Form = @QRollOutputForm,
			Comment = @QRollComment
		WHERE ([Report_ID] = @QRollReportID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update operation failed: "' + @QRollReportName + '"'
			RAISERROR (@message, 10, 1)
			return 51140
		end
	end -- update mode


	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateQRollupReport] TO [DMS_Ops_Admin]
GO
