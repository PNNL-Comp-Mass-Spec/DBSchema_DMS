/****** Object:  StoredProcedure [dbo].[ValidateAnalysisJobParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[ValidateAnalysisJobParameters]
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
**
*****************************************************/
(
	@toolName varchar(64),
    @parmFileName varchar(255) output,
    @settingsFileName varchar(64) output,
    @organismDBName varchar(64) output,
    @organismName varchar(64),
	@protCollNameList varchar(4000) output,		-- Will raise an error if over 2000 characters long; necessary since the Broker DB (DMS_Pipeline) has a 2000 character limit on analysis job parameter values
	@protCollOptionsList varchar(256) output,
    @ownerPRN varchar(32),
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
	WHERE 
		(DS_rating = -2)
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
		set @message = 'The following datasets have a rating of -2 (Data Files Missing):"' + @list + '"'
		return 51007
	end	
	
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
	
	-- get list of allowed instrument classes and dataset types for tool
	--
	declare @allowedInstClasses varchar(255)
	declare @allowedDatasetTypes varchar(255)
	--
	SELECT  @allowedInstClasses = AJT_allowedInstClass,
			@allowedDatasetTypes = AJT_allowedDatasetTypes
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
	FROM
		#TD 
	WHERE 
		Dataset_Type NOT IN (SELECT * FROM MakeTableFromList(@allowedDatasetTypes))
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
