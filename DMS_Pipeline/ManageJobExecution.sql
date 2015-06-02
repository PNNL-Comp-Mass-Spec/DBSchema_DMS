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
**			05/08/2009 grk - Initial release
**			09/16/2009 mem - Now updating priority and processor group directly in this DB
**						   - Next, calls S_ManageJobExecution to update the primary DMS DB
**			05/25/2011 mem - No longer updating priority in T_Job_Steps
**			06/01/2015 mem - Removed support for option @action = 'group' because we have deprecated processor groups
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
	
	set @result = ''

	Declare @message varchar(512)
	
	Declare @priority varchar(12)
	Declare @NewPriority int
	
	Declare @associatedProcessorGroup varchar(64)

	Declare @JobUpdateCount int

	---------------------------------------------------
	---------------------------------------------------
	--  Extract parameters from XML input
	---------------------------------------------------
	---------------------------------------------------

	declare @paramXML xml
--	set @paramXML = '<root> <operation> <action>priority</action> <value>3</value> </operation> <jobs> <job>245023</job> <job>304378</job> <job>305663</job> <job>305680</job> <job>305689</job> <job>305696</job> <job>121917</job> <job>305677</job> <job>305692</job> <job>305701</job> </jobs> </root>'
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
 	CREATE TABLE #Tmp_JobList (
		Job int
	)

	INSERT INTO #Tmp_JobList
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

	---------------------------------------------------
	-- See if Priority or Processor Group needs to be updated
	---------------------------------------------------
	
	if(@action = 'priority')
	begin
		---------------------------------------------------
		-- Immediately update priorities for jobs
		---------------------------------------------------
		--

		set @priority = @value
		Set @NewPriority = Cast(@priority as int)

		Set @JobUpdateCount = 0

		UPDATE T_Jobs
		SET Priority = @NewPriority
		FROM T_Jobs J
		     INNER JOIN #Tmp_JobList JL
		       ON J.Job = JL.Job
		WHERE J.Priority <> @NewPriority
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		Set @JobUpdateCount = @myRowCount

		If @JobUpdateCount > 0
		Begin
			Set @message = 'Job priorities changed: updated ' + Convert(varchar(12), @JobUpdateCount) + ' job(s) in T_Jobs'
			execute PostLogEntry 'Normal', @message, 'ManageJobExecution'
			Set @message = ''
		End
	end

/*
	---------------------------------------------------
	-- Deprecated in May 2015: 
	--	
	if(@action = 'group')
	begin
		set @associatedProcessorGroup = @value

		If @associatedProcessorGroup = ''
		Begin
			---------------------------------------------------
			-- Immediately remove all processor group associations for jobs in #Tmp_JobList
			---------------------------------------------------
			--
			DELETE T_Local_Job_Processors
			FROM T_Local_Job_Processors JP
			     INNER JOIN #Tmp_JobList JL
			       ON JL.Job = JP.Job
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			Set @JobUpdateCount = @myRowCount
			
			If @JobUpdateCount > 0
			Begin
				Set @message = 'Updated T_Local_Job_Processors; UpdateCount=0; InsertCount=0; DeleteCount=' + Convert(varchar(12), @JobUpdateCount)
				execute PostLogEntry 'Normal', @message, 'ManageJobExecution'
				Set @message = ''
			End
		End
		Else
		Begin
			---------------------------------------------------
			-- Need to associate jobs with a specific processor group
			-- Given the complexity of the association, this needs to be done in DMS5,
			-- and this will happen when S_ManageJobExecution is called
			---------------------------------------------------
			Set @myError = 0
		End		            
	end
*/
	
	if(@action = 'state')
	begin
		If @value = 'Hold'
		Begin
			---------------------------------------------------
			-- Immediately hold the requested jobs
			---------------------------------------------------
			UPDATE T_Jobs
				SET State = 8							-- 8=Holding
			FROM T_Jobs J INNER JOIN #Tmp_JobList JL ON J.Job = JL.Job
			WHERE J.State <> 8
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
		End
	end


	---------------------------------------------------
	--  Call S_ManageJobExecution to update the primary DMS DB
	---------------------------------------------------
	
	exec @myError = S_ManageJobExecution @parameters, @result output

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ManageJobExecution] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ManageJobExecution] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ManageJobExecution] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ManageJobExecution] TO [RBAC-Web_Analysis] AS [dbo]
GO
