/****** Object:  StoredProcedure [dbo].[SetRunComplete] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE Procedure [dbo].[SetRunComplete]
/****************************************************
**
**		Desc: 
**		Adds new dataset entry to DMS database
**		either from scheduled run or as all original
**
**		Return values: 0: success, otherwise, error code
** 
**		Parameters:
**
**	Auth: 	grk
**	Date: 	01/29/2003
**			09/20/2003 - grk - Fixed problem with revised request table reference
**			09/02/2011 mem - Now calling PostUsageLogEntry
**    
*****************************************************/
(
	@requestID int,
	@datasetNum varchar(128) = '',
	@experimentNum varchar(64) = '',
	@operPRN varchar(64) = '',
	@instrumentName varchar(64) = '',
	@msType varchar(20) = '',
	@wellNum varchar(64) = '',
	@secSep varchar(64) = '',
	@comment varchar(512) = '',
	@rating varchar(32) = '',
	@completionCode varchar(12) = 'Success', -- or 'Failure'
	@message varchar(512) output
)
As

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	---------------------------------------------------
	-- Get parameter values from scheduled run
	-- if ID for one is supplied
	---------------------------------------------------
	declare @tmp_datasetNum varchar(128)
	declare @tmp_Experiment varchar(128)
	declare @tmp_operPRN varchar(64)
	declare @tmp_instrumentName varchar(64)
	declare @tmp_msType varchar(20)
	declare @tmp_wellNum varchar(64)
	declare @tmp_secSep varchar(64)
	declare @tmp_comment varchar(512)
	declare @tmp_rating varchar(32)

	set @tmp_datasetNum = ''
	set @tmp_Experiment = ''
	set @tmp_operPRN = ''
	set @tmp_instrumentName = ''
	set @tmp_msType = ''
	set @tmp_wellNum = ''
	set @tmp_secSep = ''
	set @tmp_comment = ''
	set @tmp_rating = ''

	if @requestID <> 0
	begin
		SELECT     
			@tmp_datasetNum = [Name], 
			@tmp_Experiment = Experiment,
			@tmp_instrumentName = Instrument, 
			@tmp_comment = Comment, 
			@tmp_msType = Type, 
			@tmp_operPRN = PRN
		FROM         V_Scheduled_Run_Detail_Report
		WHERE     (Request = @requestID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 
		begin
			set @message = 'Error trying to get run: ' + cast(@requestID as varchar(12))
			goto Done
		end
		if  @myRowCount <> 1
		begin
			set @myError = 51002
			set @message = 'Run could not be found: ' + cast(@requestID as varchar(12))
			goto Done
		end
	end

	---------------------------------------------------
	-- if an input parameter is blank, default it to
	-- value from scheduled run (if any)
	---------------------------------------------------

	if @datasetNum = '' set @datasetNum = @tmp_datasetNum 
	if @experimentNum = '' set @experimentNum = @tmp_Experiment
	if @operPRN = '' set @operPRN = @tmp_operPRN
	if @instrumentName = '' set @instrumentName = @tmp_instrumentName
	if @msType = '' set @msType = @tmp_msType
	if @wellNum = '' set @wellNum = @tmp_wellNum
	if @secSep = '' set @secSep = @tmp_secSep
	if @comment = '' set @comment = @tmp_comment
	if @rating = '' set @rating = 'Unknown'

	---------------------------------------------------
	-- Create dataset entry
	---------------------------------------------------
	
	declare @result int
	exec @result = AddUpdateDataset
						@datasetNum,
						@experimentNum,
						@operPRN,
						@instrumentName,
						@msType,
						@wellNum,
						@secSep,
						@comment,
						@rating,
						@requestID,
						'add',
						@message output
	--
	if @result <> 0
	begin
		set @myError = 51012
		goto Done
	end

	---------------------------------------------------
	-- Exit point
	---------------------------------------------------
Done:

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = 'Dataset: ' + @datasetNum
	Exec PostUsageLogEntry 'SetRunComplete', @UsageMessage

	return @myError


GO

GRANT VIEW DEFINITION ON [dbo].[SetRunComplete] TO [Limited_Table_Write] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetRunComplete] TO [PNL\D3M578] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[SetRunComplete] TO [PNL\D3M580] AS [dbo]
GO

