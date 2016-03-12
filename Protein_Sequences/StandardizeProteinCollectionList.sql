/****** Object:  StoredProcedure [dbo].[StandardizeProteinCollectionList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.StandardizeProteinCollectionList
/****************************************************
**
**	Desc:
**    Standardizes the order of protein collection names
**     in a protein collection list, returning them in a 
**	   canonical format such that internal_standard
**	   collections (type 5) are listed first, and then the
**	   remaining collections are listed alphabetically.
**
**	  Note that this procedure does not validate the protein 
**	   collection names vs. those in T_Protein_Collections, 
**	   though it will correct capitalization errors
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	06/08/2006
**			08/11/2006 mem - Updated to place contaminants collections at the end of the list
**			10/04/2007 mem - Increased @protCollNameList from varchar(2048) to varchar(max)
**			06/24/2013 mem - Now removing duplicate protein collection names in @protCollNameList
**    
*****************************************************/
(
    @protCollNameList varchar(max) output,
	@message varchar(512)='' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	-- Check for Null values
	SET @protCollNameList = ISNULL(@protCollNameList, '')
	
	Declare @ProtCollNameListNew varchar(max)
	Set @ProtCollNameListNew = ''

	---------------------------------------------------
	-- Populate a temporary table with the protein collections 
	-- in @protCollNameList
	---------------------------------------------------
	If Not @protCollNameList IN ('', 'na')
	Begin
		CREATE TABLE #TmpProteinCollections (
			Unique_ID int identity(1,1) NOT NULL,
			Collection_Name varchar(512) NOT NULL,
			Collection_Type_ID int NOT NULL DEFAULT 1
		)

		-- Split @protCollNameList on commas and populate #TmpProteinCollections
		INSERT INTO #TmpProteinCollections (Collection_Name)
		SELECT DISTINCT LTrim(RTrim(Value))
		FROM dbo.udfParseDelimitedList(@protCollNameList, ',')
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error

		-- Make sure no zero-length records are present in #TmpProteinCollections
		DELETE FROM #TmpProteinCollections
		WHERE Len(Collection_Name) = 0
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
		-- Determine the Collection_Type_ID values for the entries in #TmpProteinCollections
		-- Additionally, correct any capitalization errors
		UPDATE #TmpProteinCollections
		SET Collection_Type_ID = PCT.Collection_Type_ID,
			Collection_Name = PC.FileName
		FROM #TmpProteinCollections TempPC INNER JOIN
			T_Protein_Collections PC ON TempPC.Collection_Name = PC.FileName INNER JOIN
			T_Protein_Collection_Types PCT ON PC.Collection_Type_ID = PCT.Collection_Type_ID
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
		-- Populate @ProtCollNameListNew with any entries having Collection_Type_ID = 5
		SELECT @ProtCollNameListNew = @ProtCollNameListNew + Collection_Name + ',' 
		FROM #TmpProteinCollections
		WHERE Collection_Type_ID = 5
		ORDER BY Collection_Name
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error

		-- Now populate @ProtCollNameListNew with any entries having Collection_Type_ID <> 4 and <> 5
		SELECT @ProtCollNameListNew = @ProtCollNameListNew + Collection_Name + ',' 
		FROM #TmpProteinCollections
		WHERE Collection_Type_ID NOT IN (4,5)
		ORDER BY Collection_Name
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error

		-- Now populate @ProtCollNameListNew with any entries having Collection_Type_ID = 4
		SELECT @ProtCollNameListNew = @ProtCollNameListNew + Collection_Name + ',' 
		FROM #TmpProteinCollections
		WHERE Collection_Type_ID = 4
		ORDER BY Collection_Name
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error

		-- Remove the trailing comma from @ProtCollNameListNew
		If Len(@ProtCollNameListNew) > 0
			Set @ProtCollNameListNew = Left(@ProtCollNameListNew, Len(@ProtCollNameListNew)-1)

		-- Compare @ProtCollNameListNew to @protCollNameList to see if they differ
		If Replace(@protCollNameList, ' ', '') <> @ProtCollNameListNew
			Set @message = 'Protein collection list order has been standardized'
			
		-- Copy to @protCollNameList
		Set @protCollNameList = @ProtCollNameListNew
	End
	
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[StandardizeProteinCollectionList] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StandardizeProteinCollectionList] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StandardizeProteinCollectionList] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
