/****** Object:  StoredProcedure [dbo].[ValidateProteinCollectionParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.ValidateProteinCollectionParams
/****************************************************
** 
**	Desc:	Validates the organism DB and/or protein collection options
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	08/26/2010
**    
*****************************************************/
(
	@toolName varchar(64),						-- If blank, then will assume @orgDbReqd=1
	@organismDBName varchar(64) output,
	@organismName varchar(64),
	@protCollNameList varchar(4000) output,		-- Will raise an error if over 2000 characters long; necessary since the Broker DB (DMS_Pipeline) has a 2000 character limit on analysis job parameter values
	@protCollOptionsList varchar(256) output,
	@ownerPRN varchar(64) = '',					-- Only required if the user chooses an "Encrypted" protein collection; as of August 2010 we don't have any encrypted protein collections
	@message varchar(255) = '' output,
	@debugMode tinyint = 0						-- If non-zero then will display some debug info
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @result int
	
	-----------------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------------

	Set @message = ''
	Set @ownerPRN = IsNull(@ownerPRN, '')
	Set @debugMode = IsNull(@debugMode, 0)
	
	---------------------------------------------------
	-- Make sure settings for which 'na' is acceptable truly have lowercase 'na' and not 'NA' or 'n/a'
	-- Note that Sql server string comparisons are not case-sensitive, but VB.NET string comparisons are
	--  Therefore, @settingsFileName needs to be lowercase 'na' for compatibility with the analysis manager
	---------------------------------------------------
	--	
	Set @organismDBName =      dbo.ValidateNAParameter(@organismDBName, 1)
	Set @protCollNameList =    dbo.ValidateNAParameter(@protCollNameList, 1)
	Set @protCollOptionsList = dbo.ValidateNAParameter(@protCollOptionsList, 1)


	if @organismDBName = '' set @organismDBName = 'na'
	if @protCollNameList = '' set @protCollNameList = 'na'
	if @protCollOptionsList = '' set @protCollOptionsList = 'na'

	---------------------------------------------------
	-- Lookup orgDbReqd for the analysis tool
	---------------------------------------------------
	--
	declare @orgDbReqd int
	set @orgDbReqd = 0

	If IsNull(@toolName, '') = ''
		Set @orgDbReqd = 1
	Else
	Begin
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

		if @myRowCount = 0
		begin
			set @message = 'Invalid analysis tool "' + @toolName + '"; not found in T_Analysis_Tool'
			return 51039
		end
	End
	
	---------------------------------------------------
	-- Validate the protein collection info
	---------------------------------------------------
	
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
		if @debugMode <> 0
		begin
			Set @message =  'Calling ProteinSeqs.Protein_Sequences.dbo.ValidateAnalysisJobProteinParameters: ' +
								IsNull(@organismName, '??') + '; ' +
								IsNull(@ownerPRN, '??') + '; ' +
								IsNull(@organismDBName, '??') + '; ' +
								IsNull(@protCollNameList, '??') + '; ' +
								IsNull(@protCollOptionsList, '??')
		
			Print @message
			-- exec PostLogEntry 'Debug',@message, 'ValidateAnalysisJobParameters'
			Set @message = ''
		end
							
		exec @result = ProteinSeqs.Protein_Sequences.dbo.ValidateAnalysisJobProteinParameters
							@organismName,
							@ownerPRN,
							@organismDBName,
							@protCollNameList output,
							@protCollOptionsList output,
							@message output


		if @result <> 0
		begin
			return 53108
		end
	end
	
			
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[ValidateProteinCollectionParams] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateProteinCollectionParams] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateProteinCollectionParams] TO [PNL\D3M580] AS [dbo]
GO
