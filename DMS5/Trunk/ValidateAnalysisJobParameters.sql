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
**	Auth:	grk
**	Date:	04/04/2006 grk - supersedes MakeAnalysisJobX
**			05/01/2006 grk - modified to conditionally call 
**                            Protein_Sequences.dbo.ValidateAnalysisJobProteinParameters
**			06/01/2006 grk - removed dataset archive state restriction 
**			08/30/2006 grk - removed restriction for dataset state verification that limited it to "add" mode (http://prismtrac.pnl.gov/trac/ticket/219)
**			11/30/2006 mem - Now checking dataset type against AJT_allowedDatasetTypes in T_Analysis_Tool (Ticket #335)
**			12/20/2006 mem - Now assuring dataset rating is not -2=Data Files Missing (Ticket #339)
**			09/06/2007 mem - Updated to reflect Protein_Sequences DB move to server ProteinSeqs
**			10/11/2007 grk - Expand protein collection list size to 4000 characters (http://prismtrac.pnl.gov/trac/ticket/545)
**			09/12/2008 mem - Now calling ValidateNAParameter for the various parameters that can be 'na' (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**						   - Changed @parmFileName and @settingsFileName to be input/output parameters instead of input only
**			01/14/2009 mem - Now raising an error if @protCollNameList is over 2000 characters long (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**			01/28/2009 mem - Now checking for settings files in T_Settings_Files instead of on disk (Ticket #718, http://prismtrac.pnl.gov/trac/ticket/718)
**			12/18/2009 mem - Now using T_Analysis_Tool_Allowed_Dataset_Type to determine valid dataset types for a given analysis tool
**			12/21/2009 mem - Now validating that the parameter file tool and the settings file tool match the tool defined by @toolName
**			02/11/2010 mem - Now assuring dataset rating is not -1 (or -2)
**			05/05/2010 mem - Now calling AutoResolveNameToPRN to check if @ownerPRN contains a person's real name rather than their username
**			05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**
*****************************************************/
(
	@toolName varchar(64),
	@parmFileName varchar(255) output,
	@settingsFileName varchar(255) output,
	@organismDBName varchar(64) output,
	@organismName varchar(64),
	@protCollNameList varchar(4000) output,		-- Will raise an error if over 2000 characters long; necessary since the Broker DB (DMS_Pipeline) has a 2000 character limit on analysis job parameter values
	@protCollOptionsList varchar(256) output,
	@ownerPRN varchar(64) output,
	@mode varchar(12), 
	@userID int output,
	@analysisToolID int output, 
	@organismID int output,
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @list varchar(1024)
	declare @ParamFileTool varchar(128)
	declare @SettingsFileTool varchar(128)

	---------------------------------------------------
	-- Update temp table from existing datasets
	---------------------------------------------------
	
	UPDATE T
	SET
		T.Dataset_ID = T_Dataset.Dataset_ID, 
		T.IN_class = T_Instrument_Class.IN_class, 
		T.DS_state_ID = T_Dataset.DS_state_ID, 
		T.AS_state_ID = isnull(T_Dataset_Archive.AS_state_ID, 0),
		T.Dataset_Type = T_DatasetTypeName.DST_name,
		T.DS_rating = T_Dataset.DS_Rating
	FROM
		#TD T INNER JOIN
		T_Dataset ON T.Dataset_Num = T_Dataset.Dataset_Num INNER JOIN
		T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
		T_Instrument_Class ON T_Instrument_Name.IN_class = T_Instrument_Class.IN_class INNER JOIN
		T_DatasetTypeName ON T_DatasetTypeName.DST_Type_ID = T_Dataset.DS_type_ID LEFT OUTER JOIN
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
		set @message = 'Error checking dataset state'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following datasets were not in correct state:"' + @list + '"'
		return 51007
	end	

	---------------------------------------------------
	-- Verify rating of datasets
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
	WHERE (DS_rating IN (-1, -2))
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking dataset rating'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following datasets have a rating of -1 (No Data) or -2 (Data Files Missing): "' + @list + '"'
		return 51007
	end	
	
	---------------------------------------------------
	-- Resolve user ID for operator PRN
	---------------------------------------------------

	execute @userID = GetUserID @ownerPRN
	if @userID = 0
	begin
		---------------------------------------------------
		-- @ownerPRN did not resolve to a User_ID
		-- In case a name was entered (instead of a PRN),
		--  try to auto-resolve using the U_Name column in T_Users
		---------------------------------------------------
		Declare @MatchCount int
		Declare @NewPRN varchar(64)

		exec AutoResolveNameToPRN @ownerPRN, @MatchCount output, @NewPRN output, @userID output
					
		If @MatchCount = 1
		Begin
			-- Single match was found; update @ownerPRN
			Set @ownerPRN = @NewPRN
		End
		Else
		Begin
			set @message = 'Could not find entry in database for owner PRN "' + @ownerPRN + '"'
			return 51019
		End
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
	
	-- get list of allowed instrument classes and dataset types for tool
	--
	declare @allowedInstClasses varchar(255)
	--
	SELECT  @allowedInstClasses = AJT_allowedInstClass
	FROM    T_Analysis_Tool
	WHERE   (AJT_toolName = @toolName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking for allowed instrument classes for tool'
		return 51007
	end

	-- find datasets that are not compatible with tool 
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
		set @message = 'The instrument class for the following datasets is not compatible with the analysis tool: "' + @list + '"'
		return 51007
	end

	---------------------------------------------------
	-- Check tool/dataset type compatibility for datasets
	---------------------------------------------------
	
	-- find datasets that are not compatible with tool 
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN Dataset_Num
		ELSE ', ' + Dataset_Num
		END
	FROM #TD
	WHERE Dataset_Type NOT IN ( SELECT ADT.Dataset_Type
	                            FROM T_Analysis_Tool_Allowed_Dataset_Type ADT
	                                 INNER JOIN T_Analysis_Tool Tool
	                                   ON ADT.Analysis_Tool_ID = Tool.AJT_toolID
	                            WHERE Tool.AJT_toolName = @toolName )
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking dataset types against tool'
		return 51008
	end

	if @list <> ''
	begin
		set @message = 'The dataset type for the following datasets is not compatible with the analysis tool: "' + @list + '"'
		return 51008
	end
	
	
	---------------------------------------------------
	-- Make sure settings for which 'na' is acceptable truly have lowercase 'na' and not 'NA' or 'n/a'
	-- Note that Sql server string comparisons are not case-sensitive, but VB.NET string comparisons are
	--  Therefore, @settingsFileName needs to be lowercase 'na' for compatibility with the analysis manager
	---------------------------------------------------
	--	
	Set @settingsFileName =    dbo.ValidateNAParameter(@settingsFileName, 1)
	Set @parmFileName =        dbo.ValidateNAParameter(@parmFileName, 1)
	Set @organismDBName =      dbo.ValidateNAParameter(@organismDBName, 1)
	Set @protCollNameList =    dbo.ValidateNAParameter(@protCollNameList, 1)
	Set @protCollOptionsList = dbo.ValidateNAParameter(@protCollOptionsList, 1)
	
	---------------------------------------------------
	-- Validate param file for tool
	---------------------------------------------------

	declare @result int
	--
	set @result = 0
	--
	if @parmFileName <> 'na'
	begin
		if Exists (SELECT * FROM dbo.T_Param_Files WHERE (Param_File_Name = @parmFileName) AND (Valid <> 0))
		Begin
			-- The specified parameter file is valid
			-- Make sure the parameter file tool corresponds to @toolName
			
			If Not Exists (
				SELECT *
				FROM T_Param_Files PF
				     INNER JOIN T_Analysis_Tool ToolList
				       ON PF.Param_File_Type_ID = ToolList.AJT_paramFileType
				WHERE (PF.Param_File_Name = @parmFileName) AND
				      (ToolList.AJT_toolName = @toolName)
				)
			Begin
				SELECT TOP 1 @ParamFileTool = ToolList.AJT_toolName
				FROM T_Param_Files PF
				     INNER JOIN T_Analysis_Tool ToolList
				       ON PF.Param_File_Type_ID = ToolList.AJT_paramFileType
				WHERE (PF.Param_File_Name = @parmFileName)
				ORDER BY ToolList.AJT_toolID

				set @message = 'Parameter file "' + @parmFileName + '" is for tool ' + @ParamFileTool + '; not ' + @toolName
				return 53111
			End
		End
		else
		begin
			-- Parameter file either does not exist or is inactive
			--
			If Exists (SELECT * FROM dbo.T_Param_Files WHERE (Param_File_Name = @parmFileName) AND (Valid = 0))
				set @message = 'Parameter file is inactive and cannot be used' + ':"' + @parmFileName + '"'
			Else
				set @message = 'Parameter file could not be found' + ':"' + @parmFileName + '"'
				
			return 53109
		end
	end

	---------------------------------------------------
	-- Lookup orgDbReqd for this tool
	---------------------------------------------------

	declare @orgDbReqd int
	set @orgDbReqd = 0

	SELECT 
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

	---------------------------------------------------
	-- Validate settings file for tool
	-- We used to check for the existence of settings files on disk (in the DMS_Parameter_Files share)
	-- However, settings files for tools that use the Job Broker now only live in the T_Settings_Files table,
	--  so we will simply check for an entry in that table
	---------------------------------------------------

	if @settingsFileName <> 'na'
	begin
		if Exists (SELECT * FROM dbo.T_Settings_Files WHERE (File_Name = @settingsFileName) AND (Active <> 0))
		Begin
			-- The specified settings file is valid
			-- Make sure the settings file tool corresponds to @toolName

			If Not Exists (
				SELECT *
				FROM V_Settings_File_Picklist SFP
				WHERE (SFP.File_Name = @settingsFileName) AND
				      (SFP.Analysis_Tool = @toolName)
				)
			Begin

				SELECT TOP 1 @SettingsFileTool = SFP.Analysis_Tool
				FROM V_Settings_File_Picklist SFP
				     INNER JOIN T_Analysis_Tool ToolList
				       ON SFP.Analysis_Tool = ToolList.AJT_toolName
				WHERE (SFP.File_Name = @settingsFileName)
				ORDER BY ToolList.AJT_toolID

				set @message = 'Settings file "' + @settingsFileName + '" is for tool ' + @SettingsFileTool + '; not ' + @toolName
				return 53112
			End
		End
		else
		begin
			-- Settings file either does not exist or is inactive
			--
			If Exists (SELECT * FROM dbo.T_Settings_Files WHERE (File_Name = @settingsFileName) AND (Active = 0))
				set @message = 'Settings file is inactive and cannot be used' + ':"' + @settingsFileName + '"'
			Else
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

	if Len(@protCollNameList) > 2000
	begin
		set @message = 'Protein collection list is too long; maximum length is 2000 characters'
		return 53110
	end
	--
	if @orgDbReqd = 0
	begin
		if @organismDBName <> 'na' OR @protCollNameList <> 'na' OR @protCollOptionsList <> 'na'
		begin
			set @message = 'Protein parameters must all be "na"; you have: OrgDBName = "' + @organismDBName + '", ProteinCollectionList = "' + @protCollNameList + '", ProteinOptionsList = "' + @protCollOptionsList + '"'
			return 53093
		end
	end
	else
	begin
		exec @result = ProteinSeqs.Protein_Sequences.dbo.ValidateAnalysisJobProteinParameters
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
GRANT VIEW DEFINITION ON [dbo].[ValidateAnalysisJobParameters] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateAnalysisJobParameters] TO [PNL\D3M580] AS [dbo]
GO
