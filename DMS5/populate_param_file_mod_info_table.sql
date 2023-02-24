/****** Object:  StoredProcedure [dbo].[populate_param_file_mod_info_table] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[populate_param_file_mod_info_table]
/****************************************************
**
**  Desc:   Populates temporary table #TmpParamFileModResults
**            using the param file IDs in #TmpParamFileInfo
**
**          Both of these tables needs to be created by
**            the calling procedure
**
**  Return values: 0: success, otherwise, error code
**
**  Date:   12/08/2006 mem - Initial version (Ticket #342)
**          04/07/2008 mem - Added parameters @MassModFilterTextColumn, @MassModFilterText, and @MassModFilterSql
**          11/30/2018 mem - Renamed the Monoisotopic_Mass and Average_Mass columns
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @showModSymbol tinyint = 1,                        -- Set to 1 to display the modification symbol
    @showModName tinyint = 1,                        -- Set to 1 to display the modification name
    @showModMass tinyint = 0,                        -- Set to 1 to display the modification mass
    @useModMassAlternativeName tinyint = 0,
    @massModFilterTextColumn varchar(64) = '',        -- If text is defined here, then the @MassModFilterText filter is only applied to column(s) whose name matches this
    @massModFilterText varchar(64) = '',            -- If text is defined here, then @MassModFilterSql will be populated with SQL to filter the results to only show rows that contain this text in one of the mass mod columns
    @massModFilterSql varchar(4000) = ''output,
    @message varchar(512) = '' output
)
AS
    Set NoCount On

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @CurrentColumn varchar(64)
    Declare @ColumnHeaderRowID int
    Declare @ContinueColumnHeader int
    Declare @ContinueAppendDescriptions int
    Declare @ModTypeFilter varchar(128)

    Declare @S varchar(4000)
    Declare @MMD varchar(512)

    Declare @MassModFilterComparison varchar(66)
    Declare @AddFilter tinyint

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    -- Assure that one of the following is non-zero
    If IsNull(@ShowModSymbol, 0) = 0 AND IsNull(@ShowModName, 0) = 0 AND IsNull(@ShowModMass, 0) = 0
    Begin
        Set @ShowModSymbol = 0
        Set @ShowModName = 1
        Set @ShowModMass = 0
    End

    Set @MassModFilterTextColumn = IsNull(@MassModFilterTextColumn, '')
    Set @MassModFilterText = IsNull(@MassModFilterText, '')

    Set @message = ''
    Set @MassModFilterSql = ''

    If Len(@MassModFilterTextColumn) > 0
        Set @MassModFilterComparison = '%' + @MassModFilterTextColumn + '%'
    Else
        Set @MassModFilterComparison = ''


    -----------------------------------------------------------
    -- Create some temporary tables
    -----------------------------------------------------------

    CREATE TABLE #TmpParamFileModInfo (
        Param_File_ID int NOT NULL ,
        Mod_Entry_ID int NOT NULL ,
        ModType varchar(64) NULL ,
        Mod_Description varchar(128) NULL,
        Used tinyint DEFAULT 0
    )
    CREATE UNIQUE CLUSTERED INDEX #IX_TempTable_ParamFileModInfo_Param_File_ID_Mod_Entry_ID ON #TmpParamFileModInfo(Param_File_ID, Mod_Entry_ID)

    CREATE TABLE #ColumnHeaders (
        UniqueRowID int Identity(1,1),
        ModType varchar(64)
    )
    CREATE UNIQUE CLUSTERED INDEX #IX_TempTable_ColumnHeaders ON #ColumnHeaders(UniqueRowID)


    -----------------------------------------------------------
    -- Populate #TmpParamFileModInfo
    -----------------------------------------------------------

    Set @S = ''
    Set @S = @S + ' INSERT INTO #TmpParamFileModInfo (Param_File_ID, Mod_Entry_ID, ModType, Mod_Description)'
    Set @S = @S + ' SELECT PFMM.Param_File_ID, PFMM.Mod_Entry_ID, '
    Set @S = @S +         ' MT.Mod_Type_Synonym + CASE WHEN R.Residue_Symbol IN (''['',''<'') THEN ''_N'''
    Set @S = @S +                               ' WHEN R.Residue_Symbol IN ('']'',''>'') THEN ''_C'''
    Set @S = @S +                               ' ELSE ''_'' + R.Residue_Symbol '
    Set @S = @S +                               ' END AS ModType,'

    If @ShowModSymbol <> 0
    Begin
        Set @S = @S + ' IsNull(Local_Symbol, ''-'') '

        If @ShowModName <> 0 OR @ShowModMass <> 0
            Set @S = @S + ' + '', '' + '
    End

    If @ShowModName <> 0
    Begin
        If @UseModMassAlternativeName = 0
            Set @S = @S + ' RTRIM(MCF.Mass_Correction_Tag)'
        Else
            Set @S = @S + ' IsNull(Alternative_Name, RTRIM(MCF.Mass_Correction_Tag))'

        If @ShowModMass <> 0
             Set @S = @S + ' + '' ('' + '
    End

    If @ShowModMass <> 0
    Begin
        Set @S = @S + ' CONVERT(varchar(19), MCF.Monoisotopic_Mass)'
        If @ShowModName <> 0
             Set @S = @S + ' + '')'''
    End

    Set @S = @S +     ' AS Mod_Description'

    Set @S = @S + ' FROM #TmpParamFileInfo PFI INNER JOIN '
    Set @S = @S +      ' T_Param_File_Mass_Mods PFMM ON PFI.Param_File_ID = PFMM.Param_File_ID INNER JOIN'
    Set @S = @S +      ' T_Mass_Correction_Factors MCF ON PFMM.Mass_Correction_ID = MCF.Mass_Correction_ID INNER JOIN'
    Set @S = @S +      ' T_Residues R ON PFMM.Residue_ID = R.Residue_ID INNER JOIN'
    Set @S = @S +      ' T_Modification_Types MT ON PFMM.Mod_Type_Symbol = MT.Mod_Type_Symbol INNER JOIN'
    Set @S = @S +      ' T_Seq_Local_Symbols_List LSL ON PFMM.Local_Symbol_ID = LSL.Local_Symbol_ID'

    Exec (@S)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error populating #TmpParamFileModInfo: ' + Convert(varchar(19), @myError)
        goto done
    end

    -----------------------------------------------------------
    -- Populate #TmpParamFileModResults with the Param File IDs
    --  in #TmpParamFileInfo; this may include param files that
    --  do not have any mods
    -----------------------------------------------------------
    INSERT INTO #TmpParamFileModResults (Param_File_ID)
    SELECT Param_File_ID
    FROM #TmpParamFileInfo
    GROUP BY Param_File_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -----------------------------------------------------------
    -- Generate a list of the unique mod types in #TmpParamFileModInfo
    -- Use these to define the column headers for the crosstab
    -----------------------------------------------------------
    INSERT INTO #ColumnHeaders (ModType)
    SELECT ModType
    FROM #TmpParamFileModInfo
    GROUP BY ModType
    ORDER BY ModType
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin -- <a>
        -----------------------------------------------------------
        -- Use the columns in #ColumnHeaders to dynamically add
        --  columns to #TmpParamFileModResults
        -- By using DEFAULT('') WITH VALUES, all of the rows will
        --  have blank, non-Null values for these new columns
        -----------------------------------------------------------
        Set @S = ''
        Set @S = @S + ' ALTER TABLE #TmpParamFileModResults ADD '

        SELECT @S = @S + '[' + ModType + '] varchar(128) DEFAULT ('''') WITH VALUES ' + ', '
        FROM #ColumnHeaders
        ORDER BY UniqueRowID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- Remove the trailing comma from @S
        Set @S = Left(@S, Len(@S)-1)

        -- Execute the Sql to alter the table
        Exec (@S)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error appending new columns to #TmpParamFileModResults: ' + Convert(varchar(19), @myError)
            goto done
        end

        -----------------------------------------------------------
        -- Populate #TmpParamFileModResults by looping through
        --  the Columns in #ColumnHeaders
        -----------------------------------------------------------
        Set @ColumnHeaderRowID = 0
        Set @ContinueColumnHeader = 1
        While @ContinueColumnHeader <> 0
        Begin -- <b>

            SELECT TOP 1 @CurrentColumn = ModType,
                         @ColumnHeaderRowID = UniqueRowID
            FROM #ColumnHeaders
            WHERE UniqueRowID > @ColumnHeaderRowID
            ORDER BY UniqueRowID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Set @ContinueColumnHeader = 0
            Else
            Begin -- <c>

                -----------------------------------------------------------
                -- Loop through the entries for @CurrentColumn, creating a comma separated list
                --  of the mods defined for each mod type in each parameter file
                -----------------------------------------------------------
                Set @ContinueAppendDescriptions = 1
                While @ContinueAppendDescriptions <> 0
                Begin -- <d>

                    Set @ModTypeFilter = '(ModType = ''' + @CurrentColumn + ''')'

                    Set @MMD = ''
                    Set @MMD = @MMD + ' SELECT Param_File_ID, MIN(Mod_Description) AS Mod_Description'
                    Set @MMD = @MMD + ' FROM #TmpParamFileModInfo'
                    Set @MMD = @MMD + ' WHERE (Used = 0) AND ' + @ModTypeFilter
                    Set @MMD = @MMD + ' GROUP BY Param_File_ID'


                    Set @S = ''
                    Set @S = @S + ' UPDATE #TmpParamFileModResults'
                    Set @S = @S + ' SET [' + @CurrentColumn + '] = [' + @CurrentColumn + '] + '
                    Set @S = @S +            ' CASE WHEN LEN([' + @CurrentColumn + ']) > 0'
                    Set @S = @S +            ' THEN '', '' '
                    Set @S = @S +            ' ELSE '''' '
                    Set @S = @S +            ' END + SourceQ.Mod_Description'
                    Set @S = @S + ' FROM #TmpParamFileModResults PFMR INNER JOIN'
                    Set @S = @S +      ' (' + @MMD + ') SourceQ '
                    Set @S = @S +      ' ON PFMR.Param_File_ID = SourceQ.Param_File_ID'
                    --
                    Exec (@S)
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount
                    --
                    if @myError <> 0
                    begin
                        set @message = 'Error updating "' + @CurrentColumn + '" in #TmpParamFileModResults: ' + Convert(varchar(19), @myError)
                        goto done
                    end

                    If @myRowCount = 0
                        Set @ContinueAppendDescriptions = 0
                    Else
                    Begin -- <e>
                        Set @S = ''
                        Set @S = @S + ' UPDATE #TmpParamFileModInfo'
                        Set @S = @S + ' SET Used = 1'
                        Set @S = @S + ' FROM #TmpParamFileModInfo PFMI INNER JOIN'
                        Set @S = @S +      ' (' + @MMD + ') SourceQ'
                        Set @S = @S +      ' ON PFMI.Param_File_ID = SourceQ.Param_File_ID AND'
                        Set @S = @S +         ' PFMI.Mod_Description = SourceQ.Mod_Description'
                        Set @S = @S + ' WHERE ' + @ModTypeFilter
                        --
                        Exec (@S)
                        --
                        SELECT @myError = @@error, @myRowCount = @@rowcount

                    End -- </e>
                End -- </d>

                -----------------------------------------------------------
                -- Possibly populate @MassModFilterSql
                -----------------------------------------------------------
                If Len(@MassModFilterText) > 0
                Begin
                    Set @AddFilter = 1
                    If Len(@MassModFilterComparison) > 0
                    Begin
                        If Not @CurrentColumn LIKE @MassModFilterComparison
                            Set @AddFilter = 0
                    End

                    If @AddFilter = 1
                    Begin
                        If Len(@MassModFilterSql) > 0
                            Set @MassModFilterSql = @MassModFilterSql + ' OR '

                        Set @MassModFilterSql = @MassModFilterSql + ' [' + @CurrentColumn + '] LIKE ''%' + @MassModFilterText + '%'''
                    End
                End

            End -- </c>
        End -- </b>
    End -- </a>

    -----------------------------------------------------------
    -- Exit
    -----------------------------------------------------------
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[populate_param_file_mod_info_table] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[populate_param_file_mod_info_table] TO [Limited_Table_Write] AS [dbo]
GO
