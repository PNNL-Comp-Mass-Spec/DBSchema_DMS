/****** Object:  StoredProcedure [dbo].[ValidateProteinCollectionListForDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ValidateProteinCollectionListForDatasets
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
**    
*****************************************************/
(
    @datasets varchar(7800),
    @protCollNameList varchar(4000)='' output,
    @CollectionCountAdded int = 0 output,
    @ShowMessages tinyint = 1,
    @message varchar(512)='' output
)
As
	Set nocount on
	
	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Set @protCollNameList = IsNull(@protCollNameList,'')
	set @CollectionCountAdded = 0
	set @message = ''
	
	declare @msg varchar(512)

	declare @continue int
	declare @UniqueID int
	declare @ProteinCollectionName varchar(128)
	
	declare @DatasetCount int
	declare @ExperimentCount int
	declare @DatasetCountTotal int
	declare @ExperimentCountTotal int
	
	declare @EnzymeContaminantCollection tinyint
	

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
		set @msg = 'Failed to create temporary table #TmpDatasets'
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
	SELECT Item, 0 AS Collection_Appended
	FROM MakeTableFromList(@protCollNameList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	--------------------------------------------------------------
	-- Look for duplicates in #ProteinCollections
	--------------------------------------------------------------
	--
	declare @dups varchar(1024)
	set @dups = ''

	SELECT   
		@dups = CASE 
				WHEN @dups = '' THEN ''
				ELSE @dups + ', '
				END + Protein_Collection_Name
	FROM #ProteinCollections
	GROUP BY Protein_Collection_Name
	HAVING   COUNT(*) > 1
	--
	SELECT @myError = @@error
	--
	If @myError <> 0
	Begin
		set @msg = 'Error trying to look for duplicate protein collection names'
		RAISERROR (@msg, 11, 1)
		return 51009
	End	
	
	If @dups <> ''
	Begin
		set @msg = 'There were duplicate names (' + @dups + ') in the protein collections list'
		RAISERROR (@msg, 11, 1)
		return 51010
	End

	--------------------------------------------------------------
	-- Populate #TmpDatasets with the datasets in @datasets
	--------------------------------------------------------------
	--   
	INSERT INTO #TmpDatasets (Dataset_Num)
	SELECT Item
	FROM MakeTableFromList(@datasets)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	

	--------------------------------------------------------------
	-- Populate #IntStds with any protein collections associated 
	-- with the enzymes for the experiments of the datasets in #TmpDatasets
	--------------------------------------------------------------
	--	
	INSERT INTO #IntStds( Internal_Std_Mix_ID, Protein_Collection_Name,
	                      Dataset_Count, Experiment_Count,
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

	
	--------------------------------------------------------------
	-- Populate #IntStds with any internal standards associated 
	-- with the datasets in #TmpDatasets, including their parent experiments
	--------------------------------------------------------------
	--   
	INSERT INTO #IntStds( Internal_Std_Mix_ID, Protein_Collection_Name,
	                      Dataset_Count, Experiment_Count,
	                      Enzyme_Contaminant_Collection )
	SELECT DSIntStd.Internal_Std_Mix_ID, ISPM.Protein_Collection_Name, 
		COUNT(*) AS Dataset_Count, 0 AS Experiment_Count, 0 AS Enzyme_Contaminant_Collection
	FROM #TmpDatasets INNER JOIN 
		dbo.T_Dataset DS ON #TmpDatasets.Dataset_Num = DS.Dataset_Num INNER JOIN
		dbo.T_Internal_Standards DSIntStd ON DS.DS_internal_standard_ID = DSIntStd.Internal_Std_Mix_ID INNER JOIN
		dbo.T_Internal_Std_Parent_Mixes ISPM ON DSIntStd.Internal_Std_Parent_Mix_ID = ISPM.Parent_Mix_ID
	WHERE LEN(IsNull(ISPM.Protein_Collection_Name, '')) > 0
	GROUP BY DSIntStd.Internal_Std_Mix_ID, ISPM.Protein_Collection_Name
	UNION
	SELECT DSIntStd.Internal_Std_Mix_ID, ISPM.Protein_Collection_Name, 
		0 AS Dataset_Count, COUNT(DISTINCT E.Exp_ID) AS Experiment_Count, 0 AS Enzyme_Contaminant_Collection
	FROM #TmpDatasets INNER JOIN 
		dbo.T_Dataset DS ON #TmpDatasets.Dataset_Num = DS.Dataset_Num INNER JOIN
		dbo.T_Experiments E ON DS.Exp_ID = E.Exp_ID INNER JOIN
		dbo.T_Internal_Standards DSIntStd ON E.EX_internal_standard_ID = DSIntStd.Internal_Std_Mix_ID INNER JOIN
		dbo.T_Internal_Std_Parent_Mixes ISPM ON DSIntStd.Internal_Std_Parent_Mix_ID = ISPM.Parent_Mix_ID
	WHERE LEN(IsNull(ISPM.Protein_Collection_Name, '')) > 0
	GROUP BY DSIntStd.Internal_Std_Mix_ID, ISPM.Protein_Collection_Name
	UNION
	SELECT DSIntStd.Internal_Std_Mix_ID, ISPM.Protein_Collection_Name, 
		0 AS Dataset_Count, COUNT(DISTINCT E.Exp_ID) AS Experiment_Count, 0 AS Enzyme_Contaminant_Collection
	FROM #TmpDatasets INNER JOIN 
		dbo.T_Dataset DS ON #TmpDatasets.Dataset_Num = DS.Dataset_Num INNER JOIN
		dbo.T_Experiments E ON DS.Exp_ID = E.Exp_ID INNER JOIN
		dbo.T_Internal_Standards DSIntStd ON E.EX_postdigest_internal_std_ID = DSIntStd.Internal_Std_Mix_ID INNER JOIN
		dbo.T_Internal_Std_Parent_Mixes ISPM ON DSIntStd.Internal_Std_Parent_Mix_ID = ISPM.Parent_Mix_ID
	WHERE LEN(IsNull(ISPM.Protein_Collection_Name, '')) > 0
	GROUP BY DSIntStd.Internal_Std_Mix_ID, ISPM.Protein_Collection_Name
	ORDER BY DSIntStd.Internal_Std_Mix_ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	
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
		set @msg = 'Error populating #ProteinCollectionsToAdd with the missing protein collections'
		RAISERROR (@msg, 11, 1)
		return 51006
	End
	
	If @myRowCount > 0 
	Begin -- <a>
		-- New collections were added to #ProteinCollectionsToAdd
		-- Now append them to #ProteinCollections
		-- Note that we first append collections that did not come from digestion enzymes
		--				
		INSERT INTO #ProteinCollections (Protein_Collection_Name, Collection_Appended)
		SELECT Protein_Collection_Name, 1 AS Collection_Appended
		FROM #ProteinCollectionsToAdd
		GROUP BY Enzyme_Contaminant_Collection, Protein_Collection_Name
		ORDER BY Enzyme_Contaminant_Collection, Protein_Collection_Name
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			set @msg = 'Error populating #ProteinCollections with the missing protein collections'
			RAISERROR (@msg, 11, 1)
			return 51008
		End
		
		Set @CollectionCountAdded = @myRowCount

		--------------------------------------------------------------
		-- Collapse #ProteinCollections into @protCollNameList
		-- The Order By statements in this query assure that the 
		--  internal standard collections and contaminant collections 
		--  are listed first and that the original collection order is preserved
		--------------------------------------------------------------
		
		Set @protCollNameList = ''
		SELECT @protCollNameList = @protCollNameList + Protein_Collection_Name + ','
		FROM #ProteinCollections
		ORDER BY Collection_Appended Desc, RowNumberID Asc
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
							set @msg = @msg + Convert(varchar(12), @DatasetCountTotal) + ' dataset'
							If @DatasetCountTotal <> 1
								Set @msg = @msg + 's'
						End -- </e1>
						Else
						Begin -- <e2>
							If @ExperimentCount > 0
							Begin
								Set @msg = @msg + Convert(varchar(12), @ExperimentCount) + ' of '
								set @msg = @msg + Convert(varchar(12), @ExperimentCountTotal) + ' experiment'
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
GRANT VIEW DEFINITION ON [dbo].[ValidateProteinCollectionListForDatasets] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateProteinCollectionListForDatasets] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateProteinCollectionListForDatasets] TO [PNL\D3M580] AS [dbo]
GO
