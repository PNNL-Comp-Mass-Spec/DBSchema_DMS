/****** Object:  StoredProcedure [dbo].[add_new_terms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_new_terms]
/****************************************************
**
**  Desc:
**      Adds new ontology terms to the ontology-specific table
**      For example, if @OntologyName is 'BTO', will append data to table ont.t_cv_bto
**      Does not update existing items
**
**      The data source is V_Term_Lineage, which queries T_Ontology, T_Term, and T_Term_Relationship
**
**  Arguments:
**    @ontologyName   Examples: BTO, MS, MOD, or PRIDE; used to find identifiers
**    @infoOnly       When 1, preview updates
**    @previewSql     When 1, preview the SQL (but do not execute it)
**
**  Auth:   mem
**  Date:   05/13/2013 mem - Initial Version
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          06/08/2024 mem - No longer process BTO, ENVO, MS, or NEWT info; instead, use the ontology specific procedure (e.g. add_new_bto_terms or add_new_newt_terms)
**
*****************************************************/
(
    @ontologyName varchar(24) = 'PSI',  -- Examples: NEWT, MS, MOD, or PRIDE; used to find identifiers
    @infoOnly tinyint = 0,
    @previewSql tinyint= 0
)
AS
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @TargetTable varchar(32) = 'T_CV_' + @OntologyName
    Declare @InsertSql varchar(1024) = ''
    Declare @S varchar(2048) = ''

    ---------------------------------------------------
    -- Ontology PSI is superseded by PSI_MS
    -- Do not allow processing of the 'PSI' ontology
    ---------------------------------------------------

    If @OntologyName = 'PSI'
    Begin
        SELECT 'Ontology PSI is superseded by MS (aka PSI_MS); creation of table T_CV_PSI is not allowed' AS Error_Message
        Goto Done
    End

    If @ontologyName In ('BTO', 'ENVO', 'MS', 'NEWT')
    Begin
        SELECT 'Use procedure "add_new_' + Lower(@ontologyName) + '_terms" to add ' + @ontologyName + ' terms' AS Error_Message
        Goto Done
    End

    If Not Exists (SELECT TOP 1 ontology FROM V_Term_Lineage WHERE ontology = @OntologyName)
    Begin
        SELECT 'Invalid ontology name: ' + @OntologyName + '; not found in V_Term_Lineage' AS Error_Message
        Goto Done
    End

    ---------------------------------------------------
    -- Create the target table, if necessary
    ---------------------------------------------------

    If Not Exists (SELECT * from sys.tables WHERE Name = @TargetTable)
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

    /*
     * Deprecated in June 2024; instead, use ont.add_new_newt_terms

    If @OntologyName = 'NEWT'
    Begin
        -- NEWT identifiers do not start with NEWT
        -- Query V_NEWT_Terms (which in turn queries V_Term_Lineage)

        Set @InsertSql = ' INSERT INTO ' + @TargetTable + ' ( Term_PK, Term_Name, identifier, Is_Leaf, Parent_term_name, Parent_term_ID,  GrandParent_term_name,  GrandParent_term_ID )'
        Set @S = ''
        Set @S = @S + ' SELECT DISTINCT term_pk, term_name, identifier, is_leaf, Parent_term_name, Parent_term_Identifier, GrandParent_term_name, GrandParent_term_Identifier'
        Set @S = @S + ' FROM V_NEWT_Terms'
        Set @S = @S + ' WHERE NOT Parent_term_Identifier Is Null AND NOT identifier IN ( SELECT identifier FROM ' + @TargetTable + ' )'
    End
    */

    -- Identifiers start with the ontology name
    -- Directly query V_Term_Lineage

    Set @InsertSql = ' INSERT INTO ' + @TargetTable + ' ( Term_PK, Term_Name, identifier, Is_Leaf, Parent_term_name, Parent_term_ID,  GrandParent_term_name,  GrandParent_term_ID )'
    Set @S = ''
    Set @S = @S + ' SELECT DISTINCT term_pk, term_name, identifier, is_leaf, Parent_term_name, Parent_term_Identifier, GrandParent_term_name, GrandParent_term_Identifier'
    Set @S = @S + ' FROM V_Term_Lineage'
    Set @S = @S + ' WHERE Ontology = ''' + @OntologyName + ''' AND is_obsolete = 0 AND NOT Parent_term_Identifier Is Null AND NOT identifier IN ( SELECT identifier FROM ' + @TargetTable + ' )'

    ---------------------------------------------------
    -- Add or preview new terms
    ---------------------------------------------------

    If @InfoOnly = 0
    Begin
        If @PreviewSql=1
            Print @InsertSql + @S
        Else
            Exec (@InsertSql + @S)      -- Add new terms
    End
    Else
    Begin
        If @PreviewSql=1
            Print @S
        Else
            Exec (@S)       -- Preview new terms
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_new_terms] TO [DDL_Viewer] AS [dbo]
GO
