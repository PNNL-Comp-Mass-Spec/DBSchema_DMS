/****** Object:  StoredProcedure [dbo].[ValidateAnalysisJobParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure ValidateAnalysisJobParameters
/****************************************************
**
**	Desc: Validates analysis job parameters and returns internal
**        values converted from external values (input arguments)
**
**  Note: This procedure depends upon the caller having created
**  a temporary table for selected dataset information and
**  having populated it dataset names before calling
**  this procedure.
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**		Auth: grk
**		Date: 04/04/2006 grk - supersedes MakeAnalysisJobX
**		Date: 05/01/2006 grk - modified to conditionally call 
**                             Protein_Sequences.dbo.ValidateAnalysisJobProteinParameters
**		Date: 06/01/2006 grk - removed dataset archive state restriction 
**    
*****************************************************/
	@toolName varchar(64),
    @parmFileName varchar(255),
    @settingsFileName varchar(64),
    @organismDBName varchar(64) output,
    @organismName varchar(64),
	@protCollNameList varchar(512) output,
	@protCollOptionsList varchar(256) output,
    @ownerPRN varchar(32),
	@mode varchar(12), 
	@userID int output,
	@analysisToolID int output, 
	@organismID int output,
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @list varchar(1024)

	---------------------------------------------------
	-- Update temp table from existing datasets
	---------------------------------------------------
	
	UPDATE T
	SET
		T.Dataset_ID = T_Dataset.Dataset_ID, 
		T.IN_class = T_Instrument_Class.IN_class, 
		T.DS_state_ID = T_Dataset.DS_state_ID, 
		T.AS_state_ID = isnull(T_Dataset_Archive.AS_state_ID, 0)
	FROM
		#TD T INNER JOIN
		T_Dataset ON T.Dataset_Num = T_Dataset.Dataset_Num INNER JOIN
		T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
		T_Instrument_Class ON T_Instrument_Name.IN_class = T_Instrument_Class.IN_class LEFT OUTER JOIN
		T_Dataset_Archive ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary table'
		return 51007
	end

	---------------------------------------------------
	-- Verify that datasets in list all exist
	---------------------------------------------------
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN Dataset_Num
		ELSE ', ' + Dataset_Num
		END
	FROM
		#TD
	WHERE 
		Dataset_ID IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking dataset Existence'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following datasets from list were not in database:"' + @list + '"'
		return 51007
	end	

	---------------------------------------------------
	-- Verify dataset state of datasets
	-- if we are actually going to be making jobs
	---------------------------------------------------
	--
	if @mode = 'add'
	begin
		set @list = ''
		--
		SELECT 
			@list = @list + CASE 
			WHEN @list = '' THEN Dataset_Num
			ELSE ', ' + Dataset_Num
			END
		FROM
			#TD
		WHERE 
			(DS_state_ID <> 3)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error checking dataset Existence'
			return 51007
		end
		--
		if @list <> ''
		begin
			set @message = 'The following datasets were not in correct state:"' + @list + '"'
			return 51007
		end	
	end -- mode = 'add'
		
	---------------------------------------------------
	-- Resolve user ID for operator PRN
	---------------------------------------------------

	execute @userID = GetUserID @ownerPRN
	if @userID = 0
	begin
		set @message = 'Could not find entry in database for owner PRN "' + @ownerPRN + '"'
		return 51019
	end

	---------------------------------------------------
	-- get analysis tool ID from tool name 
	---------------------------------------------------
	--			
	execute @analysisToolID = GetAnalysisToolID @toolName
	if @analysisToolID = 0
	begin
		set @message = 'Could not find entry in database for analysis tool "' + @toolName + '"'
		return 53102
	end
				
	---------------------------------------------------
	-- get organism ID using organism name
	---------------------------------------------------
	--
	execute @organismID = GetOrganismID @organismName
	if @organismID = 0
	begin
		set @message = 'Could not find entry in database for organismName "' + @organismName + '"'
		return 53105
	end

	---------------------------------------------------
	-- Check tool/instrument compatibility for datasets
	---------------------------------------------------
	
	-- get list of allowed instrument classes for tool
	--
	declare @allowedInstClasses varchar(255)
	--
	SELECT  @allowedInstClasses = AJT_allowedInstClass
	FROM         T_Analysis_Tool
	WHERE     (AJT_toolName = @toolName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking for allowed instrument classes for tool'
		return 51007
	end

	-- find datasets are not compatible with tool 
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN Dataset_Num
		ELSE ', ' + Dataset_Num
		END
	FROM
		#TD 
	WHERE 
		IN_class NOT IN (SELECT * FROM MakeTableFromList(@allowedInstClasses))
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking dataset instrument classes against tool'
		return 51007
	end

	if @list <> ''
	begin
		set @message = 'The following datasets are not compatible with the analysis tool:"' + @list + '"'
		return 51007
	end

	---------------------------------------------------
	-- Validate param file for tool
	---------------------------------------------------

	declare @result int
	--
	set @result = 0
	--
	if @parmFileName <> 'na'
	begin
		SELECT @result = Param_File_ID
		FROM T_Param_Files
		WHERE Param_File_Name = @parmFileName
		--
		if @result = 0
		begin
			set @message = 'Parameter file could not be found' + ':"' + @parmFileName + '"'
			return 53109
		end
	end

	---------------------------------------------------
	-- Validate settings file for tool
	---------------------------------------------------
	--
	declare @fullPath varchar(255)
	declare @dirPath varchar(255)
	declare @orgDbReqd int
	--
	-- get tool parameters
	--
	set @dirPath = ''
	set @orgDbReqd = 0
	--
	SELECT 
		@dirPath = AJT_parmFileStoragePathLocal,
		@orgDbReqd = AJT_orgDbReqd
	FROM T_Analysis_Tool
	WHERE (AJT_toolName = @toolName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking up tool parameters'
		return 51038
	end
	--
	-- settings file path
	--
	if @settingsFileName <> 'na'
	begin
		if @dirPath = ''
		begin
			set @message = 'Could not get settings file folder'
			return 53107
		end
		--
		set @fullPath = @dirPath + 'SettingsFiles\' + @settingsFileName
		exec @result = VerifyFileExists @fullPath, @message output
		--
		if @result <> 0
		begin
			set @message = 'Settings file could not be found' + ':"' + @settingsFileName + '"'
			return 53108
		end
	end

	---------------------------------------------------
	-- Check protein parameters
	---------------------------------------------------
	
	if @organismDBName = '' set @organismDBName = 'na'
	if @protCollNameList = '' set @protCollNameList = 'na'
	if @protCollOptionsList = '' set @protCollOptionsList = 'na'
	--
	if @orgDbReqd = 0
		begin
			if @organismDBName <> 'na' OR @protCollNameList <> 'na' OR @protCollOptionsList <> 'na'
			begin
				set @message = 'Protein parameters must all be "na"'
				return 53093
			end
		end
	else
		begin
			exec @result = Protein_Sequences.dbo.ValidateAnalysisJobProteinParameters
								@organismName,
								@ownerPRN,
								@organismDBName,
								@protCollNameList output,
								@protCollOptionsList output,
								@message output

			--
			if @result <> 0
			begin
				return 53108
			end
		end
	


GO
