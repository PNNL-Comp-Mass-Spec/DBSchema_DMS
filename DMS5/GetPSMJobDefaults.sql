/****** Object:  StoredProcedure [dbo].[GetPSMJobDefaults] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[GetPSMJobDefaults]
/****************************************************
**
**	Desc: Parses the list of datasets to create a table of stats and to suggest 
**  default search settings for creating an analysis job to search MS/MS data (PSM search)
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	11/14/2012 mem - Initial version
**			11/20/2012 mem - Added 3 new parameters: organism name, protein collection name, and protein collection options
**			01/11/2013 mem - Renamed MSGF-DB search tool to MSGFPlus
**			03/05/2013 mem - Now passing @AutoRemoveNotReleasedDatasets to ValidateAnalysisJobRequestDatasets
**			09/03/2013 mem - Added iTRAQ8
**			04/23/2015 mem - Now passing @toolName to ValidateAnalysisJobRequestDatasets
**			02/23/2016 mem - Add set XACT_ABORT on
**			03/18/2016 mem - Added TMT6 and TMT10
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/13/2017 mem - Exclude logging some try/catch errors
**			12/06/2017 mem - Set @allowNewDatasets to 1 when calling ValidateAnalysisJobRequestDatasets
**    
*****************************************************/
(
    @datasets varchar(max) output,				-- Input/output parameter; comma-separated list of datasets; will be alphabetized after removing duplicates
	@Metadata varchar(2048) output,				-- Output parameter; table of metadata with columns separated by colons and rows separated by vertical bars
    @toolName varchar(64) output,
    @jobTypeName varchar(64) output,
    @jobTypeDesc varchar(255) output,
    @DynMetOxEnabled tinyint output,    
    @StatCysAlkEnabled tinyint output,
    @DynSTYPhosEnabled tinyint output,
    @organismName varchar(128) output,
    @protCollNameList varchar(1024) output,
    @protCollOptionsList varchar(256) output,
    @message varchar(512) output
)
As
	Set XACT_ABORT, nocount on

	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	Declare @msg varchar(512)
	Declare @result int = 0
	Declare @List varchar(1024)
	
	Declare @TopDatasetType varchar(64) = ''
	Declare @TopLabeling varchar(64) = ''
	
	Declare @DatasetCount int = 0
	Declare @DatasetCountAlkylated int = 0
	Declare @DatasetCountPhospho int = 0
	Declare @OrganismCount int = 0
	
	Declare @logErrors tinyint = 0
	
	BEGIN TRY 

		---------------------------------------------------
		-- Initialize the output parameters
		---------------------------------------------------
		
		Set @Metadata = ''
		Set @toolName = 'MSGFPlus'
		Set @jobTypeName = ''
		Set @jobTypeDesc = ''
		Set @DynMetOxEnabled = 0
		Set @StatCysAlkEnabled = 0
		Set @DynSTYPhosEnabled = 0
		Set @organismName = ''
		Set @protCollNameList = ''
		Set @protCollOptionsList = ''
		Set @message = ''

		---------------------------------------------------
		-- dataset list shouldn't be empty
		---------------------------------------------------
		If IsNull(@datasets, '') = ''
			RAISERROR ('Dataset list is empty', 11, 1)

		Set @logErrors = 1
		
		---------------------------------------------------
		-- Create temporary table to hold list of datasets
		---------------------------------------------------

		CREATE TABLE #TD (
			Dataset_Num varchar(128),
			Dataset_ID int NULL,
			IN_class varchar(64) NULL, 
			DS_state_ID int NULL, 
			AS_state_ID int NULL,
			Dataset_Type varchar(64) NULL,
			DS_rating smallint NULL
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
			RAISERROR ('Failed to create temporary table', 11, 10)

		CREATE INDEX #IX_TD_DatasetID ON #TD (Dataset_ID)

		---------------------------------------------------
		-- Create several additional temporary tables
		---------------------------------------------------

		CREATE TABLE #T_Tmp_DatasetTypeStats (
			Dataset_Type varchar(64),
			Description varchar(255),
			DatasetCount int
		)

		CREATE TABLE #T_Tmp_DatasetLabelingStats (
			Labeling varchar(64),
			DatasetCount int
		)
		
		CREATE TABLE #T_Tmp_Organisms (
			OrganismName varchar(128),
			DatasetCount int
		)
		
		---------------------------------------------------
		-- Populate #TD using the dataset list
		-- Remove any duplicates that may be present
		---------------------------------------------------
		--
		INSERT INTO #TD ( Dataset_Num )
		SELECT DISTINCT Item
		FROM MakeTableFromList ( @datasets )
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			RAISERROR ('Error populating temporary table #TD', 11, 10)
		End

		---------------------------------------------------
		-- Validate the datasets in #TD
		---------------------------------------------------
		
		exec @result = ValidateAnalysisJobRequestDatasets @message output, @AutoRemoveNotReleasedDatasets=1, @toolName=@toolName, @allowNewDatasets=1
		
		If @result <> 0
		Begin
			Set @logErrors = 0
			RAISERROR (@message, 11, 10)
		End
		
		---------------------------------------------------
		-- Regenerate the dataset list, sorting by dataset name
		---------------------------------------------------
		--
		Set @datasets = ''
		
		SELECT @datasets = @datasets + Dataset_Num + ', '
		FROM #TD
		ORDER BY Dataset_Num
			
		-- Remove the trailing comma
		If Len(@datasets) > 0
		Set @datasets = SubString(@datasets, 1, Len(@datasets)-1)
		
		---------------------------------------------------
		-- Populate a temporary table with dataset type stats
		---------------------------------------------------
		
		INSERT INTO #T_Tmp_DatasetTypeStats (Dataset_Type, Description, DatasetCount)
		SELECT DTN.DST_name, DTN.DST_Description, COUNT(*) AS DatasetCount
		FROM #TD
		     INNER JOIN T_DatasetTypeName DTN
		       ON #TD.Dataset_Type = DTN.DST_Name
		GROUP BY DTN.DST_name, DTN.DST_Description
		ORDER BY DTN.DST_name
		--
		SELECT Top 1 @TopDatasetType = Dataset_Type
		FROM #T_Tmp_DatasetTypeStats
		ORDER BY DatasetCount Desc		
				
		---------------------------------------------------
		-- Populate a temporary table with labeling stats
		---------------------------------------------------

		INSERT INTO #T_Tmp_DatasetLabelingStats (Labeling, DatasetCount)
		SELECT E.EX_Labelling, COUNT(*) AS DatasetCount
		FROM #TD
		     INNER JOIN T_Dataset DS
		       ON #TD.Dataset_ID = DS.Dataset_ID
		     INNER JOIN T_Experiments E
		       ON DS.Exp_ID = E.Exp_ID
		GROUP BY E.EX_Labelling
		ORDER BY E.EX_Labelling
		--
		SELECT Top 1 @TopLabeling = Labeling
		FROM #T_Tmp_DatasetLabelingStats
		ORDER BY DatasetCount Desc		

		---------------------------------------------------
		-- Populate a temporary table with the organism(s) for the datasets
		---------------------------------------------------

		INSERT INTO #T_Tmp_Organisms (OrganismName, DatasetCount)
		SELECT O.OG_name, COUNT(*) AS DatasetCount
		FROM #TD
		     INNER JOIN T_Dataset DS
		       ON #TD.Dataset_ID = DS.Dataset_ID
		     INNER JOIN T_Experiments E
		       ON DS.Exp_ID = E.Exp_ID
		     INNER JOIN T_Organisms O
		       ON E.EX_organism_ID = O.Organism_ID
		GROUP BY O.OG_name
		ORDER BY O.OG_name
		--
		SELECT @myError = @@error, @OrganismCount = @@rowcount
		--
		SELECT Top 1 @organismName = OrganismName
		FROM #T_Tmp_Organisms
		ORDER BY DatasetCount Desc

		Set @protCollNameList = ''
		Set @protCollOptionsList = 'seq_direction=decoy'
		
		-- Lookup the default protein collection name (if defined)
		--
		SELECT @protCollNameList = OG_organismDBName
		FROM T_Organisms
		WHERE OG_name = @organismName AND IsNull(OG_organismDBName, 'na') <> 'na'

		If Len(@protCollNameList) > 0 And dbo.ValidateNAParameter(@protCollNameList, 1) <> 'na'
		Begin
			-- Append the default contaminant collections
			exec @result = ValidateProteinCollectionListForDatasets 
								@datasets, 
								@protCollNameList=@protCollNameList output, 
								@ShowMessages=1
						
		End
		
		---------------------------------------------------
		-- Populate @Metadata
		---------------------------------------------------
		
		-- Header row
		--
		Set @Metadata = 'Metadata:Description:Datasets|'
		
		-- Dataset Type stats
		--
		SELECT @Metadata = @Metadata + Dataset_Type + ':' + Description + ':' + Convert(varchar(12), DatasetCount) + '|'
		FROM #T_Tmp_DatasetTypeStats
		ORDER BY Dataset_Type
		
		-- Alkylation
		--
		SELECT @DatasetCount = COUNT(*),
		       @DatasetCountAlkylated = SUM(CASE WHEN Ex_Alkylation = 'Y' THEN 1 ELSE 0 END)
		FROM #TD
		     INNER JOIN T_Dataset DS
		       ON #TD.Dataset_ID = DS.Dataset_ID
		     INNER JOIN T_Experiments E
		       ON DS.Exp_ID = E.Exp_ID
		
		Set @Metadata = @Metadata + 'Alkylated:Sample (experiment) marked as alkylated in DMS:' + Convert(varchar(12), @DatasetCountAlkylated) + '|'
		
		-- Labeling
		--
		SELECT @Metadata = @Metadata + 'Labeling:' + Labeling + ':' + Convert(varchar(12), DatasetCount) + '|'
		FROM #T_Tmp_DatasetLabelingStats
		ORDER BY Labeling
				
		-- Enzyme
		--
		SELECT @Metadata = @Metadata + 'Enzyme:' + Enz.Enzyme_Name + ':' + Convert(varchar(12), COUNT(*)) + '|'
		FROM #TD
		     INNER JOIN T_Dataset DS
		       ON #TD.Dataset_ID = DS.Dataset_ID
		     INNER JOIN T_Experiments E
		       ON DS.Exp_ID = E.Exp_ID
		     INNER JOIN T_Enzymes Enz 
		       ON E.EX_enzyme_ID = Enz.Enzyme_ID
		GROUP BY Enz.Enzyme_Name
		ORDER BY Enz.Enzyme_Name

		-- Display the organism names if datasets from multiple organisms are present
		--
		If @OrganismCount > 1
		Begin
			SELECT @Metadata = @Metadata + 'Organism:' + OrganismName + ':' + Convert(varchar(12), DatasetCount) + '|'
			FROM #T_Tmp_Organisms
			ORDER BY OrganismName
		End
				
		-- Look for phosphorylation
		--
		SELECT @DatasetCountPhospho = COUNT(*)
		FROM #TD
		WHERE Dataset_Num Like '%Phospho%' Or Dataset_Num Like '%NiNTA%'
		
		---------------------------------------------------
		-- Define the default options using the stats on the datasets
		---------------------------------------------------

		Set @jobTypeName = ''
		
		If @jobTypeName = '' And @TopLabeling Like '%itraq8%' And @TopDatasetType Like '%HCD%'
		Begin
			Set @jobTypeName = 'iTRAQ 8-plex'
		End
		
		If @jobTypeName = '' And @TopLabeling Like '%itraq%' And @TopDatasetType Like '%HCD%'
		Begin
			Set @jobTypeName = 'iTRAQ 4-plex'
		End

		If @jobTypeName = '' And (@TopLabeling Like '%TMT6%' OR @TopLabeling Like '%TMT10%') And @TopDatasetType Like '%HCD%'
		Begin
			Set @jobTypeName = 'TMT 6-plex'
		End
		
		If @jobTypeName = '' And @TopDatasetType Like 'MS-%MSn'
		Begin
			Set @jobTypeName = 'Low Res MS1'
		End
		
		If @jobTypeName = '' And @TopDatasetType Like '%HMS-%MSn'
		Begin
			Set @jobTypeName = 'High Res MS1'
		End
	
		If @DatasetCountPhospho > @DatasetCount * 0.85
		Begin
			Set @DynSTYPhosEnabled = 1
			Set @DynMetOxEnabled = 0
		End
		Else
		Begin
			Set @DynSTYPhosEnabled = 0
			Set @DynMetOxEnabled = 1
		End

		If @DatasetCountAlkylated > @DatasetCount * 0.85
			Set @StatCysAlkEnabled = 1
		Else
			Set @StatCysAlkEnabled = 0

		-- Lookup the description for @jobTypeName
		--
		SELECT @jobTypeDesc = Job_Type_Description
		FROM T_Default_PSM_Job_Types
		WHERE Job_Type_Name = @jobTypeName
		
		Set @jobTypeDesc = IsNull(@jobTypeDesc, '')
	
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		If (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

		If @logErrors > 0			
			Exec PostLogEntry 'Error', @message, 'GetPSMJobDefaults'
	END CATCH
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[GetPSMJobDefaults] TO [DDL_Viewer] AS [dbo]
GO
