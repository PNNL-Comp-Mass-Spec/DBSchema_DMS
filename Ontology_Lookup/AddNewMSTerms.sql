/****** Object:  StoredProcedure [dbo].[AddNewMSTerms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddNewMSTerms
/****************************************************
**
**	Desc: 
**		Adds new PSI-MS terms to T_CV_MS
**
**		The source table must have columns:
**
**		[Term_PK]
**		[Term_Name]
**		[Identifier
**		[Is_Leaf]
**		[Definition]
**		[Comment]
**		[Parent_term_name]
**		[Parent_term_ID]
**		[GrandParent_term_name]
**		[GrandParent_term_ID]
**
**	Auth:	mem
**	Date:	06/15/2016 mem - Initial Version
**
*****************************************************/
(
	@SourceTableName varchar(24) = 'T_Tmp_PsiMS_2016June',
	@InfoOnly tinyint = 1
)
AS
	Set NoCount On
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @SourceTableName = IsNull(@SourceTableName, '')
	Set @InfoOnly = IsNull(@InfoOnly, 1)
		
	Declare @S varchar(1500) = ''
	Declare @AddNew nvarchar(3000) = ''
	
	If Not Exists (Select * from sys.tables where [name] = @SourceTableName)
	Begin
		Select 'Source table not found: ' + @SourceTableName AS Message
		Goto Done
	End

	---------------------------------------------------
	-- Populate a temporary table with the source data
	-- We do this so we can keep track of which rows match existing entries
	---------------------------------------------------
	
	CREATE TABLE #Tmp_SourceData (
		Entry_ID int identity(1,1),
		[Term_PK] [varchar](32),
		[Term_Name] [varchar](128),
		[Identifier] [varchar](32),
		[Is_Leaf] [smallint],
		[Parent_term_name] [varchar](128) NULL,
		[Parent_term_ID] [varchar](32) NULL,
		[GrandParent_term_name] [varchar](128) NULL,
		[GrandParent_term_ID] [varchar](32) NULL,
		[MatchesExisting] tinyint
	)
	
	Set @S = ''
	Set @S = @S + ' INSERT INTO #Tmp_SourceData( Term_PK, Term_Name, Identifier, Is_Leaf,'
	Set @S = @S +                               ' Parent_term_name, Parent_term_ID, '
	Set @S = @S +                               ' GrandParent_term_name, GrandParent_term_ID, MatchesExisting )'
	Set @S = @S + ' SELECT Term_PK, Term_Name, Identifier, Is_Leaf,'
	Set @S = @S + ' Parent_term_name, Parent_term_ID,'
	Set @S = @S + ' GrandParent_term_name, GrandParent_term_ID, 0 AS MatchesExisting'
	Set @S = @S + ' FROM [' + @SourceTableName + ']'
	Set @S = @S + ' WHERE Parent_term_name <> '''' AND Definition NOT Like ''Obsolete%'' And Comment Not Like ''Obsolete%'' '
	
	DECLARE @GetSourceData nvarchar(3000) = @S
	
	EXEC sp_executesql @GetSourceData
	
	---------------------------------------------------
	-- Replace empty Grandparent term IDs and names with NULL
	---------------------------------------------------
	--	
	UPDATE #Tmp_SourceData
	SET GrandParent_Term_ID = NULL,
	    GrandParent_Term_Name = NULL
	WHERE IsNull(GrandParent_Term_ID, '') = '' AND
	      IsNull(GrandParent_Term_Name, '') = '' AND
	      (GrandParent_Term_ID = '' OR GrandParent_Term_Name = '')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	---------------------------------------------------
	-- Set MatchesExisting to 1 for rows that match an existing row in T_CV_MS
	---------------------------------------------------
	--
	UPDATE #Tmp_SourceData
	SET MatchesExisting = 1
	FROM #Tmp_SourceData s INNER JOIN T_CV_MS t
		ON t.Term_PK = s.Term_PK AND 
			t.Parent_term_ID = s.Parent_term_ID AND 
			ISNULL(t.GrandParent_term_ID, '') = ISNULL(s.GrandParent_term_ID, '')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	---------------------------------------------------
	-- Look for obsolete terms that need to be deleted
	---------------------------------------------------
	--
	Set @S = ''	   
	Set @S = @S + ' SELECT @myRowCount = COUNT(*)'
	Set @S = @S + ' FROM ('
	Set @S = @S +   ' SELECT s.Term_PK, s.Comment, s.Definition'
	Set @S = @S +   ' FROM [' + @SourceTableName + '] s INNER JOIN'
	Set @S = @S +        ' T_CV_MS t ON s.Term_PK = t.Term_PK'
	Set @S = @S +   ' WHERE (s.Parent_term_name = '''') AND '
	Set @S = @S +         ' (s.Definition LIKE ''Obsolete%'' OR s.Comment LIKE ''Obsolete%'')'
	Set @S = @S +   ' UNION' 
	Set @S = @S +   ' SELECT s.Term_PK, s.Comment, s.Definition '
	Set @S = @S +   ' FROM T_CV_MS t INNER JOIN'
	Set @S = @S +      ' (SELECT Term_PK, Parent_term_ID, Comment, Definition'
	Set @S = @S +       ' FROM [' + @SourceTableName + ']'
	Set @S = @S +       ' WHERE Parent_term_name <> '''' AND '
	Set @S = @S +             ' (Definition LIKE ''obsolete%'' OR Comment LIKE ''obsolete%'')'
	Set @S = @S +       ' ) s '
	Set @S = @S +       ' ON t.Term_PK = s.Term_PK AND '
	Set @S = @S +          ' t.Parent_term_ID = s.Parent_term_ID'
	Set @S = @S +   ' ) LookupQ'
		   	
	Declare @FindObsoleteRows nvarchar(3000) = @S
	Declare @DeleteObsolete1 nvarchar(3000) = ''
	Declare @DeleteObsolete2 nvarchar(3000) = ''

	exec sp_executesql @FindObsoleteRows, N'@myRowCount int output', @myRowCount = @myRowCount output

	If @myRowCount > 0
	Begin
		---------------------------------------------------
		-- Obsolete items found
		-- Construct SQL to delete them
		---------------------------------------------------
		--
		Set @S = ''
		Set @S = @S + ' DELETE T_CV_MS'
		Set @S = @S + ' FROM [' + @SourceTableName + '] s INNER JOIN'
		Set @S = @S +      ' T_CV_MS t ON s.Term_PK = t.Term_PK'
		Set @S = @S + ' WHERE (s.Parent_term_name = '''') AND '
		Set @S = @S +       ' (s.Definition LIKE ''Obsolete%'' OR s.Comment LIKE ''Obsolete%'')'
		
		Set @DeleteObsolete1 = @S
		
		Set @S = ''
		Set @S = @S + ' DELETE T_CV_MS'
		Set @S = @S + ' FROM T_CV_MS t INNER JOIN'
		Set @S = @S +    ' (SELECT Term_PK, Parent_term_ID'
		Set @S = @S +     ' FROM [' + @SourceTableName + ']'
		Set @S = @S +     ' WHERE Parent_term_name <> '''' AND '
		Set @S = @S +           ' (Definition LIKE ''obsolete%'' OR Comment LIKE ''obsolete%'')'
		Set @S = @S +     ' ) ObsoleteTerms '
		Set @S = @S +     ' ON t.Term_PK = ObsoleteTerms.Term_PK AND '
		Set @S = @S +        ' t.Parent_term_ID = ObsoleteTerms.Parent_term_ID'
		
		Set @DeleteObsolete2 = @S
	End
	
	If @InfoOnly = 0
	Begin
		If @DeleteObsolete1 <> '' OR @DeleteObsolete2 <> ''
		Begin
			---------------------------------------------------
			-- Delete obsolete entries
			---------------------------------------------------
			--
			exec sp_executesql @DeleteObsolete1
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			DECLARE @additionalRows int
			exec sp_executesql @DeleteObsolete2
			--
			SELECT @myError = @@error, @additionalRows = @@rowcount
			
			Set @myRowCount = @myRowCount + @additionalRows			
			SELECT 'Deleted ' + Cast(@myRowCount as varchar(9)) + ' obsolete rows in T_CV_MS based on entries in ' + @SourceTableName AS Message
		End
		
		---------------------------------------------------
		-- Update existing rows
		---------------------------------------------------
		--
		MERGE T_CV_MS AS t
		USING (SELECT Term_PK, Term_Name, Identifier, Is_Leaf, 
			          Parent_term_name, Parent_term_ID, 
			          GrandParent_term_name, GrandParent_term_ID
			   FROM #Tmp_SourceData
			   WHERE MatchesExisting = 1) as s
		ON ( t.Term_PK = s.Term_PK AND 
			 t.Parent_term_ID = s.Parent_term_ID AND 
			 ISNULL(t.GrandParent_term_ID, '') = ISNULL(s.GrandParent_term_ID, ''))
		WHEN MATCHED AND (
			t.[Term_Name] <> s.[Term_Name] OR
			t.[Identifier] <> s.[Identifier] OR
			t.[Is_Leaf] <> s.[Is_Leaf] OR
			t.[Parent_term_name] <> s.[Parent_term_name] OR
			ISNULL( NULLIF(t.[GrandParent_term_name], s.[GrandParent_term_name]),
					NULLIF(s.[GrandParent_term_name], t.[GrandParent_term_name])) IS NOT NULL
			)
		THEN UPDATE SET 
			[Term_Name] = s.[Term_Name],
			[Identifier] = s.[Identifier],
			[Is_Leaf] = s.[Is_Leaf],
			[Parent_term_name] = s.[Parent_term_name],
			[GrandParent_term_ID] = s.[GrandParent_term_ID],
			[GrandParent_term_name] = s.[GrandParent_term_name],
			[Updated] = GetDate();
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		SELECT 'Updated ' + Cast(@myRowCount as varchar(9)) + ' rows in T_CV_MS using ' + @SourceTableName AS Message

		---------------------------------------------------
		-- Add new rows
		---------------------------------------------------
		--
		INSERT INTO T_CV_MS (Term_PK, Term_Name, Identifier, Is_Leaf, 
			                 Parent_term_name, Parent_term_ID, 
			                 GrandParent_term_name, GrandParent_term_ID)
		SELECT Term_PK, Term_Name, Identifier, Is_Leaf, 
			   Parent_term_name, Parent_term_ID, 
			   GrandParent_term_name, GrandParent_term_ID
		FROM #Tmp_SourceData
		WHERE MatchesExisting = 0
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		SELECT 'Added ' + Cast(@myRowCount as varchar(9)) + ' new rows to T_CV_MS using ' + @SourceTableName AS Message


	End
	Else
	Begin
		---------------------------------------------------
		-- Preview updates
		---------------------------------------------------
		
		If @DeleteObsolete1 <> '' OR @DeleteObsolete2 <> ''
		Begin
			print '-- Delete Obsolete rows'
			print @DeleteObsolete1
			print @DeleteObsolete2
			
			Set @S = ''
			Set @S = @S + ' SELECT ''Obsolete term to delete'' as Item_Type, s.*, t.Entered, t.updated'
			Set @S = @S + ' FROM [' + @SourceTableName + '] s INNER JOIN'
			Set @S = @S +      ' T_CV_MS t ON s.Term_PK = t.Term_PK'
			Set @S = @S + ' WHERE (s.Definition LIKE ''Obsolete%'' OR s.Comment LIKE ''Obsolete%'')'
			
			Declare @PreviewObsoleteData nvarchar(1000) = @S
			
			Exec sp_executesql @PreviewObsoleteData
			
		End

		---------------------------------------------------
		-- View existing rows that would be updated
		---------------------------------------------------
		--		
		SELECT 'Existing item to update' as Item_Type,
		       t.Entry_ID,
		       t.Term_PK,
		       CASE WHEN t.Term_Name = s.Term_Name THEN t.Term_Name ELSE t.Term_Name + ' --> ' + s.Term_Name END Term_Name,
		       CASE WHEN t.Identifier = s.Identifier THEN t.Identifier ELSE t.Identifier + ' --> ' + s.Identifier END Identifier,
		       CASE WHEN t.Is_Leaf = s.Is_Leaf THEN Cast(t.Is_Leaf AS varchar(16)) ELSE Cast(t.Is_Leaf AS varchar(16)) + ' --> ' + Cast(s.Is_Leaf AS varchar(16)) END Is_Leaf,
		       t.Parent_term_ID,
		       CASE WHEN t.Parent_term_name = s.Parent_term_name THEN t.Parent_term_name ELSE t.Parent_term_name + ' --> ' + s.Parent_term_name END Parent_term_name,
		       t.GrandParent_term_ID,
		       CASE WHEN t.GrandParent_term_name = s.GrandParent_term_name THEN t.GrandParent_term_name ELSE IsNull(t.GrandParent_term_name, 'NULL') + ' --> ' + IsNull(s.GrandParent_term_name, 'NULL') END GrandParent_term_name,
		       t.Entered,
		       t.Updated
		FROM T_CV_MS AS t
		    INNER JOIN #Tmp_SourceData AS s
		      ON t.Term_PK = s.Term_PK AND
		         t.Parent_term_ID = s.Parent_term_ID AND
		         ISNULL(t.GrandParent_term_ID, '') = ISNULL(s.GrandParent_term_ID, '')
		WHERE MatchesExisting=1 AND 
		      ( (t.Term_Name <> s.Term_Name) OR
		        (t.Identifier <> s.Identifier) OR
		        (t.Is_Leaf <> s.Is_Leaf) OR
		        (t.Parent_term_name <> s.Parent_term_name) OR
		        (ISNULL(NULLIF(t.GrandParent_term_name, s.GrandParent_term_name), 
		              NULLIF(s.GrandParent_term_name, t.GrandParent_term_name)) IS NOT NULL)
		       )
		UNION
		SELECT 'New item to add' as Item_Type,
		       0 AS Entry_ID,
		       Term_PK, Term_Name, 
		       Identifier, 
		       Cast(Is_Leaf AS varchar(16)), 
			   Parent_term_ID, 
			   Parent_term_name,
			   GrandParent_term_ID,
			   GrandParent_term_name,
			   Null AS Entered,
		       Null as Updated
		FROM #Tmp_SourceData
		WHERE MatchesExisting = 0
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

	End
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError
GO
