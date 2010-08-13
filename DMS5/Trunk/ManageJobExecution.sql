/****** Object:  StoredProcedure [dbo].[ManageJobExecution] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ManageJobExecution
/****************************************************
**
**	Desc:
**   Updates parameters to new values for jobs in list
**   Meant to be called by job control dashboard program
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**			07/09/2009 grk - Initial release
**			09/16/2009 mem - Updated to pass table #TAJ to UpdateAnalysisJobsWork
**						   - Updated to resolve job state defined in the XML with T_Analysis_State_Name
**			05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**
*****************************************************/
(
    @parameters text = '',
    @result varchar(4096) output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	declare @JobCount int
	set @JobCount = 0
	
	set @result = ''

	---------------------------------------------------
	---------------------------------------------------
	--  Extract parameters from XML input
	---------------------------------------------------
	---------------------------------------------------

	declare @paramXML xml
	set @paramXML = @parameters

	---------------------------------------------------
	--  get action and value parameters
	---------------------------------------------------
	declare @action varchar(64)
	set @action = ''

	SELECT 
	@action = xmlNode.value('.', 'nvarchar(64)')
	FROM   @paramXML.nodes('//action') AS R(xmlNode)
	
	declare @value varchar(512)
	set @value = ''

	SELECT 
	@value = xmlNode.value('.', 'nvarchar(512)')
	FROM   @paramXML.nodes('//value') AS R(xmlNode)
	
 	---------------------------------------------------
	-- Create temporary table to hold list of jobs
	-- and populate it from job list  
	---------------------------------------------------
 	CREATE TABLE #TAJ (
		Job int
	)

	INSERT INTO #TAJ
	(Job)
	SELECT 
		xmlNode.value('.', 'nvarchar(12)') Job
	FROM   @paramXML.nodes('//job') AS R(xmlNode)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @result = 'Error populating temporary job table'
		return 51007
	end

	Set @JobCount = @myRowCount
	

	---------------------------------------------------
	---------------------------------------------------
	-- set up default arguments 
	-- for calling UpdateAnalysisJobs
	---------------------------------------------------
	---------------------------------------------------

	declare @NoChangeText varchar(32)
	set @NoChangeText = '[no change]'

	declare
		@state varchar(32),
		@priority varchar(12),
		@comment varchar(512),
		@findText varchar(255),
		@replaceText varchar(255),
		@assignedProcessor varchar(64),
		@associatedProcessorGroup varchar(64),
		@propagationMode varchar(24),
		@parmFileName varchar(255),
		@settingsFileName varchar(255),
		@organismName varchar(64),
		@protCollNameList varchar(4000),
		@protCollOptionsList varchar(256),
		@mode varchar(12),
		@message varchar(512),
		@callingUser varchar(128)
	
	set @state = @NoChangeText 
	set @priority = @NoChangeText 
	set @comment = @NoChangeText 
	set @findText = @NoChangeText 
	set @replaceText = @NoChangeText 
	set @assignedProcessor = @NoChangeText 
	set @associatedProcessorGroup = @NoChangeText
	set @propagationMode = @NoChangeText 
	set @parmFileName = @NoChangeText 
	set @settingsFileName = @NoChangeText 
	set @organismName = @NoChangeText 
	set @protCollNameList = @NoChangeText 
	set @protCollOptionsList = @NoChangeText 
	set @mode = 'update' 
	set @message = '' 
	set @callingUser = ''

	---------------------------------------------------
	---------------------------------------------------
	-- change affected calling arguments based on 
	-- command action and value
	---------------------------------------------------
	---------------------------------------------------

	if(@action = 'state')
	begin
		If @value = 'Hold'
			-- Holding
			SELECT @state = AJS_name
			FROM T_Analysis_State_Name
			WHERE (AJS_stateID = 8)
			
		If @value = 'Release'
		Begin
			-- Release (unhold)
			SELECT @state = AJS_name
			FROM T_Analysis_State_Name
			WHERE (AJS_stateID = 1)
		End
		
		If @value = 'Reset'
		Begin
			-- Reset
			-- For a reset, we still just set the DMS state to "New"
			-- If the job was failed in the broker, it will get reset
			-- If it was on hold, then it will resume
			SELECT @state = AJS_name
			FROM T_Analysis_State_Name
			WHERE (AJS_stateID = 1)
		End
	end
	
	if(@action = 'priority')
	begin
		set @priority = @value
	end
	
	if(@action = 'group')
	begin
		set @associatedProcessorGroup = @value
	end

	---------------------------------------------------
	---------------------------------------------------
	-- Call UpdateAnalysisJobsWork function
	-- It uses #TAJ to determine which jobs to update
	---------------------------------------------------
	---------------------------------------------------

	exec @myError = UpdateAnalysisJobsWork
		@state,
		@priority,
		@comment,
		@findText,
		@replaceText,
		@assignedProcessor,
		@associatedProcessorGroup,
		@propagationMode,
		@parmFileName,
		@settingsFileName,
		@organismName,
		@protCollNameList,
		@protCollOptionsList,
		@mode,
		@message output,
		@callingUser,
		@DisableRaiseError=1

 	---------------------------------------------------
	-- Report success or error
	---------------------------------------------------

	if @myError <> 0
	Begin
			If IsNull(@message, '') <> ''
				Set @result = 'Error: ' + @message + '; '
			Else
				Set @result = 'Unknown error calling UpdateAnalysisJobsWork; '
	End
	Else	
	begin
		Set @result = @message
		
		If IsNull(@result, '') = ''
		Begin
			Set @result = 'Empty message returned by UpdateAnalysisJobsWork.  '
			set @result = @result + 'The action was "' + @action + '".  '
			set @result = @result + 'The value was "' + @value + '".  '
			set @result = @result + 'There were ' + convert(varchar(12), @JobCount) + ' jobs in the list: '
		End
	end
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ManageJobExecution] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ManageJobExecution] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ManageJobExecution] TO [RBAC-Web_Analysis] AS [dbo]
GO
