/****** Object:  StoredProcedure [dbo].[AddNewTerms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddNewTerms
/****************************************************
**
**	Desc: 
**		Adds new ontology terms to the ontology-specific table
**		For example, if @OntologyName is 'NEWT' then will update table T_CV_NEWT
**
**	Auth:	mem
**	Date:	05/13/2013 mem - Initial Version
**
*****************************************************/
(
	@OntologyName varchar(24) = 'PSI',	-- Examples: NEWT, MS, MOD, or PRIDE; used to find identifiers
	@InfoOnly tinyint = 0,
	@PreviewSql tinyint= 0
)
AS
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @TargetTable varchar(32) = 'T_CV_' + @OntologyName
	Declare @InsertSql varchar(1024) = ''
	Declare @S varchar(2048) = ''
	
	---------------------------------------------------
	-- Validate the ontology name
	---------------------------------------------------
	--
	If Not Exists (select top 1 * from V_Term_Lineage where ontology=@OntologyName)
	Begin
		SELECT 'Invalid ontology name: ' + @OntologyName + '; not found in V_Term_Lineage' AS Error_Message
		Goto Done
	End
	
	---------------------------------------------------
	-- Ontology PSI is superseded by PSI_MS
	-- Do not allow processing of the 'PSI' ontology
	---------------------------------------------------
	--
	If @OntologyName = 'PSI'
	Begin
		SELECT 'Ontology PSI is superseded by MS (aka PSI_MS); creation of table T_CV_PSI is not allowed' AS Error_Message
		Goto Done
	End
	
	---------------------------------------------------
	-- Create the target table, if necessary
	---------------------------------------------------
	--
	If Not Exists (Select * from sys.tables Where Name = @TargetTable)
	Begin

		Set @S = ''
		Set @S = @S + ' CREATE TABLE ' + @TargetTable + '('
		Set @S = @S +     ' Entry_ID int Identity(1,1) NOT NULL,'
		Set @S = @S +     ' Term_PK varchar(255) NOT NULL,'
		Set @S = @S +     ' Term_Name varchar(255) NOT NULL,'
		Set @S = @S +     ' Identifier varchar(24) NOT NULL,'
		Set @S = @S +     ' Is_Leaf tinyint NOT NULL,'
		Set @S = @S +     ' Parent_term_name varchar(255) NOT NULL,'
		Set @S = @S +     ' Parent_term_ID varchar(24) NOT NULL,'
		Set @S = @S +     ' GrandParent_term_name varchar(255) NULL,'
		Set @S = @S +     ' GrandParent_term_ID varchar(24) NULL'
		Set @S = @S +     ' CONSTRAINT PK_' + @TargetTable + ' PRIMARY KEY NONCLUSTERED '
		Set @S = @S +     ' (Entry_ID ASC)'
		Set @S = @S + ' )'

		If @PreviewSql=1				
			Print @S
		Else
			EXEC (@S)

		SET @S = 'CREATE CLUSTERED INDEX IX_' + @TargetTable + '_Term_Name ON ' + @TargetTable + '(Term_Name ASC)'
		
		If @PreviewSql=1				
			Print @S
		Else
			EXEC (@S)


		SET @S = 'CREATE INDEX IX_' + @TargetTable + '_Parent_Term_Name ON ' + @TargetTable + '(Parent_Term_Name ASC)'
		
		If @PreviewSql=1				
			Print @S
		Else
			EXEC (@S)
			
			
		SET @S = 'CREATE INDEX IX_' + @TargetTable + '_GrandParent_Term_Name ON ' + @TargetTable + '(GrandParent_Term_Name ASC)'
		
		If @PreviewSql=1				
			Print @S
		Else
			EXEC (@S)
			
	End

	---------------------------------------------------
	-- Construct the Insert Into and Select SQL
	---------------------------------------------------
	--
	If @OntologyName = 'NEWT'
	Begin
		-- NEWT identifiers do not start with NEWT
		-- Query V_NEWT_Terms (which in turn queries V_Term_Lineage)
		--
		Set @InsertSql = ' INSERT INTO ' + @TargetTable + ' ( Term_PK, Term_Name, identifier, Is_Leaf, Parent_term_name, Parent_term_ID,  GrandParent_term_name,  GrandParent_term_ID )'
		Set @S = ''
		Set @S = @S + ' SELECT DISTINCT term_pk, term_name, identifier, is_leaf, Parent_term_name, Parent_term_Identifier, GrandParent_term_name, GrandParent_term_Identifier'
		Set @S = @S + ' FROM V_NEWT_Terms'
		Set @S = @S + ' WHERE NOT Parent_term_Identifier Is Null AND NOT identifier IN ( SELECT identifier FROM ' + @TargetTable + ' )'
	End
	Else
	Begin
		-- Other identifiers do start with the ontology name
		-- Directly query V_Term_Lineage
		Set @InsertSql = ' INSERT INTO ' + @TargetTable + ' ( Term_PK, Term_Name, identifier, Is_Leaf, Parent_term_name, Parent_term_ID,  GrandParent_term_name,  GrandParent_term_ID )'
		Set @S = ''
		Set @S = @S + ' SELECT DISTINCT term_pk, term_name, identifier, is_leaf, Parent_term_name, Parent_term_Identifier, GrandParent_term_name, GrandParent_term_Identifier'
		Set @S = @S + ' FROM V_Term_Lineage'
		Set @S = @S + ' WHERE Ontology = ''' + @OntologyName + ''' AND is_obsolete = 0 AND NOT Parent_term_Identifier Is Null AND NOT identifier IN ( SELECT identifier FROM ' + @TargetTable + ' )'   
			
	End
		
	---------------------------------------------------
	-- Add or preview new terms
	---------------------------------------------------
	--
	If @InfoOnly = 0
	Begin		
		If @PreviewSql=1				
			Print @InsertSql + @S
		Else
			Exec (@InsertSql + @S)		-- Add new terms		
	End
	Else
	Begin		
		If @PreviewSql=1				
			Print @S
		Else
			Exec (@S)		-- Preview new terms
	End

	---------------------------------------------------
	-- exit
	---------------------------------------------------
	--
Done:
	return @myError
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewTerms] TO [DDL_Viewer] AS [dbo]
GO
