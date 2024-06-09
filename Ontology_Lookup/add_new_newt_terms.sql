/****** Object:  StoredProcedure [dbo].[add_new_newt_terms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_new_newt_terms]
/****************************************************
**
**  Desc:
**      Adds/updates NEWT terms in T_CV_NEWT
**
**      The source table for T_CV_NEWT must have these columns:
**        Term_PK
**        Term_Name
**        Identifier             (integer)
**        Is_Leaf
**        Rank
**        Parent_Term_Name
**        Parent_Term_ID         (integer)
**        Grandparent_Term_Name
**        Grandparent_Term_ID    (integer)
**        Common_Name
**        Synonym
**        Mnemonic
**
**  Arguments:
**    @sourceTable          Source table name
**    @infoOnly             When true, preview updates
**    @previewDeleteExtras  When true, preview the rows that would be deleted from t_cv_newt (ignored if _infoOnly is true)
**
**  Example usage:
**        EXEC add_new_newt_terms @infoOnly = 1;
**        EXEC add_new_newt_terms @infoOnly = 0, @previewDeleteExtras = 1;
**        EXEC add_new_newt_terms @infoOnly = 0, @previewDeleteExtras = 0;
**
**  Auth:   mem
**  Date:   06/06/2024 mem - Initial Version (based on add_new_envo_terms)
**          06/07/2024 mem - Change parent and grandparent term ID columns to integers
**
*****************************************************/
(
    @sourceTable varchar(24) = 'T_Tmp_NEWT',
    @infoOnly tinyint = 1,
    @previewDeleteExtras tinyint = 1                -- Set to 1 to preview deleting extra terms; 0 to actually delete them
)
AS
    Set NoCount On

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    Declare @message varchar(255)
    Declare @rowsInserted int

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @sourceTable = IsNull(@sourceTable, '')
    Set @infoOnly = IsNull(@infoOnly, 1)
    Set @previewDeleteExtras = IsNull(@previewDeleteExtras, 1)

    Declare @S varchar(1500) = ''
    Declare @AddNew nvarchar(3000) = ''

    If Not Exists (SELECT * FROM sys.tables where [name] = @sourceTable)
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
        Term_PK varchar(255),
        Term_Name varchar(255),
        Identifier int,
        Is_Leaf tinyint,
        Rank varchar(64),
        Parent_term_name varchar(255) NULL,
        Parent_term_ID int NULL,
        Grandparent_Term_Name varchar(255) NULL,
        Grandparent_Term_ID int NULL,
        Common_Name varchar(128) NULL,
        Synonym varchar(128) NULL,
        Mnemonic varchar(16) NULL,
        MatchesExisting tinyint
    )

    Set @S = ''
    Set @S = @S + ' INSERT INTO #Tmp_SourceData( Term_PK, Term_Name, Identifier, Is_Leaf, Rank,'
    Set @S = @S +                               ' Parent_term_name, Parent_term_ID,'
    Set @S = @S +                               ' Grandparent_Term_Name, Grandparent_Term_ID,'
    Set @S = @S +                               ' Common_Name, Synonym, Mnemonic, MatchesExisting )'
    Set @S = @S + ' SELECT Term_PK, Term_Name, Identifier, Is_Leaf, Coalesce(Rank, ''''),'
    Set @S = @S + '   Parent_term_name, Parent_term_ID,'
    Set @S = @S + '   Grandparent_Term_Name, Grandparent_Term_ID,'
    Set @S = @S + '   Common_Name, Synonym, Mnemonic, 0 AS MatchesExisting'
    Set @S = @S + ' FROM [' + @sourceTable + ']'
    Set @S = @S + ' WHERE Parent_term_name <> '''' And Term_PK Like ''%NEWT1'''

    Declare @GetSourceData nvarchar(3000) = @S

    EXEC sp_executesql @GetSourceData

    SELECT @rowsInserted = COUNT(*)
    FROM #Tmp_SourceData

    Set @message = 'Inserted ' + CAST(@rowsInserted as varchar(12)) + ' rows into #Tmp_SourceData, using SQL:'
    Print @message

    Print @S

    ---------------------------------------------------
    -- Replace empty Grandparent term IDs and names with NULL
    ---------------------------------------------------

    UPDATE #Tmp_SourceData
    SET Grandparent_Term_ID = NULL,
        Grandparent_Term_Name = NULL
    WHERE Coalesce(Grandparent_Term_ID, 0) = 0 AND
          Coalesce(Grandparent_Term_Name, '') = '' AND
          (NOT Grandparent_Term_ID IS NULL OR NOT Grandparent_Term_Name IS NULL);
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @message = 'Set grandparent term ID and name to null for ' + CAST(@myRowCount as varchar(12)) + ' rows in #Tmp_SourceData'
    Print @message

    ---------------------------------------------------
    -- Change empty strings to nulls in columns common_name, synonym, and mnemonic
    -- Change nulls to empty strings in the rank column
    ---------------------------------------------------

    UPDATE #Tmp_SourceData
    SET Common_Name = CASE WHEN Common_Name = '' THEN NULL ELSE Common_Name END,
        Synonym     = CASE WHEN Synonym = ''     THEN NULL ELSE Synonym END,
        Mnemonic    = CASE WHEN Mnemonic = ''    THEN NULL ELSE Mnemonic END,
        Rank        = COALESCE(Rank, '');
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @message = 'Set Common_Name, Synonym, and Mnemonic to null for ' + CAST(@myRowCount as varchar(12)) + ' rows in #Tmp_SourceData'
    Print @message

    ---------------------------------------------------
    -- Set MatchesExisting to 1 for rows that match an existing row in T_CV_NEWT
    ---------------------------------------------------

    UPDATE #Tmp_SourceData
    SET MatchesExisting = 1
    FROM #Tmp_SourceData s
         INNER JOIN T_CV_NEWT t
           ON t.Term_PK = s.Term_PK AND
              t.Parent_term_ID = s.Parent_term_ID AND
              Coalesce(t.Grandparent_Term_ID, 0) = Coalesce(s.Grandparent_Term_ID, 0)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @message = 'Set MatchesExisting to 1 for ' + CAST(@myRowCount as varchar(12)) + ' rows in #Tmp_SourceData'
    Print @message

    If @infoOnly = 0
    Begin -- <a1>

        ---------------------------------------------------
        -- Update existing rows
        ---------------------------------------------------

        MERGE T_CV_NEWT AS t
        USING (SELECT Term_PK, Term_Name, Identifier, Is_Leaf, Rank,
                      Parent_term_name, Parent_term_ID,
                      Grandparent_Term_Name, Grandparent_Term_ID,
                      Common_Name, Synonym, Mnemonic
               FROM #Tmp_SourceData
               WHERE MatchesExisting = 1) AS s
        ON ( t.Term_PK = s.Term_PK AND
             t.Parent_term_ID = s.Parent_term_ID AND
             Coalesce(t.Grandparent_Term_ID, 0) = Coalesce(s.Grandparent_Term_ID, 0))
        WHEN MATCHED AND (
            t.[Term_Name] <> s.[Term_Name] OR
            t.[Identifier] <> s.[Identifier] OR
            t.[Is_Leaf] <> s.[Is_Leaf] OR
            ISNULL( NULLIF(t.Rank, s.Rank),
                    NULLIF(s.Rank, t.Rank)) IS NOT NULL OR
            t.[Parent_term_name] <> s.[Parent_term_name] OR
            ISNULL( NULLIF(t.[Grandparent_Term_Name], s.[Grandparent_Term_Name]),
                    NULLIF(s.[Grandparent_Term_Name], t.[Grandparent_Term_Name])) IS NOT NULL OR
            ISNULL( NULLIF(t.[Common_Name], s.[Common_Name]),
                    NULLIF(s.[Common_Name], t.[Common_Name])) IS NOT NULL OR
            ISNULL( NULLIF(t.[Synonym], s.[Synonym]),
                    NULLIF(s.[Synonym], t.[Synonym])) IS NOT NULL OR
            ISNULL( NULLIF(t.[Mnemonic], s.[Mnemonic]),
                    NULLIF(s.[Mnemonic], t.[Mnemonic])) IS NOT NULL
            )
        THEN UPDATE SET
            [Term_Name] = s.[Term_Name],
            [Identifier] = s.[Identifier],
            [Is_Leaf] = s.[Is_Leaf],
            [Rank] = s.[Rank],
            [Parent_term_name] = s.[Parent_term_name],
            [Grandparent_Term_ID] = s.[Grandparent_Term_ID],
            [Grandparent_Term_Name] = s.[Grandparent_Term_Name],
            [Common_Name] = s.[Common_Name],
            [Synonym] = s.[Synonym],
            [Mnemonic] = s.[Mnemonic],
            [Updated] = GetDate();
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        SELECT 'Updated ' + Cast(@myRowCount as varchar(9)) + ' rows in T_CV_NEWT using ' + @sourceTable AS Message

        ---------------------------------------------------
        -- Add new rows
        ---------------------------------------------------

        INSERT INTO T_CV_NEWT (Term_PK, Term_Name, Identifier, Is_Leaf, Rank,
                               Parent_term_name, Parent_term_ID,
                               Grandparent_Term_Name, Grandparent_Term_ID,
                               Common_Name, Synonym, Mnemonic)
        SELECT Term_PK, Term_Name, Identifier, Is_Leaf, Rank,
               Parent_term_name, Parent_term_ID,
               Grandparent_Term_Name, Grandparent_Term_ID,
               Common_Name, Synonym, Mnemonic
        FROM #Tmp_SourceData
        WHERE MatchesExisting = 0
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        SELECT 'Added ' + Cast(@myRowCount as varchar(9)) + ' new rows to T_CV_NEWT using ' + @sourceTable AS Message

        ---------------------------------------------------
        -- Look for identifiers with invalid term names
        ---------------------------------------------------

        CREATE TABLE #Tmp_InvalidTermNames (
            Entry_ID   int not null IDENTITY (1,1),
            Identifier int not null,
            Term_Name  varchar(255) not null
        )

        CREATE TABLE #Tmp_IDsToDelete (
            Entry_ID int NOT NULL
        )

        CREATE CLUSTERED INDEX #IX_Tmp_IDsToDelete ON #Tmp_IDsToDelete (Entry_ID)

        INSERT INTO #Tmp_InvalidTermNames( Identifier,
                                           Term_Name )
        SELECT UniqueQTarget.Identifier,
               UniqueQTarget.Term_Name AS Invalid_Term_Name_to_Delete
        FROM ( SELECT DISTINCT Identifier, Term_Name FROM T_CV_NEWT GROUP BY Identifier, Term_Name ) UniqueQTarget
             LEFT OUTER JOIN
             ( SELECT DISTINCT Identifier, Term_Name FROM #Tmp_SourceData ) UniqueQSource
               ON UniqueQTarget.Identifier = UniqueQSource.Identifier AND
                  UniqueQTarget.Term_Name = UniqueQSource.Term_Name
        WHERE UniqueQTarget.Identifier IN ( SELECT Identifier
                                            FROM ( SELECT DISTINCT Identifier, Term_Name
                                                   FROM T_CV_NEWT
                                                   GROUP BY Identifier, Term_Name ) LookupQ
                                            GROUP BY Identifier
                                            HAVING (COUNT(*) > 1) ) AND
              UniqueQSource.Identifier IS NULL

        If Exists (SELECT Entry_ID FROM #Tmp_InvalidTermNames)
        Begin -- <b>
            SELECT 'Extra term name to delete' AS Action, *
            FROM #Tmp_InvalidTermNames

            INSERT INTO #Tmp_IDsToDelete (Entry_ID)
            SELECT target.Entry_ID
            FROM T_CV_NEWT target
                 INNER JOIN #Tmp_InvalidTermNames source
                   ON target.Identifier = source.Identifier AND
                      target.Term_Name  = source.Term_Name
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @previewDeleteExtras > 0
            Begin
                SELECT 'To be deleted' AS Action, *
                FROM T_CV_NEWT
                WHERE Entry_ID IN ( SELECT Entry_ID
                                    FROM #Tmp_IDsToDelete )

            End
            Else
            Begin -- <c>
                Declare @entryID int = 0
                Declare @continue tinyint = 1
                Declare @identifier int
                Declare @termName varchar(255)

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
                        If Exists (SELECT Identifier FROM T_CV_NEWT WHERE Identifier = @identifier AND Not Entry_ID IN (SELECT Entry_ID FROM #Tmp_IDsToDelete))
                        Begin
                            -- Safe to delete
                            DELETE FROM T_CV_NEWT
                            WHERE Identifier = @identifier AND Term_Name = @termName
                            --
                            SELECT @myError = @@error, @myRowCount = @@rowcount

                            Print 'Deleted ' + Cast(@myRowCount as varchar(9)) + ' row(s) for ID ' + Cast(@identifier as varchar(12)) + ' and term ' + @termName
                        End
                        Else
                        Begin
                            -- Not safe to delete
                            SELECT 'Will not delete term ' + @termName + ' for ID ' + Cast(@identifier as varchar(12)) + ' since no entries would remain for this ID' AS Error
                        End
                    End -- </e>

                End -- </d>
            End -- </c>
        End -- </b>
    End -- </a1>
    Else
    Begin -- <a2>
        ---------------------------------------------------
        -- Preview existing rows that would be updated
        ---------------------------------------------------

        SELECT 'Existing item to update' AS Item_Type,
               t.Entry_ID,
               t.Term_PK,
               CASE WHEN t.Term_Name = s.Term_Name THEN t.Term_Name ELSE t.Term_Name + ' --> ' + s.Term_Name END AS Term_Name,
               CASE WHEN t.Identifier = s.Identifier THEN t.Identifier ELSE t.Identifier + ' --> ' + s.Identifier END AS Identifier,
               CASE WHEN t.Is_Leaf = s.Is_Leaf THEN Cast(t.Is_Leaf as varchar(16)) ELSE Cast(t.Is_Leaf as varchar(16)) + ' --> ' + Cast(s.Is_Leaf as varchar(16)) END AS Is_Leaf,
               CASE WHEN t.Rank = s.Rank THEN t.Rank ELSE Coalesce(t.Rank, 'NULL') + ' --> ' + Coalesce(s.Rank, 'NULL') END AS Rank,
               t.Parent_term_ID,
               CASE WHEN t.Parent_term_name = s.Parent_term_name THEN t.Parent_term_name ELSE Coalesce(t.Parent_term_name, 'NULL') + ' --> ' + Coalesce(s.Parent_term_name, 'NULL') END AS Parent_term_name,
               t.Grandparent_Term_ID,
               CASE WHEN t.Grandparent_Term_Name = s.Grandparent_Term_Name THEN t.Grandparent_Term_Name ELSE Coalesce(t.Grandparent_Term_Name, 'NULL') + ' --> ' + Coalesce(s.Grandparent_Term_Name, 'NULL') END AS Grandparent_Term_Name,
               CASE WHEN t.Common_Name = s.Common_Name THEN t.Common_Name ELSE Coalesce(t.Common_Name, 'NULL') + ' --> ' + Coalesce(s.Common_Name, 'NULL') END AS Common_Name,
               CASE WHEN t.Synonym = s.Synonym THEN t.Synonym ELSE Coalesce(t.Synonym, 'NULL') + ' --> ' + Coalesce(s.Synonym, 'NULL') END AS Synonym,
               CASE WHEN t.Mnemonic = s.Mnemonic THEN t.Mnemonic ELSE Coalesce(t.Mnemonic, 'NULL') + ' --> ' + Coalesce(s.Mnemonic, 'NULL') END AS Mnemonic,
               t.Entered
        FROM T_CV_NEWT AS t
            INNER JOIN #Tmp_SourceData AS s
              ON t.Term_PK = s.Term_PK AND
                 t.Parent_term_ID = s.Parent_term_ID AND
                 Coalesce(t.Grandparent_Term_ID, 0) = Coalesce(s.Grandparent_Term_ID, 0)
        WHERE MatchesExisting=1 AND
              ( (t.Term_Name <> s.Term_Name) OR
                (t.Identifier <> s.Identifier) OR
                (t.Is_Leaf <> s.Is_Leaf) OR
                (ISNULL(NULLIF(t.Rank, s.Rank),
                        NULLIF(s.Rank, t.Rank)) IS NOT NULL) OR
                (t.Parent_term_name <> s.Parent_term_name) OR
                (ISNULL(NULLIF(t.Grandparent_Term_Name, s.Grandparent_Term_Name),
                        NULLIF(s.Grandparent_Term_Name, t.Grandparent_Term_Name)) IS NOT NULL) OR
                (ISNULL(NULLIF(t.Common_Name, s.Common_Name),
                        NULLIF(s.Common_Name, t.Common_Name)) IS NOT NULL) OR
                (ISNULL(NULLIF(t.Synonym, s.Synonym),
                        NULLIF(s.Synonym, t.Synonym)) IS NOT NULL) OR
                (ISNULL(NULLIF(t.Mnemonic, s.Mnemonic),
                        NULLIF(s.Mnemonic, t.Mnemonic)) IS NOT NULL)
               )
        UNION
        SELECT 'New item to add' AS Item_Type,
               0 AS Entry_ID,
               Term_PK,
               Term_Name,
               Identifier,
               Cast(Is_Leaf as varchar(16)),
               Rank,
               Parent_term_ID,
               Parent_term_name,
               Grandparent_Term_ID,
               Grandparent_Term_Name,
               Common_Name,
               Synonym,
               Mnemonic,
               Null AS Entered
        FROM #Tmp_SourceData
        WHERE MatchesExisting = 0
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    End -- </a2>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------

Done:
    Return @myError

GO
