/****** Object:  StoredProcedure [dbo].[AddRequestedRuns] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.AddRequestedRuns
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
**
*****************************************************/
	@experimentGroupID varchar(12) = '',
	@experimentList varchar(3500) = '',
	@requestNamePrefix varchar(32) = '',
	@operPRN varchar(64),
	@instrumentName varchar(64),
	@workPackage varchar(50),
	@msType varchar(20),
		-- optional arguments
	@instrumentSettings varchar(512) = "na",
	@specialInstructions varchar(512) = "na",
	@wellplateNum varchar(64) = "na",
	@wellNum varchar(24) = "na",
	@eusProposalID varchar(10) = 'na',
	@eusUsageType varchar(50),
	@eusUsersList varchar(1024) = '',
	@internalStandard varchar(50) = "na",
	@comment varchar(244) = "na",
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if @experimentGroupID <> '' AND @experimentList <> ''
	begin
		set @myError = 51130
		set @message = 'Experiment Group ID and Experiment List cannot both be non-blank'
		RAISERROR (@message,10, 1)
	end
	--
	if @experimentGroupID = '' AND @experimentList = ''
	begin
		set @myError = 51131
		set @message = 'Experiment Group ID and Experiment List cannot both be blank'
		RAISERROR (@message,10, 1)
	end
	--
	if LEN(@operPRN) < 1
	begin
		set @myError = 51113
		RAISERROR ('Operator payroll number/HID was blank',
			10, 1)
	end
	--
	if LEN(@instrumentName) < 1
	begin
		set @myError = 51114
		RAISERROR ('Instrument name was blank',
			10, 1)
	end
	--
	if LEN(@msType) < 1
	begin
		set @myError = 51115
		RAISERROR ('Dataset type was blank',
			10, 1)
	end
	--
	if LEN(@workPackage) < 1
	begin
		set @myError = 51115
		RAISERROR ('Work package was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError
		
	---------------------------------------------------
	-- If experiment group is given, generate experiment
	-- list from it
	---------------------------------------------------
	
	if @experimentGroupID <> ''
	begin
		SELECT @experimentList = @experimentList + T_Experiments.Experiment_Num + ','
		FROM 
			T_Experiments INNER JOIN
			T_Experiment_Group_Members ON T_Experiments.Exp_ID = T_Experiment_Group_Members.Exp_ID LEFT OUTER JOIN
			T_Experiment_Groups ON T_Experiments.Exp_ID <> T_Experiment_Groups.Parent_Exp_ID AND 
			T_Experiment_Group_Members.Group_ID = T_Experiment_Groups.Group_ID
		WHERE     (T_Experiment_Groups.Group_ID = CONVERT(int, @experimentGroupID))	
	end
	
	select @experimentList

	---------------------------------------------------
	-- make sure experiment list is not too big
	---------------------------------------------------

	if LEN(@experimentList) >= 3500
	begin
		set @myError = 51115
		set @message = 'Experiment list is too long'
		RAISERROR (@message, 10, 1)
	end

	---------------------------------------------------
	-- set up to auto increment well number
	---------------------------------------------------
	declare @wellInt int
	set @wellInt = 0
	--
	if @wellNum <> 'na'
	begin
		set @wellInt = cast(@wellNum as int)	
	end

	---------------------------------------------------
	-- Step through experiment list and make 
	-- run request entry for each one
	---------------------------------------------------

	declare @reqName varchar(64)
	declare @request int
	
	declare @suffix varchar(64)
	set @suffix = ISNULL(@requestNamePrefix, '')
	if @suffix <> ''
	begin
		set @suffix = '_' + @suffix
	end

	declare @delim char(1)
	set @delim = ','

	declare @done int
	declare @count int

	declare @tPos int
	set @tPos = 1
	declare @tFld varchar(128)

	-- process list into datasets
	-- and make job for each one
	--
	set @count = 0
	set @done = 0

	while @done = 0 and @myError = 0
	begin
		set @count = @count + 1
		
		-- process the  next field from the ID list
		--
		set @tFld = ''
		execute @done = NextField @experimentList, @delim, @tPos output, @tFld output
		
		if @tFld <> ''
		begin
			set @message = ''
			set @reqName = @tFld + @suffix
			exec @myError = AddUpdateRequestedRun
								@reqName,
								@tFld,
								@operPRN,
								@instrumentName,
								@workPackage,
								@msType,
								@instrumentSettings,
								@specialInstructions,
								@wellplateNum,
								@wellNum,
								@internalStandard,
								@comment,
								@eusProposalID,
								@eusUsageType,
								@eusUsersList,
								'add',
								@request output,
								@message output
			set @message = '[' + @tFld + '] ' + @message 
			if @myError <> 0
				return @myError
		end

		-- bump well count
		if @wellNum <> 'na'
		begin
			set @wellInt = @wellInt + 1	
			set @wellNum = cast(@wellInt as varchar(12))
		end
	end
	
	set @message = 'Number of requests created:' + cast(@count as varchar(12))
/**/
	return 0

GO
GRANT EXECUTE ON [dbo].[AddRequestedRuns] TO [DMS_Experiment_Entry]
GO
GRANT EXECUTE ON [dbo].[AddRequestedRuns] TO [DMS_User]
GO
