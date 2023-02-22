/****** Object:  StoredProcedure [dbo].[AddNewBTOTerms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddNewBTOTerms
/****************************************************
**
**	Desc: 
**		Adds new BTO terms to T_CV_BTO
**
**		The source table must have columns:
**
**		[Term_PK]
**		[Term_Name]
**		[Identifier
**		[Is_Leaf]
**		[Synonyms]
**		[Parent_term_name]
**		[Parent_term_ID]
**		[GrandParent_term_name]
**		[GrandParent_term_ID]
**
**	Auth:	mem
**	Date:	08/24/2017 mem - Initial Version
**
*****************************************************/
(
	@sourceTable varchar(24) = 'T_Tmp_BTO',
	@infoOnly tinyint = 1,
	@previewDeleteExtras tinyint = 1				-- Set to 1 to preview deleting extra terms; 0 to actually delete them
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
	
	Set @sourceTable = IsNull(@sourceTable, '')
	Set @infoOnly = IsNull(@infoOnly, 1)
	Set @previewDeleteExtras = IsNull(@previewDeleteExtras, 1)
	
	Declare @S varchar(1500) = ''
	Declare @AddNew nvarchar(3000) = ''
	
	If Not Exists (Select * from sys.tables where [name] = @sourceTable)
	Begin
		Select 'Source table not found: ' + @sourceTable AS Message
		Goto Done
	End

	---------------------------------------------------
	-- Populate a temporary table with the source data
	-- We do this so we can keep track of which rows match existing entries
	---------------------------------------------------
	
	CREATE TABLE #Tmp_SourceData (
		Entry_ID int identity(1,1),
		[Term_PK] varchar(32),
		[Term_Name] varchar(128),
		[Identifier] varchar(32),
		[Is_Leaf] [smallint],
		[Synonyms] varchar(900),
		[Parent_term_name] varchar(128) NULL,
		[Parent_term_ID] varchar(32) NULL,
		[GrandParent_term_name] varchar(128) NULL,
		[GrandParent_term_ID] varchar(32) NULL,
		[MatchesExisting] tinyint
	)
	
	Set @S = ''
	Set @S = @S + ' INSERT INTO #Tmp_SourceData( Term_PK, Term_Name, Identifier, Is_Leaf, Synonyms,'
	Set @S = @S +                               ' Parent_term_name, Parent_term_ID, '
	Set @S = @S +                               ' GrandParent_term_name, GrandParent_term_ID, MatchesExisting )'
	Set @S = @S + ' SELECT Term_PK, Term_Name, Identifier, Is_Leaf, Synonyms,'
	Set @S = @S + '   Parent_term_name, Parent_term_ID,'
	Set @S = @S + '   GrandParent_term_name, GrandParent_term_ID, 0 AS MatchesExisting'
	Set @S = @S + ' FROM [' + @sourceTable + ']'
	Set @S = @S + ' WHERE Parent_term_name <> '''' '
	
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
	-- Set MatchesExisting to 1 for rows that match an existing row in T_CV_BTO
	---------------------------------------------------
	--
	UPDATE #Tmp_SourceData
	SET MatchesExisting = 1
	FROM #Tmp_SourceData s INNER JOIN T_CV_BTO t
		ON t.Term_PK = s.Term_PK AND 
			t.Parent_term_ID = s.Parent_term_ID AND 
			ISNULL(t.GrandParent_term_ID, '') = ISNULL(s.GrandParent_term_ID, '')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
    
	If @infoOnly = 0
	Begin -- <a1>

		---------------------------------------------------
		-- Update existing rows
		---------------------------------------------------
		--
		MERGE T_CV_BTO AS t
		USING (SELECT Term_PK, Term_Name, Identifier, Is_Leaf, Synonyms, 
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
			t.[Synonyms] <> s.[Synonyms] OR
			t.[Parent_term_name] <> s.[Parent_term_name] OR
			ISNULL( NULLIF(t.[GrandParent_term_name], s.[GrandParent_term_name]),
					NULLIF(s.[GrandParent_term_name], t.[GrandParent_term_name])) IS NOT NULL
			)
		THEN UPDATE SET 
			[Term_Name] = s.[Term_Name],
			[Identifier] = s.[Identifier],
			[Is_Leaf] = s.[Is_Leaf],
			[Synonyms] = s.[Synonyms],
			[Parent_term_name] = s.[Parent_term_name],
			[GrandParent_term_ID] = s.[GrandParent_term_ID],
			[GrandParent_term_name] = s.[GrandParent_term_name],
			[Updated] = GetDate();
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		SELECT 'Updated ' + Cast(@myRowCount as varchar(9)) + ' rows in T_CV_BTO using ' + @sourceTable AS Message


		---------------------------------------------------
		-- Add new rows
		---------------------------------------------------
		--
		INSERT INTO T_CV_BTO (Term_PK, Term_Name, Identifier, Is_Leaf, Synonyms,
			                 Parent_term_name, Parent_term_ID, 
			                 GrandParent_term_name, GrandParent_term_ID)
		SELECT Term_PK, Term_Name, Identifier, Is_Leaf, Synonyms,
			   Parent_term_name, Parent_term_ID, 
			   GrandParent_term_name, GrandParent_term_ID
		FROM #Tmp_SourceData
		WHERE MatchesExisting = 0
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		SELECT 'Added ' + Cast(@myRowCount as varchar(9)) + ' new rows to T_CV_BTO using ' + @sourceTable AS Message


		---------------------------------------------------
		-- Look for identifiers with invalid term names
		---------------------------------------------------
		--
		CREATE TABLE #Tmp_InvalidTermNames (
		    Entry_ID   int not null IDENTITY (1,1),
		    Identifier varchar(32) not null,
		    Term_Name  varchar(128) not null 
		)

		CREATE TABLE #Tmp_IDsToDelete (
			Entry_ID int NOT NULL
		)
	
		CREATE CLUSTERED INDEX #IX_Tmp_IDsToDelete ON #Tmp_IDsToDelete (Entry_ID)
		
		INSERT INTO #Tmp_InvalidTermNames( Identifier,
		                                   Term_Name )
		SELECT UniqueQTarget.Identifier,
		       UniqueQTarget.Term_Name AS Invalid_Term_Name_to_Delete
		FROM ( SELECT DISTINCT Identifier, Term_Name FROM T_CV_BTO GROUP BY Identifier, Term_Name ) UniqueQTarget
		     LEFT OUTER JOIN 
		     ( SELECT DISTINCT Identifier, Term_Name FROM #Tmp_SourceData ) UniqueQSource
		       ON UniqueQTarget.Identifier = UniqueQSource.Identifier AND
		          UniqueQTarget.Term_Name = UniqueQSource.Term_Name
		WHERE UniqueQTarget.Identifier IN ( SELECT Identifier
		                                     FROM ( SELECT DISTINCT Identifier, Term_Name
		                                            FROM T_CV_BTO
		                                            GROUP BY Identifier, Term_Name ) LookupQ
		                                     GROUP BY Identifier
		                                     HAVING (COUNT(*) > 1) ) AND
		      UniqueQSource.Identifier IS NULL
		      
		If Exists (Select * From #Tmp_InvalidTermNames)
		Begin -- <b>
			Select 'Extra term name to delete' as Action, *
			FROM #Tmp_InvalidTermNames
			
			INSERT INTO #Tmp_IDsToDelete (Entry_ID)			
			SELECT target.Entry_ID
			FROM T_CV_BTO target
			     INNER JOIN #Tmp_InvalidTermNames source
			       ON target.Identifier = source.Identifier AND
			          target.Term_Name = source.Term_Name
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
				
			If @previewDeleteExtras > 0
			Begin
				SELECT 'To be deleted' as Action, *
				FROM T_CV_BTO
				WHERE Entry_ID IN ( SELECT Entry_ID
				                    FROM #Tmp_IDsToDelete )

			End
			Else
			Begin -- <c>
				Declare @entryID int = 0
				Declare @continue tinyint = 1
				Declare @identifier varchar(32)
				Declare @termName varchar(128)
				
				While @continue > 0
				Begin -- <d>
					SELECT TOP 1 @entryID = Entry_ID,
								@identifier = Identifier,
								@termName = Term_Name
					FROM #Tmp_InvalidTermNames
					WHERE Entry_ID > @entryID
					ORDER BY Entry_ID
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount
					
					If @myRowCount = 0
					Begin
						Set @continue = 0
					End
					Else
					Begin-- <e>
						If Exists (Select * FROM T_CV_BTO WHERE Identifier = @identifier AND Not Entry_ID IN (Select Entry_ID FROM #Tmp_IDsToDelete))
						Begin
							-- Safe to delete
							DELETE FROM T_CV_BTO
							WHERE Identifier = @identifier AND Term_Name = @termName
							--
							SELECT @myError = @@error, @myRowCount = @@rowcount
							
							Print 'Deleted ' + Cast(@myRowCount as varchar(9)) + ' row(s) for ID ' + @identifier + ' and term ' + @termName
						End
						Else
						Begin
							-- Not safe to delete
							SELECT 'Will not delete term ' + @termName + ' for ID ' + @identifier + ' since no entries would remain for this ID' as Error
						End
					End -- </e>

				End -- </d>
			End -- </c>
		End -- </b>
		
		
		---------------------------------------------------
		-- Update the Children counts
		---------------------------------------------------
		--
		UPDATE T_CV_BTO
		SET Children = StatsQ.Children
		FROM T_CV_BTO Target
		     INNER JOIN ( SELECT Parent_term_ID, COUNT(*) AS Children
		                  FROM T_CV_BTO
		                  GROUP BY Parent_term_ID ) StatsQ
		       ON Target.Identifier = StatsQ.Parent_Term_ID
		WHERE IsNull(Target.Children, 0) <> StatsQ.Children
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		-- Change counts to null if no children
		--
		UPDATE T_CV_BTO
		SET Children = NULL
		FROM T_CV_BTO Target
		     LEFT OUTER JOIN ( SELECT Parent_term_ID, COUNT(*) AS Children
		                       FROM T_CV_BTO
		                       GROUP BY Parent_term_ID ) StatsQ
		       ON Target.Identifier = StatsQ.Parent_Term_ID
		WHERE StatsQ.Parent_term_ID IS NULL AND
		      NOT Target.Children IS NULL
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		     
	End -- </a1>
	Else
	Begin -- <a2>
		---------------------------------------------------
		-- Preview existing rows that would be updated
		---------------------------------------------------
		--		
		SELECT 'Existing item to update' as Item_Type,
		       t.Entry_ID,
		       t.Term_PK,
		       CASE WHEN t.Term_Name = s.Term_Name THEN t.Term_Name ELSE t.Term_Name + ' --> ' + s.Term_Name END Term_Name,
		       CASE WHEN t.Identifier = s.Identifier THEN t.Identifier ELSE t.Identifier + ' --> ' + s.Identifier END Identifier,
		       CASE WHEN t.Is_Leaf = s.Is_Leaf THEN Cast(t.Is_Leaf AS varchar(16)) ELSE Cast(t.Is_Leaf AS varchar(16)) + ' --> ' + Cast(s.Is_Leaf AS varchar(16)) END Is_Leaf,
		       CASE WHEN t.Synonyms = s.Synonyms THEN t.Synonyms ELSE t.Synonyms + ' --> ' + s.Synonyms END Synonyms,		       
		       t.Parent_term_ID,
		       CASE WHEN t.Parent_term_name = s.Parent_term_name THEN t.Parent_term_name ELSE t.Parent_term_name + ' --> ' + s.Parent_term_name END Parent_term_name,
		       t.GrandParent_term_ID,
		       CASE WHEN t.GrandParent_term_name = s.GrandParent_term_name THEN t.GrandParent_term_name ELSE IsNull(t.GrandParent_term_name, 'NULL') + ' --> ' + IsNull(s.GrandParent_term_name, 'NULL') END GrandParent_term_name,
		       t.Entered,
		       t.Updated
		FROM T_CV_BTO AS t
		    INNER JOIN #Tmp_SourceData AS s
		      ON t.Term_PK = s.Term_PK AND
		         t.Parent_term_ID = s.Parent_term_ID AND
		         ISNULL(t.GrandParent_term_ID, '') = ISNULL(s.GrandParent_term_ID, '')
		WHERE MatchesExisting=1 AND 
		      ( (t.Term_Name <> s.Term_Name) OR
		        (t.Identifier <> s.Identifier) OR
		        (t.Is_Leaf <> s.Is_Leaf) OR
		        (t.Synonyms <> s.Synonyms) OR
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
		       Synonyms,
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

	End -- </a2>

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError
GO
