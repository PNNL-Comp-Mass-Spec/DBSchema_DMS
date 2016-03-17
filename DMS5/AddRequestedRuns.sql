/****** Object:  StoredProcedure [dbo].[AddRequestedRuns] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddRequestedRuns
/****************************************************
**
**	Desc: 
**  Adds a group of entries to the requested dataset table
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 7/22/2005
**		7/27/2005 grk -- modified prefix
**      10/12/2005 -- grk Added stuff for new work package and proposal fields.
**      2/23/2006  -- grk Added stuff for EUS proposal and user tracking.
**      3/24/2006  -- grk Added stuff for auto incrementing well numbers.
**      6/23/2006  -- grk Removed instrument name from generated request name
**      10/12/2006  -- grk Fixed trailing suffix in name (Ticket #248)
**      11/09/2006  -- grk Fixed error message handling (Ticket #318)
**      07/17/2007 grk - Increased size of comment field (Ticket #500)
**      09/06/2007 grk - Removed @specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**		04/25/2008 grk - Added secondary separation field (Ticket #658)
**		03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**		07/27/2009 grk - removed autonumber for well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**		03/02/2010 grk - added status field to requested run
**		08/27/2010 mem - Now referring to @instrumentName as an instrument group
**		09/29/2011 grk - fixed limited size of variable holding delimited list of experiments from group
**		12/14/2011 mem - Added parameter @callingUser, which is passed to AddUpdateRequestedRun
**		02/20/2012 mem - Now using a temporary table to track the experiment names for which requested runs need to be created
**		02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**		06/13/2013 mem - Added @VialingConc and @VialingVol
					   - Now validating @WorkPackageNumber against T_Charge_Code
**		06/18/2014 mem - Now passing default to udfParseDelimitedList
**		02/23/2016 mem - Add set XACT_ABORT on
**
*****************************************************/
(
	@experimentGroupID varchar(12) = '',	-- Specify ExperimentGroupID or ExperimentList, but not both
	@experimentList varchar(3500) = '',
	@requestNamePrefix varchar(32) = '',	-- Actually used as the request name Suffix
	@operPRN varchar(64),
	@instrumentName varchar(64),			-- Instrument group; could also contain "(lookup)"
	@workPackage varchar(50),				-- Work Package; could also contain "(lookup)"
	@msType varchar(20),
		-- optional arguments
	@instrumentSettings varchar(512) = "na",
	@eusProposalID varchar(10) = 'na',
	@eusUsageType varchar(50),
	@eusUsersList varchar(1024) = '',
	@internalStandard varchar(50) = "na",
	@comment varchar(1024) = "na",
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@secSep varchar(64) = 'LC-Formic_100min',		-- Separation group
	@MRMAttachment varchar(128),
	@VialingConc varchar(32) = Null,
	@VialingVol varchar(32) = Null,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	BEGIN TRY
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @experimentGroupID = IsNull(@experimentGroupID, '')
	Set @experimentList = IsNull(@experimentList, '')	
	
	if @experimentGroupID <> '' AND @experimentList <> ''
	begin
		set @myError = 51130
		set @message = 'Experiment Group ID and Experiment List cannot both be non-blank'
		RAISERROR (@message, 11, 20)
	end
	--
	if @experimentGroupID = '' AND @experimentList = ''
	begin
		set @myError = 51131
		set @message = 'Experiment Group ID and Experiment List cannot both be blank'
		RAISERROR (@message,11, 21)
	end
	--
	If Len(@experimentGroupID) > 0
	Begin
		if IsNumeric(@experimentGroupID) = 0
		Begin
			set @myError = 51132
			set @message = 'Experiment Group ID must be a number: ' + @experimentGroupID
			RAISERROR (@message,11, 21)
		End
	End
	--
	if LEN(@operPRN) < 1
	begin
		set @myError = 51113
		RAISERROR ('Operator payroll number/HID was blank', 11, 22)
	end
	--
	if LEN(@instrumentName) < 1
	begin
		set @myError = 51114
		RAISERROR ('Instrument group was blank', 11, 23)
	end
	--
	if LEN(@msType) < 1
	begin
		set @myError = 51115
		RAISERROR ('Dataset type was blank', 11, 24)
	end
	--
	if LEN(@workPackage) < 1
	begin
		set @myError = 51115
		RAISERROR ('Work package was blank', 11, 25)
	end
	--
	if @myError <> 0
		return @myError
		
	---------------------------------------------------
	-- Validate the work package
	-- This validation also occurs in AddUpdateRequestedRun but we want to validate it now before we enter the while loop
	---------------------------------------------------

	Declare @allowNoneWP tinyint = 0
	
	If @workPackage <> '(lookup)'
	Begin
		exec @myError = ValidateWP
							@workPackage,
							@allowNoneWP,
							@msg output

		If @myError <> 0
			RAISERROR ('ValidateWP: %s', 11, 1, @msg)
	End

	---------------------------------------------------
	-- Populate a temorary table with the experiments to process
	---------------------------------------------------
	
	Declare @tblExperimentsToProcess Table
	(
		EntryID int identity(1,1),
		Experiment varchar(256)
	)
	
	
	If @experimentGroupID <> ''
	Begin
		---------------------------------------------------
		-- Determine experiment names using experiment group ID
		---------------------------------------------------
		
		INSERT INTO @tblExperimentsToProcess (Experiment)
		SELECT T_Experiments.Experiment_Num
		FROM T_Experiments
		     INNER JOIN T_Experiment_Group_Members
		       ON T_Experiments.Exp_ID = T_Experiment_Group_Members.Exp_ID
		     LEFT OUTER JOIN T_Experiment_Groups
		       ON T_Experiments.Exp_ID <> T_Experiment_Groups.Parent_Exp_ID 
		          AND
		          T_Experiment_Group_Members.Group_ID = T_Experiment_Groups.Group_ID
		WHERE (T_Experiment_Groups.Group_ID = CONVERT(int, @experimentGroupID))
		ORDER BY T_Experiments.Experiment_Num
	End
	Else
	Begin
		---------------------------------------------------
		-- Parse @experimentList to determine experiment names
		---------------------------------------------------

		INSERT INTO @tblExperimentsToProcess (Experiment)
		SELECT Value
		FROM dbo.udfParseDelimitedList(@experimentList, default)
		WHERE Len(Value) > 0
		ORDER BY Value
	End
		
	---------------------------------------------------
	-- set up wellplate stuff to force lookup 
	-- from experiments
	---------------------------------------------------
	--
	declare @wellplateNum varchar(64)
	declare @wellNum varchar(24)
	set @wellplateNum  = '(lookup)'
	set @wellNum  = '(lookup)'

	---------------------------------------------------
	-- Step through experiments in @tblExperimentsToProcess and make 
	-- run request entry for each one
	---------------------------------------------------

	declare @reqName varchar(64)
	declare @request int
	Declare @ExperimentName varchar(64)
	
	declare @suffix varchar(64)
	set @suffix = ISNULL(@requestNamePrefix, '')
	if @suffix <> ''
	begin
		set @suffix = '_' + @suffix
	end

	declare @done int = 0
	declare @count int = 0
	declare @EntryID int = 0
	
	while @done = 0 and @myError = 0
	begin
		
		SELECT TOP 1 @EntryID = EntryID, 
					 @ExperimentName = Experiment
		FROM @tblExperimentsToProcess
		WHERE EntryID > @EntryID
		ORDER BY EntryID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount


		If @myRowCount = 0
			Set @Done = 1
		Else
		Begin
			set @message = ''
			set @reqName = @ExperimentName + @suffix
			EXEC @myError = dbo.AddUpdateRequestedRun 
									@reqName = @reqName,
									@experimentNum = @ExperimentName,
									@operPRN = @operPRN,
									@instrumentName = @instrumentName,
									@workPackage = @workPackage,
									@msType = @msType,
									@instrumentSettings = @instrumentSettings,
									@wellplateNum = @wellplateNum,
									@wellNum = @wellNum,
									@internalStandard = @internalStandard,
									@comment = @comment,
									@eusProposalID = @eusProposalID,
									@eusUsageType = @eusUsageType,
									@eusUsersList = @eusUsersList,
									@mode = 'add',
									@request = @request output,
									@message = @message output,
									@secSep = @secSep,
									@MRMAttachment = @MRMAttachment,
									@status = 'Active',
									@callingUser = @callingUser,
									@VialingConc = @VialingConc,
									@VialingVol = @VialingVol
			--
			set @message = '[' + @ExperimentName + '] ' + @message 
			
			if @myError <> 0
				RAISERROR (@message, 11, 1)

			set @count = @count + 1
			
		end
	end
	
	set @message = 'Number of requests created:' + cast(@count as varchar(12))

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
	END CATCH
	return @myError


GO
GRANT EXECUTE ON [dbo].[AddRequestedRuns] TO [DMS_Experiment_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddRequestedRuns] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddRequestedRuns] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddRequestedRuns] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddRequestedRuns] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddRequestedRuns] TO [PNL\D3M580] AS [dbo]
GO
