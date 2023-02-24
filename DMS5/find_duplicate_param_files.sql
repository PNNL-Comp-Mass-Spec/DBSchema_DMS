/****** Object:  StoredProcedure [dbo].[FindDuplicateParamFiles] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FindDuplicateParamFiles]
/****************************************************
**
**  Desc:
**      Compares the param file entries in T_Param_Entries and
**      T_Param_File_Mass_Mods to find parameter files that match
**
**  Auth:   mem
**  Date:   05/15/2008 mem - Initial version (Ticket:671)
**          07/11/2014 mem - Optimized execution speed by adding #Tmp_MassModCounts
**                         - Updated default value for @ParamFileTypeList
**
*****************************************************/
(
    @ParamFileNameFilter varchar(256) = '',                 -- One or more param file name specifiers, separated by commas (filters can contain % wildcards)
    @ParamFileTypeList varchar(64) = 'MSGFDB',              -- Other options are Sequest or XTandem
    @IgnoreParentMassType tinyint = 1,                      -- Ignores 'ParentMassType' differences in T_Param_Entries
    @ConsiderInsignificantParameters tinyint = 0,
    @CheckValidOnly tinyint = 1,
    @MaxFilesToTest int = 0,
    @previewSql tinyint = 0,
    @message varchar(512)='' OUTPUT
)
AS
    Set NoCount On

    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0

    Declare @SStart varchar(2048)
    Declare @S varchar(2048)

    Declare @EntryID int
    Declare @Continue int
    Declare @FilesProcessed int

    Declare @ParamFileID int
    Declare @ParamFileName varchar(256)
    Declare @ParamFileTypeID int
    Declare @ParamFileType varchar(128)

    Declare @ModCount int
    Declare @EntryCount int

    Declare @EntryType varchar(128)
    Declare @EntrySpecifier varchar(128)
    Declare @EntryValue varchar(128)
    Declare @CompareEntry tinyint

    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------

    Set @ParamFileNameFilter = LTrim(RTrim(IsNull(@ParamFileNameFilter, '')))
    Set @ParamFileTypeList = LTrim(RTrim(IsNull(@ParamFileTypeList, '')))
    Set @IgnoreParentMassType = IsNull(@IgnoreParentMassType, 0)
    Set @ConsiderInsignificantParameters = IsNull(@ConsiderInsignificantParameters, 0)
    Set @CheckValidOnly = IsNull(@CheckValidOnly, 1)
    Set @MaxFilesToTest = IsNull(@MaxFilesToTest, 0)
    Set @previewSql = IsNull(@previewSql, 0)
    Set @message = ''

    If @ConsiderInsignificantParameters <> 0
        Set @ConsiderInsignificantParameters = 1

    If @previewSql <> 0
        Set @MaxFilesToTest = 1

    If Len(@ParamFileTypeList) = 0
    Begin
        Set @Message = 'Error: @ParamFileTypeList cannot be empty'
        Set @myError = 50000
        Goto Done
    End

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------

    CREATE TABLE #Tmp_ParamFileTypeFilter (
        Param_File_Type varchar(128),
        Valid tinyint
    )

    CREATE TABLE #Tmp_ParamFiles (
        Entry_ID int NOT NULL Identity(1,1),
        Param_File_ID int,
        Param_File_Name varchar(256),
        Param_File_Type_ID int,
        Param_File_Type varchar(128)
    )
    CREATE CLUSTERED INDEX #IX_Tmp_ParamFiles ON #Tmp_ParamFiles (Entry_ID)

    CREATE TABLE #Tmp_ParamEntries (
        Param_File_ID int,
        Entry_Type varchar(128),
        Entry_Specifier varchar(128),
        Entry_Value varchar(128),
        Compare tinyint Default 1
    )
    CREATE CLUSTERED INDEX #IX_Tmp_ParamEntries_Param_File_ID ON #Tmp_ParamEntries (Param_File_ID)
    CREATE INDEX           #IX_Tmp_ParamEntries_Entry_Type_Entry_Specifier ON #Tmp_ParamEntries (Entry_Type, Entry_Specifier, Param_File_ID)
    CREATE INDEX           #IX_Tmp_ParamEntries_Compare ON #Tmp_ParamEntries (Compare, Param_File_ID)

    CREATE TABLE #Tmp_DefaultSequestParamEntries (
        Entry_ID int NOT NULL Identity(1,1),
        Entry_Type varchar(128),
        Entry_Specifier varchar(128),
        Entry_Value varchar(128),
        Compare tinyint Default 1
    )

    CREATE CLUSTERED INDEX #IX_Tmp_DefaultSequestParamEntries_Entry_ID ON #Tmp_DefaultSequestParamEntries (Entry_ID)
    CREATE UNIQUE INDEX #IX_Tmp_DefaultSequestParamEntries_Entry_Type_Entry_Specifier ON #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier)

    CREATE TABLE #Tmp_MassModDuplicates (
        Param_File_ID int
    )

    CREATE TABLE #Tmp_ParamEntryDuplicates (
        Param_File_ID int
    )

    CREATE TABLE #Tmp_SimilarParamFiles (
        Entry_ID int NOT NULL Identity(1,1),
        Param_File_ID_Master int,
        Param_File_ID_Dup int
    )

    CREATE TABLE #Tmp_MassModCounts (
        Param_File_ID int,
        ModCount int
    )

    CREATE CLUSTERED INDEX #IX_Tmp_MassModCounts_ModCount ON #Tmp_MassModCounts (ModCount)
    CREATE UNIQUE INDEX #IX_Tmp_MassModCounts_ModCountParamFileID ON #Tmp_MassModCounts (ModCount, Param_File_ID)

    -----------------------------------------
    -- Populate #Tmp_ParamFileTypeFilter
    -----------------------------------------

    INSERT INTO #Tmp_ParamFileTypeFilter (Param_File_Type, Valid)
    SELECT DISTINCT Item, 1
    FROM dbo.MakeTableFromListDelim(@ParamFileTypeList, ',')
    --
    SELECT @myRowCount = @@rowcount, @myError = @@error

    UPDATE #Tmp_ParamFileTypeFilter
    SET Valid = 0
    FROM #Tmp_ParamFileTypeFilter PFTF
        LEFT OUTER JOIN T_Param_File_Types PFT
        ON PFTF.Param_File_Type = PFT.Param_File_Type
    WHERE PFT.Param_File_Type IS NULL
    --
    SELECT @myRowCount = @@rowcount, @myError = @@error

    If @myRowCount > 0
    Begin
        Set @message = 'Warning: one or more items in @ParamFileTypeList were not valid parameter file types'
        Print @message

        SELECT @message, *
        FROM #Tmp_ParamFileTypeFilter

        Set @message = ''

        DELETE FROM #Tmp_ParamFileTypeFilter
        WHERE Valid = 0

    End

    -----------------------------------------
    -- Populate #Tmp_ParamFiles
    -----------------------------------------

    Set @SStart = ''
    Set @S = ''

    Set @SStart = @SStart + ' INSERT INTO #Tmp_ParamFiles (Param_File_ID, Param_File_Name, Param_File_Type_ID, Param_File_Type)'
    Set @SStart = @SStart + ' SELECT '

    Set @S = @S + ' PF.Param_File_ID,'
    Set @S = @S +        ' PF.Param_File_Name,'
    Set @S = @S +        ' PF.Param_File_Type_ID,'
    Set @S = @S +        ' PFT.Param_File_Type'
    Set @S = @S + ' FROM T_Param_Files PF INNER JOIN '
    Set @S = @S +   ' T_Param_File_Types PFT ON PF.Param_File_Type_ID = PFT.Param_File_Type_ID INNER JOIN '
    Set @S = @S +      ' #Tmp_ParamFileTypeFilter PFTF ON PFT.Param_File_Type = PFTF.Param_File_Type '

    If @CheckValidOnly <> 0
        Set @S = @S + ' WHERE (PF.Valid <> 0)'
    Else
        Set @S = @S + ' WHERE (PF.Valid = PF.Valid)'

    IF Len(@ParamFileNameFilter) > 0
        Set @S = @S + ' AND (' + dbo.CreateLikeClauseFromSeparatedString(@ParamFileNameFilter, 'Param_File_Name', ',') + ')'

    Set @S = @S + ' ORDER BY Param_File_Type, Param_File_ID'

    If @previewSql <> 0
        Print @SStart + @S
    Else
        Exec (@SStart + @S)
    --
    SELECT @myRowCount = @@rowcount, @myError = @@error

    If @previewSql <> 0
    Begin
        -- Populate #Tmp_ParamFileTypeFilter with the first parameter file matching the filters
        Set @SStart = ''
        Set @SStart = @SStart + ' INSERT INTO #Tmp_ParamFiles (Param_File_ID, Param_File_Name, Param_File_Type_ID, Param_File_Type)'
        Set @SStart = @SStart + ' SELECT TOP 1 '

        Exec (@SStart + @S)
    End

    If @previewSql <> 0
        SELECT *
        FROM #Tmp_ParamFiles
        ORDER BY Entry_ID


    -----------------------------------------
    -- Populate #Tmp_MassModCounts
    -----------------------------------------
    --
    INSERT INTO #Tmp_MassModCounts( Param_File_ID,
                                    ModCount )
    SELECT P.Param_File_ID,
           SUM(CASE
                   WHEN Mod_Entry_ID IS NULL THEN 0
                   ELSE 1
               END) AS ModCount
    FROM #Tmp_ParamFiles P
         LEFT OUTER JOIN T_Param_File_Mass_Mods MM
           ON P.Param_File_ID = MM.Param_File_ID
    GROUP BY P.Param_File_ID


    If @ParamFileTypeList LIKE '%Sequest%'
    Begin -- <a1>

        -----------------------------------------
        -- Populate #Tmp_ParamEntries with T_Param_Entries
        -- After this, standardize the entries to allow for rapid comparison
        -----------------------------------------
        --
        INSERT INTO #Tmp_ParamEntries( Param_File_ID,
                                    Entry_Type,
                                    Entry_Specifier,
                                    Entry_Value,
                                    Compare )
        SELECT PE.Param_File_ID,
            PE.Entry_Type,
            PE.Entry_Specifier,
            PE.Entry_Value,
            1 AS Compare
        FROM T_Param_Entries PE
        ORDER BY Param_File_ID, Entry_Type, Entry_Specifier
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error

        If @CheckValidOnly <> 0
        Begin
            DELETE #Tmp_ParamEntries
            FROM #Tmp_ParamEntries PE INNER JOIN
                T_Param_Files PF ON PE.Param_File_ID = PF.Param_File_ID
            WHERE PF.Valid = 0
            --
            SELECT @myRowCount = @@rowcount, @myError = @@error

        End


        -----------------------------------------
        -- Possibly add entries for 'sequest_N14_NE.params' to #Tmp_ParamEntries
        -----------------------------------------
        --
        Set @ParamFileID = 1000
        SELECT @ParamFileID = Param_File_ID
        FROM T_Param_Files
        WHERE (Param_File_Name = 'sequest_N14_NE.params')

        If Not Exists (SELECT * FROM #Tmp_ParamEntries WHERE Param_File_ID = @ParamFileID)
            INSERT INTO #Tmp_ParamEntries( Param_File_ID,
                                        Entry_Type,
                                        Entry_Specifier,
                                        Entry_Value,
                                        Compare )
            VALUES(@ParamFileID, 'BasicParam', 'SelectedEnzymeIndex', 0, 1)


        -----------------------------------------
        -- Populate a temporary table with the default values to add to #Tmp_ParamEntries
        -----------------------------------------

        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('BasicParam', 'MaximumNumberMissedCleavages', '4')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('BasicParam', 'ParentMassType', 'average')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('BasicParam', 'SelectedEnzymeCleavagePosition', '0')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('BasicParam', 'SelectedEnzymeIndex', '0')

        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'FragmentIonTolerance', '1')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'MaximumNumDifferentialPerPeptide', '3')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'MaximumNumAAPerDynMod', '4')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'PeptideMassTolerance', '3')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'Use_a_Ions', '0')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'Use_b_Ions', '1')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'Use_y_Ions', '1')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'PeptideMassUnits', '0')

        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'a_Ion_Weighting', '0')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'b_Ion_Weighting', '1')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'c_Ion_Weighting', '0')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'd_Ion_Weighting', '0')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'v_Ion_Weighting', '0')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'w_Ion_Weighting', '0')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'x_Ion_Weighting', '0')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'y_Ion_Weighting', '1')
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value) VALUES ('AdvancedParam', 'z_Ion_Weighting', '0')

        -- Note: If @ConsiderInsignificantParameters = 0, then the following options will not actually affect the results
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value, Compare) VALUES ('AdvancedParam', 'ShowFragmentIons', 'False', @ConsiderInsignificantParameters)
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value, Compare) VALUES ('AdvancedParam', 'NumberOfDescriptionLines', '3', @ConsiderInsignificantParameters)
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value, Compare) VALUES ('AdvancedParam', 'NumberOfOutputLines', '10', @ConsiderInsignificantParameters)
        INSERT INTO #Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value, Compare) VALUES ('AdvancedParam', 'NumberOfResultsToProcess', '500', @ConsiderInsignificantParameters)


        -----------------------------------------
        -- Add the default values to #Tmp_ParamEntries, where missing
        -----------------------------------------

        Set @EntryId = 0
        Set @Continue = 1
        While @Continue = 1
        Begin
            SELECT TOP 1 @EntryID = Entry_ID,
                        @EntryType = Entry_Type,
                        @EntrySpecifier = Entry_Specifier,
                        @EntryValue = Entry_Value,
                        @CompareEntry = Compare
            FROM #Tmp_DefaultSequestParamEntries
            WHERE Entry_ID > @EntryID
            ORDER BY Entry_ID
            --
            SELECT @myRowCount = @@rowcount, @myError = @@error

            If @myRowCount <= 0
                Set @Continue = 0
            Else
            Begin
                INSERT INTO #Tmp_ParamEntries (Param_File_ID, Entry_Type, Entry_Specifier, Entry_Value, Compare)
                SELECT DISTINCT Param_File_ID, @EntryType, @EntrySpecifier, @EntryValue, IsNull(@CompareEntry, 1)
                FROM #Tmp_ParamEntries
                WHERE (NOT (Param_File_ID IN ( SELECT Param_File_ID
                                            FROM #Tmp_ParamEntries
                                            WHERE (Entry_Type = @EntryType) AND
                                                    (Entry_Specifier = @EntrySpecifier) )))
                --
                SELECT @myRowCount = @@rowcount, @myError = @@error

            End
        End


        -----------------------------------------
        -- Make sure all 'FragmentIonTolerance' entries are non-zero (defaulting to 1 if 0)
        -----------------------------------------
        --
        UPDATE #Tmp_ParamEntries
        SET Entry_value = '1'
        WHERE Entry_Type = 'AdvancedParam' AND
            Entry_Specifier = 'FragmentIonTolerance' AND
            Entry_Value = '0'
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error


        -----------------------------------------
        -- Change Compare to 0 for entries in #Tmp_ParamEntries that correspond to
        -- Entry_Specifier values in #Tmp_DefaultSequestParamEntries that have Compare = 0
        -----------------------------------------
        --
        UPDATE #Tmp_ParamEntries
        SET Compare = 0
        FROM #Tmp_ParamEntries PE INNER JOIN (
            SELECT DISTINCT Entry_Type, Entry_Specifier
            FROM #Tmp_DefaultSequestParamEntries
            WHERE Compare = 0) LookupQ ON
            PE.Entry_Type = LookupQ.Entry_Type AND PE.Entry_Specifier = LookupQ.Entry_Specifier
        WHERE Compare <> 0
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error

        If @myRowCount > 0
        Begin
            Set @message = 'Note: Updated ' + Convert(varchar(12), @myRowCount) + ' rows in #Tmp_ParamEntries to have Compare = 0, since they correspond to entries in #Tmp_DefaultSequestParamEntries that have Compare = 0'
            Print @message
            Set @message = ''
        End

        -----------------------------------------
        -- If @IgnoreParentMassType is non-zero, then mark these entries as Not-Compared
        -----------------------------------------
        --
        If @IgnoreParentMassType <> 0
        Begin
            UPDATE #Tmp_ParamEntries
            SET Compare = 0
            WHERE Entry_Type = 'BasicParam' AND
                Entry_Specifier = 'ParentMassType'
            --
            SELECT @myRowCount = @@rowcount, @myError = @@error
        End


        If @previewSql <> 0
        Begin
            -----------------------------------------
            -- Display stats on the data in #Tmp_ParamEntries
            -----------------------------------------
            --
            SELECT Compare,
                Entry_Type,
                Entry_Specifier,
                COUNT(*) AS Entry_Count,
                Min(Entry_Value) AS Entry_Value_Min,
                Max(Entry_Value) AS Entry_Value_Max
            FROM #Tmp_ParamEntries
            WHERE Compare <> 0
            GROUP BY Compare, Entry_Type, Entry_Specifier

            SELECT Compare,
                Entry_Type,
                Entry_Specifier,
                COUNT(*) AS Entry_Count,
                Min(Entry_Value) AS Entry_Value_Min,
                Max(Entry_Value) AS Entry_Value_Max
            FROM #Tmp_ParamEntries
            WHERE Compare = 0
            GROUP BY Compare, Entry_Type, Entry_Specifier

        End
    End -- </a1>

    -----------------------------------------
    -- Step through the entries in #Tmp_ParamFiles and look for
    --  duplicate and similar param files
    -----------------------------------------
    --
    Set @FilesProcessed = 0
    Set @EntryID = 0
    Set @Continue = 1
    While @Continue = 1
    Begin -- <a2>
        SELECT TOP 1 @EntryID = Entry_ID,
                     @ParamFileID = Param_File_ID,
                     @ParamFileName = Param_File_Name,
                     @ParamFileTypeID = Param_File_Type_ID,
                     @ParamFileType = Param_File_Type
        FROM #Tmp_ParamFiles
        WHERE Entry_ID > @EntryID
        ORDER BY Entry_ID
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error

        If @myRowCount <= 0
            Set @Continue = 0
        Else
        Begin -- <b>

            TRUNCATE TABLE #Tmp_MassModDuplicates
            TRUNCATE TABLE #Tmp_ParamEntryDuplicates

            -----------------------------------------
            -- Look for duplicates in T_Param_File_Mass_Mods
            -----------------------------------------
            --
            -- First, lookup the mod count for this parameter file
            --
            Set @ModCount= 0
            SELECT @ModCount = ModCount
            FROM #Tmp_MassModCounts
            WHERE Param_File_ID = @ParamFileID
            --
            SELECT @myRowCount = @@rowcount, @myError = @@error

            If @ModCount = 0
            Begin -- <c1>

                -----------------------------------------
                -- Parameter file doesn't have any mass modifications
                -----------------------------------------
                --
                INSERT INTO #Tmp_MassModDuplicates (Param_File_ID)
                SELECT PF.Param_File_ID
                FROM T_Param_Files PF
                     INNER JOIN #Tmp_MassModCounts PFMM
                       ON PF.Param_File_ID = PFMM.Param_File_ID
                WHERE (PFMM.ModCount = 0) AND
                      (PF.Param_File_ID <> @ParamFileID) AND
                      (PF.Param_File_Type_ID = @ParamFileTypeID) AND
                      (@CheckValidOnly = 0 OR PF.Valid <> 0)
                --
                SELECT @myRowCount = @@rowcount, @myError = @@error
            End -- </c1>
            Else
            Begin -- <c2>

                -----------------------------------------
                -- Find parameter files that are of the same type and have the same set of modifications
                -- Note that we're ignoring Local_Symbol_ID
                -----------------------------------------
                --
                INSERT INTO #Tmp_MassModDuplicates (Param_File_ID)
                SELECT B.Param_File_ID
                FROM (  SELECT Param_File_ID,
                              Residue_ID,
                              Mass_Correction_ID,
                              Mod_Type_Symbol
                        FROM T_Param_File_Mass_Mods
                        WHERE (Param_File_ID = @ParamFileID)
                     ) A
                    INNER JOIN ( SELECT PFMM.Param_File_ID,
                                        PFMM.Residue_ID,
                                        PFMM.Mass_Correction_ID,
                                        PFMM.Mod_Type_Symbol
                                FROM T_Param_File_Mass_Mods PFMM
                                    INNER JOIN T_Param_Files PF
                                        ON PFMM.Param_File_ID = PF.Param_File_ID
                                WHERE (PFMM.Param_File_ID <> @ParamFileID) AND
                                      (PF.Param_File_Type_ID = @ParamFileTypeID) AND
                                      (PFMM.Param_File_ID IN (  SELECT Param_File_ID
                                                                FROM #Tmp_MassModCounts
                                                                Where ModCount = @ModCount ))
                            ) B
                    ON A.Residue_ID = B.Residue_ID AND
                       A.Mass_Correction_ID = B.Mass_Correction_ID AND
                       A.Mod_Type_Symbol = B.Mod_Type_Symbol
                GROUP BY B.Param_File_ID
                HAVING (COUNT(*) = @ModCount)
                --
                SELECT @myRowCount = @@rowcount, @myError = @@error

            End -- </c2>

            -----------------------------------------
            -- Look for duplicates in T_Param_Entries
            -- At present, this is only applicable to Sequest parameter files
            -----------------------------------------
            --
            If @ParamFileType = 'Sequest'
            Begin -- <c3>

                -----------------------------------------
                -- First, Count the number of entries in the table for this parameter file
                -- Skipping entries with Compare = 0
                -----------------------------------------
                --
                Set @EntryCount= 0
                SELECT @EntryCount = COUNT(*)
                FROM #Tmp_ParamEntries
                WHERE Compare <> 0 AND Param_File_ID = @ParamFileID
                --
                SELECT @myRowCount = @@rowcount, @myError = @@error

                If @ModCount = 0
                Begin -- <d1>

                    -----------------------------------------
                    -- Parameter file doesn't have any param entries (with compare <> 0)
                    -- Find all other parameter files that don't have any param entries
                    -----------------------------------------
                    --
                    Set @S = ''
                    Set @S = @S + ' INSERT INTO #Tmp_ParamEntryDuplicates (Param_File_ID)'
                    Set @S = @S + ' SELECT PF.Param_File_ID'
                    Set @S = @S + ' FROM T_Param_Files PF LEFT OUTER JOIN'
                    Set @S = @S +      ' #Tmp_ParamEntries PE ON '
                    Set @S = @S +      ' PF.Param_File_ID = PE.Param_File_ID AND PE.Compare <> 0'
                    Set @S = @S + ' WHERE (PE.Param_File_ID IS NULL) AND '
                    Set @S = @S +       ' (PF.Param_File_ID <> ' + Convert(varchar(12), @ParamFileID) + ') AND'
                    Set @S = @S +       ' (PF.Param_File_Type_ID = ' + Convert(varchar(12), @ParamFileTypeID) + ')'

                    If @CheckValidOnly <> 0
                            Set @S = @S + ' AND (PF.Valid <> 0)'

                    If @previewSql <> 0
                        Print @S
                    Else
                        Exec (@S)
                    --
                    SELECT @myRowCount = @@rowcount, @myError = @@error
                End -- </d1>
                Else
                Begin -- <d2>

                    -----------------------------------------
                    -- Find parameter files that are of the same type and have the same set of param entries
                    -----------------------------------------
                    --
                    INSERT INTO #Tmp_ParamEntryDuplicates (Param_File_ID)
                    SELECT B.Param_File_ID
                    FROM (  SELECT  Param_File_ID,
                                    Entry_Type,
                                    Entry_Specifier,
                                    Entry_Value
                            FROM #Tmp_ParamEntries
                            WHERE Compare <> 0 AND Param_File_ID = @ParamFileID
                        ) A
                        INNER JOIN ( SELECT PE.Param_File_ID,
                                            PE.Entry_Type,
                                            PE.Entry_Specifier,
                                            PE.Entry_Value
                                    FROM #Tmp_ParamEntries PE
                                        INNER JOIN T_Param_Files PF
                                            ON PE.Param_File_ID = PF.Param_File_ID
                                    WHERE (PE.Compare <> 0) AND
                                          (PE.Param_File_ID <> @ParamFileID) AND
                                          (PF.Param_File_Type_ID = @ParamFileTypeID) AND
                                          (PE.Param_File_ID IN (    SELECT Param_File_ID
                                                                    FROM #Tmp_ParamEntries
                                                                    WHERE Compare <> 0
                                                                    GROUP BY Param_File_ID
                                                                    HAVING (COUNT(*) = @EntryCount) ))
                                ) B
                        ON A.Entry_Type = B.Entry_Type AND
                           A.Entry_Specifier = B.Entry_Specifier AND
                           A.Entry_Value = B.Entry_Value
                    GROUP BY B.Param_File_ID
                    HAVING (COUNT(*) = @EntryCount)
                    --
                    SELECT @myRowCount = @@rowcount, @myError = @@error

                End -- </d2>

                -----------------------------------------
                -- Any Param_File_ID values that are in #Tmp_ParamEntryDuplicates and #Tmp_MassModDuplicates are duplicates
                -- Add their IDs to #Tmp_SimilarParamFiles
                -----------------------------------------

                INSERT INTO #Tmp_SimilarParamFiles(Param_File_ID_Master, Param_File_ID_Dup)
                SELECT @ParamFileID, PED.Param_File_ID
                FROM #Tmp_ParamEntryDuplicates PED INNER JOIN
                     #Tmp_MassModDuplicates MMD ON PED.Param_File_ID = MMD.Param_File_ID


            End -- </c3>
            Else
            Begin
                -----------------------------------------
                -- Any Param_File_ID values that are in #Tmp_MassModDuplicates are duplicates
                -- Add their IDs to #Tmp_SimilarParamFiles
                -----------------------------------------

                INSERT INTO #Tmp_SimilarParamFiles(Param_File_ID_Master, Param_File_ID_Dup)
                SELECT @ParamFileID, MMD.Param_File_ID
                FROM #Tmp_MassModDuplicates MMD
            End

        End -- </b>

        Set @FilesProcessed = @FilesProcessed + 1
        If @MaxFilesToTest <> 0 And @FilesProcessed >= @MaxFilesToTest
            Set @continue = 0

    End -- </a2>


    -----------------------------------------
    -- Display the results
    -----------------------------------------


    SELECT SPF.Entry_ID,
           PFInfo.Param_File_Type,
           SPF.Param_File_ID_Master,
           SPF.Param_File_ID_Dup,
           PFA.Param_File_Name AS Name_A,
           PFB.Param_File_Name AS Name_B,
           PFA.Param_File_Description AS Desc_A,
           PFB.Param_File_Description AS Desc_B
    FROM #Tmp_SimilarParamFiles SPF
         INNER JOIN T_Param_Files PFA
           ON SPF.Param_File_ID_Master = PFA.Param_File_ID
         INNER JOIN T_Param_Files PFB
           ON SPF.Param_File_ID_Dup = PFB.Param_File_ID
         INNER JOIN #Tmp_ParamFiles PFInfo
           ON SPF.Param_File_ID_Master = PFInfo.Param_File_ID


    SELECT Convert(varchar(24), 'Master') AS Param_File_Category,
           Param_File_ID,
           Entry_Type,
           Entry_Specifier,
           Entry_Value,
           Compare
    FROM #Tmp_ParamEntries PE
         INNER JOIN #Tmp_SimilarParamFiles SPF
           ON SPF.Param_File_ID_Master = PE.Param_File_ID
    UNION
    SELECT Convert(varchar(24), 'Duplicate') AS Param_File_Category,
           Param_File_ID,
           Entry_Type,
           Entry_Specifier,
           Entry_Value,
           Compare
    FROM #Tmp_ParamEntries PE
         INNER JOIN #Tmp_SimilarParamFiles SPF
           ON SPF.Param_File_ID_Dup = PE.Param_File_ID



Done:
    If Len(@message) > 0
        SELECT @message As Message

    --
    Return @myError

GO
GRANT EXECUTE ON [dbo].[FindDuplicateParamFiles] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindDuplicateParamFiles] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindDuplicateParamFiles] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindDuplicateParamFiles] TO [Limited_Table_Write] AS [dbo]
GO
