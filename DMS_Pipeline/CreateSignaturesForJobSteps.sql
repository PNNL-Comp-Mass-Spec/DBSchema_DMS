/****** Object:  StoredProcedure [dbo].[CreateSignaturesForJobSteps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.CreateSignaturesForJobSteps
/****************************************************
**
**	Desc: 
**
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**			01/30/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/720)
**			02/08/2009 mem - Added parameter @DebugMode
**			12/21/2009 mem - Added warning message if @DebugMode is non-zero and a signature cannot be computed for a step tool
**			03/22/2011 mem - Now using varchar(1024) when extracting the @Value from the XML parameters
**    
*****************************************************/
(
	@job int,
	@pXML xml,
	@datasetID int,
	@message varchar(512) output,
	@DebugMode tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- get job parameters into table format
	---------------------------------------------------
	--
	declare @Job_Parameters table (
		[Job] int,
		[Step_Number] int,
		[Section] varchar(64),
		[Name] varchar(128),
		[Value] varchar(1024)		-- Warning: if this field is larger than varchar(2000) then the creation of @s via string concatenation later in this SP will result in corrupted strings (MEM 01/13/2009)
	)
	--
	INSERT INTO @Job_Parameters
		(Job, Step_Number, [Section], [Name], Value)
	SELECT 
		xmlNode.value('@Job', 'varchar(64)') as Job,
		xmlNode.value('@Step_Number', 'varchar(64)') as Step_Number,
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
		set @message = 'Error getting job parameters'
		goto Done
	end
	
	if @DebugMode <> 0
		SELECT '@Job_Parameters' as [Table], *
		FROM @Job_Parameters

	---------------------------------------------------
	-- calculate signature and shared resuts folder name
	-- for job steps that have tools that require signature
	---------------------------------------------------
	--
	declare @signature int
	declare @Shared int
	declare @stepTool varchar(64)
	declare @curStep int
	--
	declare @prevStep int
	set @prevStep = 0
	--
	declare @done tinyint
	set @done = 0
	--
	while @done = 0
	begin --<a>
		-- get next step that requires signature 
		--
		set @curStep = 0
		--
		select top 1
			@curStep = Step_Number,
			@stepTool = Step_Tool,
			@Shared = Shared_Result_Version
		from #Job_Steps
		where 
			Job = @job and
			(Shared_Result_Version + Filter_Version) > 0 and
			Step_Number > @prevStep
		order by Step_Number
		
		-- if none found, done, otherwise process
		if @curStep = 0
			set @done = 1
		else
		begin --<b>
			set @prevStep = @curStep			
			---------------------------------------------------
			-- get signature for step
			-- rollup parameter names and values for sections
			-- associated with step's step tool into single string
			--
			-- to allow for more than one instance of a tool
			-- in a single script, look at parameters in sections 
			-- that either are not locked to any setp 
			-- (step number is null) or are locked to the current step
			--
			set @signature = 0
			--
			declare @s varchar(max)
			set @s = ''
			--
			SELECT   
			  @s = @s + [Name] + '=' + [Value] + ';'
			FROM @Job_Parameters
			WHERE [Section] in (
				SELECT xmlNode.value('@name', 'varchar(128)') SectionName
				FROM   T_Step_Tools CROSS APPLY Parameter_Template.nodes('//section') AS R(xmlNode)
				WHERE  [Name] = @stepTool
				AND ((Step_Number is null) OR (Step_Number = @curStep))
			)
			ORDER BY [Section], [Name]
			-- 
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error forming global signature string'
				goto Done
			end
			
			if @myRowCount > 0
			begin --<c>
				---------------------------------------------------
				-- get signature for rolled-up parameter string
				--
				exec @signature = GetSignature @s           
				--
				if @signature = 0
				begin
					set @message = 'Error calculating signature'
					goto Done
				end
				
				if @DebugMode <> 0
					Select @signature as Signature, @S as Settings
					
			end --<c>
			else
			Begin
				if @DebugMode <> 0
					SELECT 'Warning: Cannot compute signature since could not find a section named "' + @stepTool + '" in column Parameter_Template in table T_Step_Tools' as Message
			End
			
			---------------------------------------------------
			-- calculate shared folder name
			--
			declare @SharedResultsFolderName varchar(256)
			set @SharedResultsFolderName = @stepTool + '_' + convert(varchar(12), @Shared) + '_' + convert(varchar(12), @Signature) + '_' + convert(varchar(12), @DatasetID)

			---------------------------------------------------
			-- set signature (and shared results folder name for shared results steps)
			--
			update #Job_Steps
			set 
				Signature = @signature,
				Output_Folder_Name = CASE WHEN @Shared > 0 THEN @SharedResultsFolderName ELSE Output_Folder_Name END
			where 
				Job = @job and
				Step_Number = @curStep

		end --<b>
	end --<a>

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CreateSignaturesForJobSteps] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreateSignaturesForJobSteps] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreateSignaturesForJobSteps] TO [PNL\D3M580] AS [dbo]
GO
