/****** Object:  StoredProcedure [dbo].[AddUpdateJobParameterXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateJobParameterXML
/****************************************************
**
**  Desc:   Adds or updates an entry in the XML parameters in @pXML
**			Alternatively, use @DeleteParam=1 to delete the given parameter
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	mem
**  Date:	09/24/2012 mem - Ported from DMS_Pipeline DB
**    
*****************************************************/
(
	@pXML XML output,				-- XML to update (Input/output parameter)
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
	
	---------------------------------------------------
	-- get job parameters into table format
	---------------------------------------------------
	--
	declare @Job_Parameters table (
		[Section] varchar(64),
		[Name] varchar(128),
		[Value] varchar(4000)
	)
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)

	---------------------------------------------------
	-- Populate @Job_Parameters with the parameters
	---------------------------------------------------
	--
		INSERT INTO @Job_Parameters
			([Section], [Name], Value)
		SELECT 
			xmlNode.value('@Section', 'varchar(64)') as [Section],
			xmlNode.value('@Name', 'varchar(64)') as [Name],
			xmlNode.value('@Value', 'varchar(1024)') as [Value]
		FROM
			@pXML.nodes('//Param') AS R(xmlNode)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error parsing job parameters'
			goto Done
		end
	
	If @infoOnly <> 0
	Begin
		SELECT 'Before update' AS Note, *
		FROM @Job_Parameters
		ORDER BY [Section]
	End

	If @DeleteParam = 0
	Begin
		---------------------------------------------------
		-- Add/update the specified parameter
		-- First try an update
		---------------------------------------------------
		--
		UPDATE @Job_Parameters
		SET VALUE = @Value
		WHERE [Section] = @Section AND
		      [Name] = @ParamName
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myRowCount = 0
		Begin
			-- Match not found; Insert a new parameter
			INSERT INTO @Job_Parameters([Section], [Name], [Value])
			VALUES (@Section, @ParamName, @Value)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		End
	End
	Else
	Begin
		---------------------------------------------------
		-- Delete the specified parameter
		---------------------------------------------------
		--
		DELETE FROM @Job_Parameters
		WHERE [Section] = @Section AND
		      [Name] = @ParamName
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End

	If @infoOnly <> 0
	Begin
		---------------------------------------------------
		-- Preview the parameters
		---------------------------------------------------
		--
		SELECT 'After update' AS Note, *
		FROM @Job_Parameters
		ORDER BY [Section]
	End
	Else
	Begin
		SELECT @pXML = ( SELECT [Section],
		                        [Name],
		                        [Value]
		                 FROM @Job_Parameters Param
		                 ORDER BY [Section]
		                 FOR XML AUTO )
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
