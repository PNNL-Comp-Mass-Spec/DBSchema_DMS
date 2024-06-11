/****** Object:  StoredProcedure [dbo].[update_cached_cv_union] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_cv_union]
/****************************************************
**
**  Desc:
**      Updates data in T_CV_Union_Cached
**
**      Source tables are those used by view V_CV_Union
**      - T_CV_BTO
**      - T_CV_ENVO
**      - T_CV_CL
**      - T_CV_GO
**      - T_CV_MI
**      - T_CV_MOD
**      - T_CV_MS
**      - T_CV_NEWT
**      - T_CV_PRIDE
**      - T_CV_DOID;
**
**  Arguments:
**    @previewSql     When true, show the SQL that would be used to update T_CV_Union_Cached
**    @message        Status message
**
**  Auth:   mem
**  Date:   06/10/2024 mem - Initial version
**
*****************************************************/
(
    @previewSql tinyint = 0,
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @continue tinyint
    Declare @entryID int
    Declare @ontology varchar(16)
    Declare @tableName varchar(64)

    Declare @sql varchar(2048)
    Declare @identifier varchar(128)
    Declare @parentTermID varchar(128)
    Declare @grandparentTermID varchar(128)

    Declare @rowsUpdated int = 0

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @previewSql = IsNull(@previewSql, 0)
    Set @message = ''

    If @previewSql > 0
        Print 'Previewing SQL to update T_CV_Union_Cached';
    Else
        Print 'Updating T_CV_Union_Cached';

    ---------------------------------------------------
    -- Process the tables referenced by view ont.v_cv_union
    ---------------------------------------------------

    CREATE TABLE #Tmp_CV_Tables (
        Entry_ID int identity(1,1),
        Ontology varchar(16),
        Table_Name varchar(64)
    );

    INSERT INTO #Tmp_CV_Tables (Ontology, Table_Name)
    VALUES ('BTO',     'T_CV_BTO'),
           ('ENVO',    'T_CV_ENVO'),
           ('CL',      'T_CV_CL'),
           ('GO',      'T_CV_GO'),
           ('PSI-MI',  'T_CV_MI'),
           ('PSI-Mod', 'T_CV_MOD'),
           ('PSI-MS',  'T_CV_MS'),
           ('NEWT',    'T_CV_NEWT'),
           ('PRIDE',   'T_CV_PRIDE'),
           ('DOID',    'T_CV_DOID');

    Set @continue = 1
    Set @entryID = 0

    While @continue > 0
    Begin
        SELECT TOP 1
               @entryID = Entry_ID,
               @ontology = Ontology,
               @tableName = Table_Name
        FROM #Tmp_CV_Tables
        WHERE Entry_ID > @entryID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @continue = 0
        End
        Else
        Begin
            Print '';
            Print 'Caching data for ' + @ontology;

            If @ontology = 'NEWT'
            Begin
                -- Cast to citext since identifiers in t_cv_newt are integers
                Set @identifier        = 'Cast(Src.identifier AS varchar(24)) AS identifier';
                Set @parentTermID      = 'Cast(Src.parent_term_id AS varchar(24)) AS parent_term_id';
                Set @grandparentTermID = 'Cast(Src.grandparent_term_id AS varchar(24)) AS grandparent_term_id';
            End
            Else
            Begin
                Set @identifier        = 'Src.identifier';
                Set @parentTermID      = 'Src.parent_term_id';
                Set @grandparentTermID = 'Src.grandparent_term_id';
            End

            Set @sql = ''
            Set @sql = @sql + ' MERGE INTO T_CV_Union_Cached AS t'
            Set @sql = @sql + ' USING (SELECT ''' + @ontology + ''' AS source,'
            Set @sql = @sql + '               Src.term_pk,'
            Set @sql = @sql + '               Src.term_name,'
            Set @sql = @sql + '               ' + @identifier + ','
            Set @sql = @sql + '               Src.is_leaf,'
            Set @sql = @sql + '               Src.parent_term_name,'
            Set @sql = @sql + '               ' + @parentTermID + ','
            Set @sql = @sql + '               Src.grandparent_term_name,'
            Set @sql = @sql + '               ' + @grandparentTermID + ''
            Set @sql = @sql + '         FROM ' + @tableName + ' AS Src'
            Set @sql = @sql + '        ) AS s'
            Set @sql = @sql + ' ON (t.source              = s.source AND'
            Set @sql = @sql + '     t.term_pk             = s.term_pk AND'
            Set @sql = @sql + '     t.parent_term_id      = s.parent_term_id AND'
            Set @sql = @sql + '     Coalesce(t.grandparent_term_id, '''') = Coalesce(s.grandparent_term_id, ''''))'
            Set @sql = @sql + ' WHEN MATCHED AND'
            Set @sql = @sql + '      (t.term_name             <> s.term_name OR'
            Set @sql = @sql + '       t.is_leaf               <> s.is_leaf OR'
            Set @sql = @sql + '       ISNULL(NULLIF(t.identifier, s.identifier),'
            Set @sql = @sql + '              NULLIF(s.identifier, t.identifier)) IS NOT NULL OR'
            Set @sql = @sql + '       ISNULL(NULLIF(t.parent_term_name, s.parent_term_name),'
            Set @sql = @sql + '              NULLIF(s.parent_term_name, t.parent_term_name)) IS NOT NULL OR'
            Set @sql = @sql + '       ISNULL(NULLIF(t.grandparent_term_name, s.grandparent_term_name),'
            Set @sql = @sql + '              NULLIF(s.grandparent_term_name, t.grandparent_term_name)) IS NOT NULL'
            Set @sql = @sql + '      ) THEN'
            Set @sql = @sql + '     UPDATE SET'
            Set @sql = @sql + '         term_name             = s.term_name,'
            Set @sql = @sql + '         identifier            = s.identifier,'
            Set @sql = @sql + '         is_leaf               = s.is_leaf,'
            Set @sql = @sql + '         parent_term_name      = s.parent_term_name,'
            Set @sql = @sql + '         grandparent_term_name = s.grandparent_term_name'
            Set @sql = @sql + ' WHEN NOT MATCHED THEN'
            Set @sql = @sql + '     INSERT (source,'
            Set @sql = @sql + '             term_pk,'
            Set @sql = @sql + '             term_name,'
            Set @sql = @sql + '             identifier,'
            Set @sql = @sql + '             is_leaf,'
            Set @sql = @sql + '             parent_term_name,'
            Set @sql = @sql + '             parent_term_id,'
            Set @sql = @sql + '             grandparent_term_name,'
            Set @sql = @sql + '             grandparent_term_id)'
            Set @sql = @sql + '     VALUES (s.source,'
            Set @sql = @sql + '             s.term_pk,'
            Set @sql = @sql + '             s.term_name,'
            Set @sql = @sql + '             s.identifier,'
            Set @sql = @sql + '             s.is_leaf,'
            Set @sql = @sql + '             s.parent_term_name,'
            Set @sql = @sql + '             s.parent_term_id,'
            Set @sql = @sql + '             s.grandparent_term_name,'
            Set @sql = @sql + '             s.grandparent_term_id)'
            Set @sql = @sql + ';'

            If @previewSql > 0
            Begin
                Print @sql;
            End
            Else
            Begin
                Print @sql
                EXECUTE (@sql);
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                Set @rowsUpdated = @rowsUpdated + @myRowCount;

                If @myRowCount > 0
                Begin
                    Print 'Added/updated ' + Cast(@myRowCount AS varchar(12)) + ' rows for ' + @ontology
                End
            End

            -- Delete extra rows from the target table

            If @ontology = 'NEWT'
            Begin
                -- Cast to citext since identifiers in t_cv_newt are integers
                Set @identifier        = 'Cast(Src.identifier AS varchar(24))';
                Set @parentTermID      = 'Cast(Src.parent_term_id AS varchar(24))';
                Set @grandparentTermID = 'Cast(Src.grandparent_term_id AS varchar(24))';
            End

            Set @sql = ''
            Set @sql = @sql + ' DELETE FROM T_CV_Union_Cached'
            Set @sql = @sql + ' WHERE T_CV_Union_Cached.source = ''' + @ontology + ''' AND'
            Set @sql = @sql + '       NOT EXISTS (SELECT Src.term_pk'
            Set @sql = @sql + '                   FROM ' + @tableName + ' Src'
            Set @sql = @sql + '                   WHERE Src.term_pk           = T_CV_Union_Cached.term_pk AND'
            Set @sql = @sql + '                         ' + @parentTermID + ' = T_CV_Union_Cached.parent_term_id AND'
            Set @sql = @sql + '                         Coalesce(' + @grandparentTermID + ', '''') = Coalesce(T_CV_Union_Cached.grandparent_term_id, '''')'
            Set @sql = @sql + '                  );'

            If @previewSql > 0
            Begin
                Print @sql;
            End
            Else
            Begin
                Print @sql
                EXECUTE (@sql);
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                Set @rowsUpdated = @rowsUpdated + @myRowCount;

                If @myRowCount > 0
                Begin
                    Print 'Deleted ' + Cast(@myRowCount AS varchar(12)) + ' extra rows for ' + @ontology
                End
            End
        End
    End

    If @previewSql = 0
    Begin
        If @rowsUpdated = 0
            Set @message = 'Cached names in T_CV_Union_Cached are already up-to-date';
        Else
            Set @message = 'Updated ' + Cast(@rowsUpdated AS varchar(12)) + ' rows T_CV_Union_Cached'

        SELECT @message AS Message
    End

    Return @myError

GO
