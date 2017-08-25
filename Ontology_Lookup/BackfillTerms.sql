/****** Object:  StoredProcedure [dbo].[BackfillTerms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE BackfillTerms
/****************************************************
**
**	Desc: 
**		Adds new entries to term, term_relationship, and term_synonym using a T_CV table
**
**		This is necessary to add new info to the master term and term_relationship tables after adding
**		new information to a T_CV table, e.g. after adding new BTO terms to T_CV_BTO using a .owl file
**
**	Auth:	mem
**	Date:	08/24/2017 mem - Initial Version
**
*****************************************************/
(
	@sourceTable varchar(24) = 'T_CV_BTO',
	@namespace varchar(128) = 'BrendaTissueOBO',
	@infoOnly tinyint = 1,
	@previewRelationshipUpdates tinyint = 1				-- Set to 1 to preview adding/removing relationships; 0 to actually update relationships
)
AS
	Declare @myError int = 0
	Declare @myRowCount int = 0

	Declare @S varchar(2048) = ''
	Declare @ontologyID int = 0
	
	---------------------------------------------------
	-- Validate inputs
	---------------------------------------------------
	--	
	Set @sourceTable = IsNull(@sourceTable, '')
	Set @infoOnly = IsNull(@infoOnly, 1)
	Set @previewRelationshipUpdates = IsNull(@previewRelationshipUpdates, 1)
	
	---------------------------------------------------
	-- Validate the that the source table exists
	---------------------------------------------------
	--
	If Not Exists (Select * From sys.tables where name = @sourceTable)
	Begin
		SELECT 'Source table not found: ' + @sourceTable
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
		[Synonyms] varchar(900),			-- Only used if the source is 'T_CV_BTO'
		[Parent_term_name] varchar(128) NULL,
		[Parent_term_ID] varchar(32) NULL,
		[GrandParent_term_name] varchar(128) NULL,
		[GrandParent_term_ID] varchar(32) NULL,
		[MatchesExisting] tinyint
	)
	
	Set @S = ''
	Set @S = @S + ' INSERT INTO #Tmp_SourceData( Term_PK, Term_Name, Identifier, Is_Leaf,'
	If @sourceTable = 'T_CV_BTO'
		Set @S = @S + ' Synonyms,'

	Set @S = @S +                               ' Parent_term_name, Parent_term_ID, '
	Set @S = @S +                               ' GrandParent_term_name, GrandParent_term_ID, MatchesExisting )'
	Set @S = @S + ' SELECT Term_PK, Term_Name, Identifier, Is_Leaf, '
	If @sourceTable = 'T_CV_BTO'
		Set @S = @S + ' Synonyms,'
		
	Set @S = @S + '   Parent_term_name, Parent_term_ID,'
	Set @S = @S + '   GrandParent_term_name, GrandParent_term_ID, 0 AS MatchesExisting'
	Set @S = @S + ' FROM [' + @sourceTable + ']'
	Set @S = @S + ' WHERE Parent_term_name <> '''' '
	
	DECLARE @GetSourceData nvarchar(3000) = @S
	
	EXEC sp_executesql @GetSourceData
		
	---------------------------------------------------
	-- Set MatchesExisting to 1 for rows that match an existing row in term
	---------------------------------------------------
	--
	UPDATE #Tmp_SourceData
	SET MatchesExisting = 1
	FROM #Tmp_SourceData s INNER JOIN term t
		ON t.term_pk = s.Term_PK
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	---------------------------------------------------
	-- Determine the ontology_id
	---------------------------------------------------
	--
	SELECT TOP 1 @ontologyID = t.ontology_id
	FROM #Tmp_SourceData s
	     INNER JOIN term t
	       ON s.Term_PK = t.term_pk
	GROUP BY t.ontology_id
	ORDER BY Count(*) DESC
	
	If @infoOnly = 0
	Begin

		---------------------------------------------------
		-- Update existing rows
		---------------------------------------------------
		--
		MERGE term AS t
		USING (SELECT Term_PK, Term_Name, Identifier, MAX(Is_Leaf) AS Is_Leaf
			   FROM #Tmp_SourceData SourceTable
			   WHERE MatchesExisting = 1
			   GROUP BY Term_PK, Term_Name, Identifier ) as s
		ON ( t.Term_PK = s.Term_PK )
		WHEN MATCHED AND (
			t.[Term_Name] <> s.[Term_Name] OR
			t.[Identifier] <> s.[Identifier] OR
			t.[Is_Leaf] <> s.[Is_Leaf]
			)
		THEN UPDATE SET 
			[Term_Name] = s.[Term_Name],
			[Identifier] = s.[Identifier],
			[Is_Leaf] = s.[Is_Leaf],
			[Updated] = GetDate();
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		SELECT 'Updated ' + Cast(@myRowCount as varchar(9)) + ' rows in term using ' + @sourceTable AS Message

		---------------------------------------------------
		-- Add new rows
		---------------------------------------------------
		--
		INSERT INTO term (term_pk, ontology_id, term_name, identifier, definition, namespace, is_obsolete, is_root_term, is_leaf)
		SELECT Term_PK, @ontologyID, Term_Name, Identifier, '' as Definition, @namespace, 0 as is_obsolete, 0 as i_root_term, Max(Is_Leaf)
		FROM #Tmp_SourceData
		WHERE MatchesExisting = 0
		GROUP BY Term_PK, Term_Name, Identifier
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		SELECT 'Added ' + Cast(@myRowCount as varchar(9)) + ' new rows to term using ' + @sourceTable AS Message


		---------------------------------------------------
		-- Add/update parent/child relationships
		---------------------------------------------------				
		
		CREATE TABLE #Tmp_RelationshipsToAdd (
			Entry_ID int not null identity(1,1),
			Child_PK varchar(32) not null,
			Parent_PK varchar(32) not null
		)
	
		CREATE TABLE #Tmp_RelationshipsToDelete (
			Relationship_ID int not null
		)
			
		-- Find missing relationships
		--
		INSERT INTO #Tmp_RelationshipsToAdd (Child_PK, Parent_PK)
		SELECT DISTINCT SourceTable.Term_PK AS Child_PK,
		                term.term_pk AS Parent_PK
		FROM T_CV_BTO SourceTable
		     INNER JOIN term
		       ON SourceTable.Parent_term_ID = term.identifier
		     LEFT OUTER JOIN term_relationship
		       ON SourceTable.Term_PK = term_relationship.subject_term_pk AND
		          term.term_pk = term_relationship.object_term_pk
		WHERE term.ontology_id = @ontologyID AND
		      term_relationship.subject_term_pk IS NULL
		ORDER BY SourceTable.Term_PK, term.term_pk
		

		-- Determine the smallest ID in table term_relationship
		--
		Declare @autoNumberStartID int = 0
		
		SELECT @autoNumberStartID = MIN(term_relationship_id) - 1
		FROM term_relationship
					
		IF @autoNumberStartID >= 0
			Set @autoNumberStartID = -1		
			
		
		If @previewRelationshipUpdates > 0
		Begin
			SELECT 'New Relationship' as Action,
			    @autoNumberStartID - Entry_ID AS New_Relationship_ID,
				Child_PK,
				'inferred_is_a' AS Predicate_Name,
				Parent_PK,
				@ontologyID
			FROM #Tmp_RelationshipsToAdd
			ORDER BY Entry_ID
		End
		Else
		Begin
			-- Add missing relationships
			--
			INSERT INTO term_relationship( term_relationship_id,
			                               subject_term_pk,
			                               predicate_term_pk,
			                               object_term_pk,
			                               ontology_id )
			SELECT @autoNumberStartID - Entry_ID AS New_Relationship_ID,
			       Child_PK,
			       'inferred_is_a' AS Predicate_Name,
			       Parent_PK,
			       @ontologyID
			FROM #Tmp_RelationshipsToAdd
			ORDER BY Entry_ID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			SELECT 'Inserted ' + Cast(@myRowCount as varchar(9)) + ' new parent/child relationships into table term_relationship' AS Message
		End
		
		--
		-- Find extra relationships
		--	
		INSERT INTO #Tmp_RelationshipsToDelete( Relationship_ID )
		SELECT term_relationship.term_relationship_id
		FROM ( SELECT DISTINCT SourceTable.Identifier,
		                       SourceTable.Term_PK AS Child_PK,
		                       SourceTable.Parent_term_ID,
		                       term.term_pk AS Parent_PK
		       FROM T_CV_BTO SourceTable
		            INNER JOIN term
		              ON SourceTable.Parent_term_ID = term.identifier
		       WHERE (term.ontology_id = @ontologyID) ) ValidRelationships
		     RIGHT OUTER JOIN term_relationship
		       ON ValidRelationships.Child_PK = term_relationship.subject_term_pk 
		          AND
		          ValidRelationships.Parent_PK = term_relationship.object_term_pk
		WHERE (ValidRelationships.Parent_term_ID IS NULL) AND
		      (term_relationship.ontology_id = @ontologyID)
		
		If @previewRelationshipUpdates > 0
		Begin
			SELECT 'Delete relationship' as Action, *
			FROM term_relationship
			WHERE term_relationship_id IN (Select Relationship_ID FROM #Tmp_RelationshipsToDelete)			
		End
		Else
		Begin
			DELETE term_relationship
			WHERE term_relationship_id IN (Select Relationship_ID FROM #Tmp_RelationshipsToDelete)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			SELECT 'Deleted ' + Cast(@myRowCount as varchar(9)) + ' parent/child relationships in table term_relationship' AS Message
		End
		
	End

	Else
	Begin
		---------------------------------------------------
		-- Preview existing rows that would be updated
		---------------------------------------------------
		--		
		SELECT 'Existing item to update' as Item_Type,
		       t.Term_PK,
		       CASE WHEN t.Term_Name = s.Term_Name THEN t.Term_Name ELSE t.Term_Name + ' --> ' + s.Term_Name END Term_Name,
		       CASE WHEN t.Identifier = s.Identifier THEN t.Identifier ELSE t.Identifier + ' --> ' + s.Identifier END Identifier,
		       CASE WHEN t.Is_Leaf = s.Is_Leaf THEN Cast(t.Is_Leaf AS varchar(16)) ELSE Cast(t.Is_Leaf AS varchar(16)) + ' --> ' + Cast(s.Is_Leaf AS varchar(16)) END Is_Leaf,
		       t.Updated
		FROM term AS t
		     INNER JOIN ( SELECT Term_PK,
		                         Term_Name,
		                         Identifier,
		                         MAX(Is_Leaf) AS Is_Leaf
		                  FROM #Tmp_SourceData SourceTable
		                  WHERE MatchesExisting = 1
		                  GROUP BY Term_PK, Term_Name, Identifier ) AS s
		       ON t.Term_PK = s.Term_PK
		WHERE ((t.Term_Name <> s.Term_Name) OR
		       (t.Identifier <> s.Identifier) OR
		       (t.Is_Leaf <> s.Is_Leaf)
		      )
		UNION
		SELECT 'New item to add' as Item_Type,
		       Term_PK, 
		       Term_Name, 
		       Identifier, 
		       Cast(Max(Is_Leaf) AS varchar(16)), 
		       Null as Updated
		FROM #Tmp_SourceData
		WHERE MatchesExisting = 0
		GROUP BY Term_PK, Term_Name, Identifier
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount


		---------------------------------------------------
		-- Preview parents to add
		---------------------------------------------------
		--	
		/*
		SELECT DISTINCT 'Missing parent/child relationship' as Relationship
		                SourceTable.Identifier AS Child,
		                SourceTable.Term_PK AS Child_PK,
		                SourceTable.Parent_term_ID AS Parent,
		                term.term_pk AS Parent_PK
		FROM T_CV_BTO SourceTable
		     INNER JOIN term
		       ON SourceTable.Parent_term_ID = term.identifier
		     LEFT OUTER JOIN term_relationship
		       ON SourceTable.Term_PK = term_relationship.subject_term_pk AND
		          term.term_pk = term_relationship.object_term_pk
		WHERE (term.ontology_id = @ontologyID) AND
		      (term_relationship.subject_term_pk IS NULL)
		ORDER BY SourceTable.Identifier
		*/
	End


	---------------------------------------------------
	-- exit
	---------------------------------------------------
	--
Done:
	return @myError
GO
