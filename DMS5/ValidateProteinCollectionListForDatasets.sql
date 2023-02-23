/****** Object:  StoredProcedure [dbo].[ValidateProteinCollectionListForDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateProteinCollectionListForDatasets]
/****************************************************
**
**	Desc:	Validates that the protein collection names in @protCollNameList
**			include protein collections for the internal standards
**			associated with the datasets listed in @datasets
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	11/13/2006 mem - Initial revision (Ticket #320)
**			02/08/2007 mem - Updated to use T_Internal_Std_Parent_Mixes to determine the protein collections associated with internal standards (Ticket #380)
**			10/11/2007 mem - Expanded protein collection list size to 4000 characters (https://prismtrac.pnl.gov/trac/ticket/545)
**			02/28/2008 grk/mem - Detect duplicate names in protein collection list (https://prismtrac.pnl.gov/trac/ticket/650)
**			07/09/2010 mem - Now auto-adding protein collections associated with the digestion enzyme for the experiments associated with the datasets; this is typically used to add trypsin contaminants to the search
**			09/02/2010 mem - Changed RAISERROR severity level from 10 to 11
**			03/21/2011 mem - Expanded @datasets to varchar(max)
**			03/14/2012 mem - Now preventing both Tryp_Pig_Bov and Tryp_Pig from being included in @protCollNameList
**			10/23/2017 mem - Do not add any enzyme-related protein collections if any of the protein collections in @protCollNameList already include contaminants
**					       - Place auto-added protein collections at the end of @protCollNameList, which is more consistent with the order we get after calling ValidateAnalysisJobParameters
**          07/27/2022 mem - Switch from FileName to Collection_Name when querying S_V_Protein_Collections_by_Organism
**
*****************************************************/
(
    @datasets varchar(max),
    @protCollNameList varchar(4000)='' output,
    @collectionCountAdded int = 0 output,
    @ShowMessages tinyint = 1,
    @message varchar(512)='' output,
    @showDebug tinyint = 0
)
As
	Set nocount on

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @msg varchar(512)

	Declare @continue int
	Declare @UniqueID int
	Declare @ProteinCollectionName varchar(128)

	Declare @matchCount int
	Declare @collectionWithContaminants varchar(128)

	Declare @DatasetCount int
	Declare @ExperimentCount int
	Declare @DatasetCountTotal int
	Declare @ExperimentCountTotal int

	Declare @EnzymeContaminantCollection tinyint

	--------------------------------------------------------------
	-- Validate the inputs
	--------------------------------------------------------------

	Set @protCollNameList = IsNull(@protCollNameList,'')
	Set @collectionCountAdded = 0
	Set @message = ''
	Set @showDebug = IsNull(@showDebug, 0)

	--------------------------------------------------------------
	-- Create the required temporary tables
	--------------------------------------------------------------

	CREATE TABLE #TmpDatasets (
		Dataset_Num varchar(128),
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		Set @msg = 'Failed to create temporary table #TmpDatasets'
		RAISERROR (@msg, 11, 1)
		return 51007
	end

	CREATE TABLE #IntStds (
		Internal_Std_Mix_ID int NOT NULL,
		Protein_Collection_Name varchar(128) NOT NULL,
		Dataset_Count int NOT NULL,
		Experiment_Count int NOT NULL,
		Enzyme_Contaminant_Collection tinyint NOT NULL
	)


	CREATE TABLE #ProteinCollections (
		RowNumberID int IDENTITY(1,1) NOT NULL,
		Protein_Collection_Name varchar(128) NOT NULL,
		Collection_Appended tinyint NOT NULL
	)

	CREATE TABLE #ProteinCollectionsToAdd (
		UniqueID int IDENTITY(1,1) NOT NULL,
		Protein_Collection_Name varchar(128) NOT NULL,
		Dataset_Count int NOT NULL,
		Experiment_Count int NOT NULL,
		Enzyme_Contaminant_Collection tinyint NOT NULL
	)


	--------------------------------------------------------------
	-- Populate #ProteinCollections with the protein collections in @protCollNameList
	--------------------------------------------------------------
	--
	INSERT INTO #ProteinCollections (Protein_Collection_Name, Collection_Appended)
	SELECT Value, 0 AS Collection_Appended
	FROM dbo.udfParseDelimitedList(@protCollNameList, ',', 'ValidateProteinCollectionListForDatasets')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	--------------------------------------------------------------
	-- Look for duplicates in #ProteinCollections
	-- If found, remove them
	--------------------------------------------------------------
	--
	Declare @dups varchar(1024) = ''

	SELECT @dups = CASE
	                   WHEN @dups = '' THEN ''
	                   ELSE @dups + ', '
	               END + Protein_Collection_Name
	FROM #ProteinCollections
	GROUP BY Protein_Collection_Name
	HAVING COUNT(*) > 1
	--
	SELECT @myError = @@error
	--
	If @myError <> 0
	Begin
		Set @msg = 'Error trying to look for duplicate protein collection names'
		RAISERROR (@msg, 11, 1)
		return 51009
	End

	If @dups <> ''
	Begin
		Set @msg = 'There were duplicate names in the protein collections list, will auto remove: ' + @dups

		If @showDebug > 0
			SELECT @msg as Debug_Message
		Else
			Print @msg

		DELETE FROM #ProteinCollections
		WHERE NOT RowNumberID IN ( SELECT Min(RowNumberID) AS IDToKeep
		                           FROM #ProteinCollections
		                           GROUP BY Protein_Collection_Name )

	End

	If @showDebug > 0
	Begin
		SELECT '#ProteinCollections' as Table_Name, *
		FROM #ProteinCollections
	End

	--------------------------------------------------------------
	-- Populate #TmpDatasets with the datasets in @datasets
	--------------------------------------------------------------
	--
	INSERT INTO #TmpDatasets (Dataset_Num)
	SELECT Value
	FROM dbo.udfParseDelimitedList(@datasets, ',', 'ValidateProteinCollectionListForDatasets')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	--------------------------------------------------------------
	-- Populate #IntStds with any protein collections associated
	-- with the enzymes for the experiments of the datasets in #TmpDatasets
	-- These are typically the contaminant collections like Tryp_Pig_Bov
	--------------------------------------------------------------
	--
	INSERT INTO #IntStds( Internal_Std_Mix_ID,
		                    Protein_Collection_Name,
		                    Dataset_Count,
		                    Experiment_Count,
		                    Enzyme_Contaminant_Collection )
	SELECT DISTINCT Internal_Std_Mix_ID,
		            Protein_Collection_Name,
		            Dataset_Count,
		            Experiment_Count,
		            Enzyme_Contaminant_Collection
	FROM ( SELECT -1 AS Internal_Std_Mix_ID,
		            ISNULL(Enz.Protein_Collection_Name, '') AS Protein_Collection_Name,
		            COUNT(DISTINCT DS.Dataset_Num) AS Dataset_Count,
		            COUNT(DISTINCT E.Exp_ID) AS Experiment_Count,
		            1 AS Enzyme_Contaminant_Collection
		    FROM #TmpDatasets
		        INNER JOIN dbo.T_Dataset DS
		            ON #TmpDatasets.Dataset_Num = DS.Dataset_Num
		        INNER JOIN T_Experiments E
		            ON DS.Exp_ID = E.Exp_ID
		        INNER JOIN T_Enzymes Enz
		            ON E.EX_enzyme_ID = Enz.Enzyme_ID
		    GROUP BY ISNULL(Enz.Protein_Collection_Name, '')
		    ) LookupQ
	WHERE Protein_Collection_Name <> ''
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	If Not Exists (SELECT * FROM #IntStds WHERE Enzyme_Contaminant_Collection > 0)
	Begin
		--------------------------------------------------------------
		-- Nothing was added; no point in looking for protein collections with Includes_Contaminants > 0
		--------------------------------------------------------------
		--
		If @showDebug > 0
		Begin
			SELECT '#IntStds' as Table_Name, *
			FROM #IntStds
		End
	End
	Else
	Begin
		--------------------------------------------------------------
		-- Check whether any of the protein collections already includes contaminants
		--------------------------------------------------------------
		--

		Set @matchCount = 0
		Set @collectionWithContaminants = ''

		SELECT @matchCount = COUNT(*),
			@collectionWithContaminants = Min(PCLocal.Protein_Collection_Name)
		FROM #ProteinCollections PCLocal
			INNER JOIN S_V_Protein_Collections_by_Organism PCMaster
			ON PCLocal.Protein_Collection_Name = PCMaster.Collection_Name
		WHERE PCMaster.Includes_Contaminants > 0

		If @matchCount > 0
		Begin
			Set @msg = 'Not adding enzyme-associated protein collections (typically contaminant collections) since ' + @collectionWithContaminants + ' already includes contaminants'

			If @showDebug > 0
				SELECT @msg as Debug_Message
			Else
				Print @msg

			Set @message = 'Did not add contaminants since ' + @collectionWithContaminants + ' already includes contaminant proteins'

			-- Remove the contaminant collections
			--
			DELETE FROM #IntStds WHERE Enzyme_Contaminant_Collection > 0
		End
	End

	--------------------------------------------------------------
	-- Populate #IntStds with any internal standards associated
	-- with the datasets in #TmpDatasets, including their parent experiments
	--------------------------------------------------------------
	--
	INSERT INTO #IntStds( Internal_Std_Mix_ID, Protein_Collection_Name,
	                      Dataset_Count, Experiment_Count,
	                      Enzyme_Contaminant_Collection )
	SELECT DSIntStd.Internal_Std_Mix_ID,
	       ISPM.Protein_Collection_Name,
	       COUNT(*) AS Dataset_Count,
	       0 AS Experiment_Count,
	       0 AS Enzyme_Contaminant_Collection
	FROM #TmpDatasets
	     INNER JOIN dbo.T_Dataset DS
	       ON #TmpDatasets.Dataset_Num = DS.Dataset_Num
	     INNER JOIN dbo.T_Internal_Standards DSIntStd
	       ON DS.DS_internal_standard_ID = DSIntStd.Internal_Std_Mix_ID
	     INNER JOIN dbo.T_Internal_Std_Parent_Mixes ISPM
	       ON DSIntStd.Internal_Std_Parent_Mix_ID = ISPM.Parent_Mix_ID
	WHERE LEN(IsNull(ISPM.Protein_Collection_Name, '')) > 0
	GROUP BY DSIntStd.Internal_Std_Mix_ID, ISPM.Protein_Collection_Name
	UNION
	SELECT DSIntStd.Internal_Std_Mix_ID,
	       ISPM.Protein_Collection_Name,
	       0 AS Dataset_Count,
	       COUNT(DISTINCT E.Exp_ID) AS Experiment_Count,
	       0 AS Enzyme_Contaminant_Collection
	FROM #TmpDatasets
	     INNER JOIN dbo.T_Dataset DS
	       ON #TmpDatasets.Dataset_Num = DS.Dataset_Num
	     INNER JOIN dbo.T_Experiments E
	       ON DS.Exp_ID = E.Exp_ID
	     INNER JOIN dbo.T_Internal_Standards DSIntStd
	       ON E.EX_internal_standard_ID = DSIntStd.Internal_Std_Mix_ID
	     INNER JOIN dbo.T_Internal_Std_Parent_Mixes ISPM
	       ON DSIntStd.Internal_Std_Parent_Mix_ID = ISPM.Parent_Mix_ID
	WHERE LEN(IsNull(ISPM.Protein_Collection_Name, '')) > 0
	GROUP BY DSIntStd.Internal_Std_Mix_ID, ISPM.Protein_Collection_Name
	UNION
	SELECT DSIntStd.Internal_Std_Mix_ID,
	       ISPM.Protein_Collection_Name,
	       0 AS Dataset_Count,
	       COUNT(DISTINCT E.Exp_ID) AS Experiment_Count,
	       0 AS Enzyme_Contaminant_Collection
	FROM #TmpDatasets
	     INNER JOIN dbo.T_Dataset DS
	       ON #TmpDatasets.Dataset_Num = DS.Dataset_Num
	     INNER JOIN dbo.T_Experiments E
	       ON DS.Exp_ID = E.Exp_ID
	     INNER JOIN dbo.T_Internal_Standards DSIntStd
	       ON E.EX_postdigest_internal_std_ID = DSIntStd.Internal_Std_Mix_ID
	     INNER JOIN dbo.T_Internal_Std_Parent_Mixes ISPM
	       ON DSIntStd.Internal_Std_Parent_Mix_ID = ISPM.Parent_Mix_ID
	WHERE LEN(IsNull(ISPM.Protein_Collection_Name, '')) > 0
	GROUP BY DSIntStd.Internal_Std_Mix_ID, ISPM.Protein_Collection_Name
	ORDER BY DSIntStd.Internal_Std_Mix_ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @showDebug > 0
	Begin
		SELECT '#IntStds' as Table_Name, *
		FROM #IntStds
	End

	--------------------------------------------------------------
	-- Make sure @protCollNameList contains each of the
	-- Protein_Collection_Name values in #IntStds
	--------------------------------------------------------------
	--
	INSERT INTO #ProteinCollectionsToAdd( Protein_Collection_Name,
	                                      Dataset_Count,
	                                      Experiment_Count,
	                                      Enzyme_Contaminant_Collection )
	SELECT I.Protein_Collection_Name,
	       SUM(I.Dataset_Count),
	       SUM(I.Experiment_Count),
	       SUM(Enzyme_Contaminant_Collection)
	FROM #IntStds I
	     LEFT OUTER JOIN #ProteinCollections PC
	       ON I.Protein_Collection_Name = PC.Protein_Collection_Name
	WHERE PC.Protein_Collection_Name IS NULL
	GROUP BY I.Protein_Collection_Name
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		Set @msg = 'Error populating #ProteinCollectionsToAdd with the missing protein collections'
		RAISERROR (@msg, 11, 1)
		return 51006
	End

	If @showDebug > 0
	Begin
		SELECT '#ProteinCollectionsToAdd' as Table_Name, *
		FROM #ProteinCollectionsToAdd
	End

	If @myRowCount > 0
	Begin -- <a>
		-- New collections were added to #ProteinCollectionsToAdd
		-- Now append them to #ProteinCollections
		-- Note that we first append collections that did not come from digestion enzymes
		--
		INSERT INTO #ProteinCollections (Protein_Collection_Name, Collection_Appended)
		SELECT Protein_Collection_Name,
		       1 AS Collection_Appended
		FROM #ProteinCollectionsToAdd
		GROUP BY Enzyme_Contaminant_Collection, Protein_Collection_Name
		ORDER BY Enzyme_Contaminant_Collection, Protein_Collection_Name
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			Set @msg = 'Error populating #ProteinCollections with the missing protein collections'
			RAISERROR (@msg, 11, 1)
			return 51008
		End

		Set @collectionCountAdded = @myRowCount

		-- Check for the presence of both Tryp_Pig_Bov and Tryp_Pig in #ProteinCollections
		--
		Set @myRowCount = 0

		SELECT @myRowCount = COUNT(*)
		FROM #ProteinCollections
		WHERE Protein_Collection_Name IN ('Tryp_Pig_Bov', 'Tryp_Pig')

		If @myRowCount = 2
		Begin
			-- The list has two overlapping contaminant collections; remove one of them
			--
			DELETE FROM #ProteinCollections
			WHERE Protein_Collection_Name = 'Tryp_Pig'

			Set @collectionCountAdded = @collectionCountAdded - 1
		End

		--------------------------------------------------------------
		-- Collapse #ProteinCollections into @protCollNameList
		-- The Order By statements in this query assure that the
		--  internal standard collections and contaminant collections
		--  are listed first and that the original collection order is preserved
		--
		-- Note that ValidateAnalysisJobParameters will call ValidateProteinCollectionParams,
		--  which calls s_validate_analysis_job_protein_parameters in the Protein_Sequences database,
		--  and that procedure uses standardize_protein_collection_list to order the protein collections in a standard manner,
		--  so the order here is not critical
		--
		-- The standard order is:
		--  Internal Standards, Normal Protein Collections, Contaminant collections
		--------------------------------------------------------------

		Set @protCollNameList = ''
		SELECT @protCollNameList = @protCollNameList + Protein_Collection_Name + ','
		FROM #ProteinCollections
		ORDER BY Collection_Appended Asc, RowNumberID Asc
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		-- Remove the trailing comma from @protCollNameList
		If Len(@protCollNameList) > 0
			Set @protCollNameList = Left(@protCollNameList, Len(@protCollNameList)-1)

		-- Count the total number of datasets and experiments in #TmpDatasets
		SELECT @DatasetCountTotal = COUNT(*),
			   @ExperimentCountTotal = COUNT(DISTINCT E.Exp_ID)
		FROM #TmpDatasets INNER JOIN
			T_Dataset DS ON #TmpDatasets.Dataset_Num = DS.Dataset_Num INNER JOIN
			T_Experiments E ON DS.Exp_ID = E.Exp_ID

		If @ShowMessages <> 0
		Begin --<b>
			-- Display messages listing the collections added
			Set @UniqueID = 0
			Set @continue = 1
			While @continue = 1
			Begin -- <c>
				SELECT TOP 1 @UniqueID = UniqueID,
							@ProteinCollectionName = Protein_Collection_Name,
							@DatasetCount = Dataset_Count,
							@ExperimentCount = Experiment_Count,
							@EnzymeContaminantCollection = Enzyme_Contaminant_Collection
				FROM #ProteinCollectionsToAdd
				WHERE UniqueID > @UniqueID
				ORDER BY UniqueID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount

				If @myRowCount <> 1
					Set @continue = 0
				Else
				Begin -- <d>
					If @EnzymeContaminantCollection <> 0
					Begin
						Set @msg = 'Added enzyme contaminant collection ' + @ProteinCollectionName
					End
					Else
					Begin
						Set @msg = 'Added protein collection ' + @ProteinCollectionName + ' since it is present in '
						If @DatasetCount > 0
						Begin -- <e1>
							Set @msg = @msg + Convert(varchar(12), @DatasetCount) + ' of '
							Set @msg = @msg + Convert(varchar(12), @DatasetCountTotal) + ' dataset'
							If @DatasetCountTotal <> 1
								Set @msg = @msg + 's'
						End -- </e1>
						Else
						Begin -- <e2>
							If @ExperimentCount > 0
							Begin
								Set @msg = @msg + Convert(varchar(12), @ExperimentCount) + ' of '
								Set @msg = @msg + Convert(varchar(12), @ExperimentCountTotal) + ' experiment'
								If @ExperimentCountTotal <> 1
									Set @msg = @msg + 's'
							End
							Else
							Begin
								-- Both @DatasetCount and @ExperimentCount are 0
								-- This code should not be reached
								Set @msg = @msg + '? datasets and/or ? experiments (unexpected stats)'
							End
						End -- </e2>
					End

					If Len(@message) > 0
						Set @message = @message + '; ' + @msg
					Else
						Set @message = 'Note: ' + @msg

				End -- </d>
			End-- </c>
		End -- </b>
	End -- </a>

Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ValidateProteinCollectionListForDatasets] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ValidateProteinCollectionListForDatasets] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateProteinCollectionListForDatasets] TO [Limited_Table_Write] AS [dbo]
GO
