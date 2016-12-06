/****** Object:  StoredProcedure [dbo].[AddUpdateJobParameterTempTable] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateJobParameterTempTable
/****************************************************
**
**  Desc:   Adds or updates an entry in the XML parameters for a given job
**			Alternatively, use @DeleteParam=1 to delete the given parameter
**
**			This procedure is nearly identical to AddUpdateJobParameter;
**			However, it operates on #Job_Parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	mem
**  Date:	03/22/2011 mem - Initial Version
**			01/19/2012 mem - Now using AddUpdateJobParameterXML
**    
*****************************************************/
(
	@Job int,
	@Section varchar(128),			-- Example: JobParameters
	@ParamName varchar(128),		-- Example: SourceJob
	@Value varchar(1024),			-- value for parameter @ParamName in section @Section
	@DeleteParam tinyint = 0,		-- When 0, then adds/updates the given parameter; when 1 then deletes the parameter
	@message varchar(512)='' output,
	@infoOnly tinyint = 0
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @pXML xml
	Declare @ExistingParamsFound tinyint = 0

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)

	---------------------------------------------------
	-- Lookup the current parameters stored in #Job_Parameters for this job
	---------------------------------------------------
	--
	SELECT @pXML = Parameters
	FROM #Job_Parameters 
	WHERE Job = @Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount > 0
		Set @ExistingParamsFound = 1
	Else
	Begin
		Set @message = 'Warning: job not found in #Job_Parameters'
		If @infoOnly <> 0
			print @message
		Set @pXML = ''
	End

	---------------------------------------------------
	-- Call AddUpdateJobParameterXML to perform the work
	---------------------------------------------------
	--
	exec AddUpdateJobParameterXML @pXML output, @Section, @ParamName, @Value, @DeleteParam, @message output, @infoOnly
	

	If @infoOnly = 0
	Begin
		---------------------------------------------------
		-- Update #Job_Parameters
		-- Note: Ordering by Section name but not by parameter name
		---------------------------------------------------
		--
		If @ExistingParamsFound = 1
		Begin
			UPDATE #Job_Parameters
			SET Parameters = @pXML
			WHERE Job = @Job
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		End
		Else
		Begin
			INSERT INTO #Job_Parameters( Job, Parameters )
			SELECT @job, @pXML
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		End

		if @myError <> 0
		begin
			set @message = 'Error storing parameters in #Job_Parameters for job ' + Convert(varchar(12), @Job)
		end
	End
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateJobParameterTempTable] TO [DDL_Viewer] AS [dbo]
GO
