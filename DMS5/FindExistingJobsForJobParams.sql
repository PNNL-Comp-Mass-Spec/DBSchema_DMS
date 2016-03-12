/****** Object:  StoredProcedure [dbo].[FindExistingJobsForJobParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE FindExistingJobsForJobParams
/****************************************************
**
**	Desc: 
**    Check how many existing jobs already exist that
**    satisfy given set of parameters
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	12/7/2005
**			04/04/2006 grk - increased sized of param file name
**			03/28/2006 grk - added protein collection fields
**			04/07/2006 grk - eliminated job to request map table
**			01/02/2009 grk - added dataset to output rowset
**			02/27/2009 mem - Expanded @comment to varchar(512)
**			03/27/2009 mem - Updated Where clause logic for Peptide_Hit jobs to ignore organism name when using a Protein Collection List
**						   - Expanded @datasetList to varchar(6000)
**			09/18/2009 mem - Switched to using dbo.MakeTableFromList to populate #XT
**						   - Now checking for invalid dataset names
**			09/18/2009 grk - Cleaned up unused parameters
**			05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**			09/25/2012 mem - Expanded @organismDBName and @organismName to varchar(128)
**    
*****************************************************/
(
	@datasetList varchar(6000),
	@toolName varchar(64),
	@parmFileName varchar(255),
	@settingsFileName varchar(255),
	@organismDBName varchar(128),
	@organismName varchar(128),
	@protCollNameList varchar(512),
	@protCollOptionsList varchar(256),
	@message varchar(512) = '' output		
)
AS
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	Declare @DatasetName varchar(128)
	
	---------------------------------------------------
	-- temporary table to hold dataset list
	---------------------------------------------------
	
	create table #XT (
		dataset varchar(128),
		ID int NULL
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temp table'
		goto Done
	end

	---------------------------------------------------
	-- convert dataset list to table entries
	---------------------------------------------------
	
	INSERT INTO #XT (dataset)
	SELECT DISTINCT Item
	FROM dbo.MakeTableFromList(@datasetList)
	ORDER BY Item


	---------------------------------------------------
	-- get dataset IDs for the datasets in #XT
	---------------------------------------------------
	
	UPDATE #XT
	SET ID = T_Dataset.Dataset_ID
	FROM #XT
	     INNER JOIN T_Dataset
	       ON T_Dataset.Dataset_Num = #XT.dataset
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to update dataset IDs'
		goto Done
	end
	
	---------------------------------------------------
	-- Check for any unknown datasets
	---------------------------------------------------
	
	Set @myRowCount = 0
	
	SELECT @myRowCount = COUNT(*)
	FROM #XT
	WHERE ID Is Null
	
	If @myRowCount > 0 
	Begin
		If @myRowCount = 1
		Begin
			SELECT @DatasetName = Dataset
			FROM #XT
			WHERE ID Is Null
			
			Set @message = 'Error: "' + @DatasetName + '" is not a known dataset'
		End
		Else
			Set @message = 'Error: ' + Convert(varchar(12), @myRowCount) + ' dataset names are invalid'
			
		RAISERROR (@message, 10, 1)
	End
	
	---------------------------------------------------
	-- convert organism name to ID
	---------------------------------------------------

	declare @organismID int
	execute @organismID = GetOrganismID @organismName

	---------------------------------------------------
	-- convert tool name to ID
	---------------------------------------------------

	declare @analysisToolID int
	execute @analysisToolID = GetAnalysisToolID @toolName

	---------------------------------------------------
	-- look for existing jobs
	---------------------------------------------------


	-- Lookup the ResultType for @toolName
	--
	declare @resultType varchar(32)
	--
	SELECT @resultType = AJT_resultType
	FROM  T_Analysis_Tool
	WHERE AJT_toolName = @toolName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	Set @resultType = IsNull(@resultType, 'Unknown')

	
	-- When looking for existing jobs, if the analysis tool is not a Peptide_Hit tool,
	--  then we ignore OrganismDBName, Organism Name, Protein Collection List, and Protein Options List
	--
	-- If the tool is a Peptide_Hit tool, then we only consider Organism Name when searching
	--  against a legacy Fasta file (i.e. when the Protein Collection List is 'na')

	SELECT AJ.AJ_jobID AS Job,
	       ASN.AJS_name AS State,
	       DS.Dataset_Num AS Dataset,
	       AJ.AJ_created AS Created,
	       AJ.AJ_start AS Start,
	       AJ.AJ_finish AS Finish
	FROM #XT
	     INNER JOIN T_Dataset DS
	       ON #XT.ID = DS.Dataset_ID
	     INNER JOIN T_Analysis_Job AJ
	       ON AJ.AJ_datasetID = DS.Dataset_ID
	     INNER JOIN T_Analysis_Tool AJT
	       ON AJ.AJ_analysisToolID = AJT.AJT_toolID
	     INNER JOIN T_Organisms Org
	       ON AJ.AJ_organismID = Org.Organism_ID
	     INNER JOIN T_Analysis_State_Name ASN
	       ON AJ.AJ_StateID = ASN.AJS_stateID
	WHERE AJT.AJT_toolName = @toolName AND
	      AJ.AJ_parmFileName = @parmFileName AND
	      AJ.AJ_settingsFileName = @settingsFileName AND
	      (@resultType NOT LIKE '%Peptide_Hit%' OR
	       @resultType LIKE '%Peptide_Hit%' AND
	       (
	        (	@protCollNameList <> 'na' AND
				AJ.AJ_proteinCollectionList = @protCollNameList AND
				AJ.AJ_proteinOptionsList = @protCollOptionsList
			) OR
	        (	@protCollNameList = 'na' AND
				AJ.AJ_proteinCollectionList = @protCollNameList AND
				AJ.AJ_organismDBName = @organismDBName AND
				Org.OG_name = @organismName
			)
		   )
		  )
	ORDER BY AJ.AJ_jobID

Done:
	RETURN @myError

GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForJobParams] TO [DMS_Guest] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForJobParams] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForJobParams] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindExistingJobsForJobParams] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindExistingJobsForJobParams] TO [PNL\D3M578] AS [dbo]
GO
